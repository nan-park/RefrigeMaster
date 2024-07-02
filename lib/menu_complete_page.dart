import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:refrige_master/backside/app_design_comp.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart' as intl;
import 'main.dart';

Future<Map> getRefData() async {
  Map map = {};
  final snapshot = await FirebaseFirestore.instance
      .collection("Refrigerators")
      .where('member', arrayContains: FirebaseAuth.instance.currentUser!.uid)
      .get(); // 냉장고 찾기
  String docid = snapshot.docs[0].id;

  final refData =
      await FirebaseFirestore.instance.collection("Refrigerators/" + docid + "/Ingredients").get(); // 재료 문서들

  for (int i = 0; i < refData.docs.length; i++) {
    var element = refData.docs[i]; // 각각의 문서
    map[element.id] = {
      'name': element.data()['name'],
      'category': element.data()['category'],
      'amount': element.data()['amount'],
      'expire_date': element.data()['expire_date']
    }; // docid : {name, category, amount, expire_date}
  }
  return map; // {재료문서uid : {'name': 사과, 'category': 과일, 'amount': 1, 'expire_date': 유통기한(Timestamp)}}
}

Future<Map<String, List<dynamic>>> getAutoOrSelfData(List wholeList) async {
  // wholeList = [{name:가지,is_countable:true,amount_double:2}...]
  Map<String, List<dynamic>> map = {'auto': [], 'minus': [], 'amountString': [], 'unmatched': []};
  Map refData =
      await getRefData(); // {재료문서uid : {'name': 사과, 'category': 과일, 'amount': 1, 'expire_date': 유통기한(Timestamp)}}
  Map realRecipeData = {}; // 냉장고에 있는 레시피재료
  Map realRefData = {};
  List nameList = []; // 레시피 재료의 이름만 가져오기
  Map refElement = {};
  Map recipeElement = {};
  Map inputElement = {};
  int index;
  String amountString = "";

  for (int i = 0; i < wholeList.length; i++) {
    nameList.add(wholeList[i]['name']);
    // recipeData[wholeList[i]['name']] = wholeList[i];
  } // nameList = [가지, 식용유, 다진마늘, ...]

  // refData에서 wholeList에 있는 것만 가져오기(이름 match) => realRefData에 넣기
  for (int i = 0; i < refData.length; i++) {
    if (nameList.contains(refData.values.elementAt(i)['name'])) {
      realRefData[refData.keys.elementAt(i)] = refData.values
          .elementAt(i); // {재료문서uid : {'name': 사과, 'category': 과일, 'amount': 1, 'expire_date': 유통기한(Timestamp)}}
      index = nameList.indexOf(refData.values.elementAt(i)['name']); // wholeList의 index
      realRecipeData[wholeList[index]['name']] =
          wholeList[index]; // {가지: {name: 가지,is_countable:true,amount_double:2}...}
    }
  }

  // (체크) 나중에 육류는 특별취급 해야 하지만 없다고 치자.

  // 자동차감, 직접 수정 나누기
  // wholeList[i][is_countable]==true && realRefData amount>=0 && 냉장고amount - 레시피amount_double>=0 => 자동차감해서 auto에 넣기.
  //                                                             냉장고amount - 레시피amount_double<0  => 자동차감해서 minus에 넣기.
  // realRefData amount < 0(많음~매우적음) => amountString에 넣기
  // realRefData amount >= 0 && wholeList[i][is_countable]==false => unmatched에 넣기

  for (int i = 0; i < realRefData.length; i++) {
    refElement = {};
    recipeElement = {};
    inputElement = {};
    // (체크) 냉장고에 중복 식재료 없다고 가정했음. 나중에 수정하기...
    refElement.addAll(realRefData.values.elementAt(i));
    refElement.addAll({
      'docid': realRefData.keys.elementAt(i)
    }); // {docid: 재료문서uid,'name': 사과, 'category': 과일, 'amount': 1, 'expire_date': 유통기한(Timestamp)}
    recipeElement =
        realRecipeData[realRefData.values.elementAt(i)['name']]; // {name:가지,is_countable:true,amount_double:2}
    // print(recipeElement['name']);
    // print(refElement['name']);
    if (recipeElement['is_countable'] == true && refElement['amount'] > 0) {
      if (refElement['amount'].toDouble() - recipeElement['amount_double'].toDouble() >= 0) {
        // 레시피is_countable==true && 냉장고 amount>0 && 냉장고amount - 레시피amount_double>=0 => 자동차감해서 auto에 넣기.
        refElement['amount_result'] =
            refElement['amount'].toDouble() - recipeElement['amount_double'].toDouble(); // 남은 개수
        // 개수 string(정수면 .0 빼기)
        if (refElement['amount'] % 1 == 0) {
          int num = refElement['amount'].toInt();
          amountString = num.toString() + "개";
        } else {
          amountString = refElement['amount'].toString() + "개";
        }
        refElement['amount'] = amountString;
        inputElement = refElement;
        inputElement.addAll({
          'amount_subtract': recipeElement['amount_double'].toString() + "개",
          'removed': false,
          'edit_required': false,
          'half': false,
        }); // 자동차감된 개수(amount_subtract)(string), 모두사용 여부(removed), 수정필요 여부(edit_required) // (체크)setting 완료할 때 auto의 amount_result가 0이라면 식재료 아예 빼버려야 함.
        map['auto']?.add(inputElement);
      } else {
        // 레시피is_countable==true && 냉장고 amount>0 && 냉장고amount - 레시피amount_double<0  => 자동차감해서 minus에 넣기.
        refElement['amount_result'] =
            refElement['amount'].toDouble() - recipeElement['amount_double'].toDouble(); // 남은 개수(minus)
        // 개수 string(정수면 .0 빼기)
        if (refElement['amount'] % 1 == 0) {
          int num = refElement['amount'].toInt();
          amountString = num.toString() + "개";
        } else {
          amountString = refElement['amount'].toString() + "개";
        }
        refElement['amount'] = amountString;
        inputElement = refElement;
        inputElement.addAll({
          'amount_subtract': recipeElement['amount_double'].toString() + "개",
          'removed': false,
          'edit_required': true,
          'half': false,
        }); // 자동차감된 개수(amount_subtract)(string), 모두사용 여부(removed), 수정필요 여부(edit_required)
        map['minus']?.add(inputElement);
      }
    } else {
      if (refElement['amount'] < 0) {
        // realRefData amount < 0(많음~매우적음) => amountString에 넣기
        inputElement['amount_result'] = refElement['amount'].toDouble(); // amount_result: double값
        switch (refElement['amount']) {
          case -1:
            refElement['amount'] = "매우적음";
            refElement['amount_result'] = -1;
            break;
          case -2:
            refElement['amount'] = "적음";
            refElement['amount_result'] = -2;
            break;
          case -3:
            refElement['amount'] = "보통";
            refElement['amount_result'] = -3;
            break;
          case -4:
            refElement['amount'] = "많음";
            refElement['amount_result'] = -4;
            break;
        }
        inputElement = refElement;
        if (recipeElement['is_countable']) {
          inputElement.addAll({'amount_subtract': recipeElement['amount_double'].toString() + "개"});
        } else {
          inputElement.addAll({'amount_subtract': recipeElement['amount_string'] + recipeElement['unit_string']});
        }
        inputElement.addAll({
          'removed': false,
          'edit_required': true // 수정 불필요 (체크) 하지만 처음에 클릭하기 전에는 빨간색으로 보여야 해서 default true로 놓았음.
        }); // 자동차감된 개수(amount_subtract)(string), 모두사용 여부(removed), 수정필요 여부(edit_required)
        map['amountString']?.add(inputElement);
      } else {
        // realRefData amount > 0 && wholeList[i][is_countable]==false => unmatched에 넣기
        refElement['amount_result'] = refElement['amount'].toDouble();
        // 개수 string(정수면 .0 빼기)
        if (refElement['amount'] % 1 == 0) {
          int num = refElement['amount'].toInt();
          amountString = num.toString() + "개";
        } else {
          amountString = refElement['amount'].toString() + "개";
        }
        refElement['amount'] = amountString;
        inputElement = refElement;
        inputElement.addAll({
          'amount_subtract': recipeElement['amount_string'] + recipeElement['unit_string'],
          'removed': false,
          'edit_required': true, // 수정 불필요 (체크) 하지만 처음에 클릭하기 전에는 빨간색으로 보여야 해서 default true로 놓았음.
          'half': false,
        }); // 자동차감된 개수(amount_subtract)(string), 모두사용 여부(removed), 수정필요 여부(edit_required) // (체크)setting 완료할 때 auto의 amount_result가 0이라면 식재료 아예 빼버려야 함.
        map['unmatched']?.add(inputElement);
      }
    }
  }
  print(map);
  return map; // 실제 냉장고 데이터.  keys: auto, minus, amountString, unmatched로 나눠서 저장하기. Map<List>
}

// 수정한 대로 냉장고 식재료 수정하기
// amount_result==0||removed==true => docid 찾아서 지우기.
// 그 이외의 경우 => docid 찾아서 amount 수정하기
Future<bool> editRefData(Map setting, String menuDocId, DateTime menuDateTime) async {
  // auto, minus, amountString, unmatched
  List keys = ['auto', 'minus', 'amountString', 'unmatched'];
  Map element = {};
  final snapshot = await FirebaseFirestore.instance
      .collection("Refrigerators")
      .where('member', arrayContains: FirebaseAuth.instance.currentUser!.uid)
      .get();
  final refDocId = snapshot.docs[0].id; // 냉장고 docid

  for (int i = 0; i < keys.length; i++) {
    for (int k = 0; k < setting[keys[i]].length; k++) {
      element = setting[keys[i]][k];
      if (element['amount_result'] == 0 || element['removed'] == true) {
        // amount_result==0||removed==true => docid 찾아서 지우기.
        await FirebaseFirestore.instance
            .collection("Refrigerators/" + refDocId + "/Ingredients")
            .doc(element['docid'])
            .delete();
      } else {
        // 그 이외의 경우 => docid 찾아서 amount 수정하기
        await FirebaseFirestore.instance
            .collection("Refrigerators/" + refDocId + "/Ingredients")
            .doc(element['docid'])
            .update({'amount': element['amount_result']});
      }
    }
  }

  // 메뉴 완료로 바꾸기
  await FirebaseFirestore.instance
      .collection("Users/" +
          FirebaseAuth.instance.currentUser!.uid +
          "/Calendar/" +
          intl.DateFormat('yyyy.MM.dd').format(menuDateTime) +
          "/MealPlans")
      .doc(menuDocId)
      .update({'completed': true});
  return true;
}

class MenuCompletePage extends StatefulWidget {
  MenuCompletePage({Key? key}) : super(key: key);

  @override
  State<MenuCompletePage> createState() => _MenuCompletePageState();
}

class _MenuCompletePageState extends State<MenuCompletePage> {
  bool autoChecked = false; // 자동 차감 버튼
  bool selfChecked = true; // 직접 수정 버튼
  // Map<dynamic, List<Map<String, dynamic>>> setting = {};
  bool possible = true;
  Map<dynamic, List<dynamic>> setting = {'auto': [], 'minus': [], 'amountString': [], 'unmatched': []};
  bool executed = false;
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments
        as Map; // wholeList => [{name:가지,is_countable:true,amount_double:2}...], menuDocId, menuDateTime
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            backgroundColor: colorBackground,
            body: SafeArea(
              child: Column(
                children: [
                  //appBar 상단바
                  Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 12.0), // (체크)(중요) 전체적인 상단바 padding 수정하기
                            child: Stack(
                              children: [
                                // 뒤로가기 버튼
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: IconButton(
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          padding: EdgeInsets.all(0.0),
                                          splashRadius: 10,
                                          icon: Icon(Icons.arrow_back, size: 24))),
                                ),
                                // 제목
                                Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                        height: 24,
                                        child: Text("식재료 양 수정", style: interBold17))), // (체크) fontweight Semi bold
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: SizedBox(
                                    width: 44,
                                    height: 28,
                                    child: TextButton(
                                      onPressed: () async {
                                        // (edit_required 모두 false이면 실행
                                        // removed==true || amount_result==0인 것 docid 찾아서 지우고,
                                        // 그 이외의 것은 냉장고 재료 amount 수정하기.
                                        possible = true;
                                        setting['minus']?.forEach((element) {
                                          if (element['edit_required']) {
                                            possible = false;
                                          }
                                        });
                                        setting['amountString']?.forEach((element) {
                                          if (element['edit_required']) {
                                            possible = false;
                                          }
                                        });
                                        setting['unmatched']?.forEach((element) {
                                          if (element['edit_required']) {
                                            possible = false;
                                          }
                                        });
                                        if (!possible) {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                content: Text("아직 수정이 필요한 항목이 있습니다."),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text("확인"))
                                                ],
                                              );
                                            },
                                          );
                                        } else {
                                          // 완료하기
                                          if (await editRefData(setting, args['menuDocId'], args['menuDateTime'])) {
                                            navigatorKey.currentState
                                                ?.pushNamedAndRemoveUntil('/home_page', (route) => false);
                                          }
                                        }
                                      },
                                      child: Text("완료", style: inter13Blue),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.fromLTRB(10, 6, 10, 6),
                                        side: BorderSide(
                                            color: colorPoint,
                                            width: 0.5), // (체크) figma 줄 두께는 0.5인데 에뮬레이터로 보면 너무 얇아 보임. 실제 기기에서 확인하기
                                        splashFactory: NoSplash.splashFactory,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            )),
                      ],
                    ),
                    color: Color.fromARGB(245, 255, 255, 255),
                    height: 50, // (체크) 원래 44인데 좀 늘림. 나중에 실제 앱에서 확인해보기
                  ),
                  // 구분선
                  Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
                  // 상단바 이외 영역 --------
                  Expanded(
                    child: SingleChildScrollView(
                      child: FutureBuilder(
                          future: getAutoOrSelfData(args['wholeList']),
                          builder: (context, AsyncSnapshot snapshot) {
                            if (snapshot.hasError) {
                              return Center(child: Text("Error"));
                            } else if (snapshot.hasData) {
                              if (!executed) {
                                // 처음 실행
                                // setting에 식재료 자동차감, 직접수정 데이터 넣기.
                                // setting = snapshot.data();  // 에러 => 실수로라도 ()를 넣는 일은 없도록 하자...
                                setting = snapshot.data as Map<dynamic,
                                    List<dynamic>>; // {auto: [], minus: [], amountString: [], unmatched: []}
                                // auto, minus, unmatched에만 half 넣어놓았음.
                                executed = true;
                              }
                              return Column(
                                children: [
                                  // 자동 차감 버튼
                                  Container(
                                      height: 56,
                                      width: MediaQuery.of(context).size.width,
                                      color: Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                        child: Row(
                                          children: [
                                            Text("자동 차감", style: interBold17),
                                            Expanded(child: Container()),
                                            SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: IconButton(
                                                    splashColor: Colors.transparent,
                                                    highlightColor: Colors.transparent,
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () {
                                                      autoChecked = !autoChecked;
                                                      setState(() {});
                                                    },
                                                    icon: Transform.rotate(
                                                        angle: autoChecked ? 0 : 180 * math.pi / 180,
                                                        child: Icon(Icons.expand_more, size: 24, color: colorGrey3)))),
                                          ],
                                        ),
                                      )),
                                  // 자동 차감 영역
                                  autoChecked == false ? Container() : autoList(setting['auto'] as List<dynamic>),
                                  SizedBox(height: 8),
                                  // 직접 수정 버튼
                                  Container(
                                      height: 56,
                                      width: MediaQuery.of(context).size.width,
                                      color: Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                        child: Row(
                                          children: [
                                            Text("직접 수정", style: interBold17),
                                            Expanded(child: Container()),
                                            SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: IconButton(
                                                    splashColor: Colors.transparent,
                                                    highlightColor: Colors.transparent,
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () {
                                                      selfChecked = !selfChecked;
                                                      setState(() {});
                                                    },
                                                    icon: Transform.rotate(
                                                        angle: selfChecked ? 0 : 180 * math.pi / 180,
                                                        child: Icon(Icons.expand_more, size: 24, color: colorGrey3)))),
                                          ],
                                        ),
                                      )),
                                  // 직접 수정 영역
                                  selfChecked == false
                                      ? Container()
                                      : selfList(
                                          setting['minus'] as List<dynamic>,
                                          setting['amountString'] as List<dynamic>,
                                          setting['unmatched'] as List<dynamic>),
                                ],
                              );
                            } else {
                              return Container();
                            }
                          }),
                    ),
                  )
                ],
              ),
            )));
  }

  Widget autoList(List mapList) {
    // [{name, category, amount, expire_date, amount_subtract, removed, edit_required, docid, amount_result}]
    return Column(
      children: [
        for (int i = 0; i < mapList.length; i++)
          Column(
            children: [
              Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
              autoItemBox(mapList[i], i),
            ],
          ),
      ],
    );
  }

  Widget autoItemBox(Map map, int seq) {
    // {name, category, amount, expire_date, amount_subtract, removed, edit_required, docid, amount_result} (추가) half
    int dDay = map['expire_date'].toDate().difference(DateTime.now()).inDays.toInt();
    String dDayString = ""; // 디데이 string
    String amountString = ""; // 양(개수) string
    if (dDay > 0) {
      dDayString = "D - " + dDay.toString();
    } else if (dDay == 0) {
      dDayString = "D - Day";
    } else if (dDay < 0) {
      int dDay_minus = dDay * (-1);
      dDayString = "D + " + dDay_minus.toString();
    }
    if (map['amount_result'] % 1 == 0) {
      // 개수 string(정수면 .0 빼기)
      int num = map['amount_result'].toInt();
      amountString = num.toString() + "개";
    } else {
      amountString = map['amount_result'].toString() + "개";
    }
    return Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(23.0),
          child: Column(
            children: [
              // 식재료 정보 영역
              Row(
                children: [
                  Container(
                      child: Center(
                        child: Image.asset(
                          'src/ingredient_apple.png',
                          width: 40,
                          height: 44,
                        ),
                      ),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: colorBackground),
                      width: 64,
                      height: 64),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      category_box(map['category']),
                      SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(map['name'], style: interBold18),
                          SizedBox(width: 6),
                          Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: colorGrey1),
                              width: 3,
                              height: 3),
                          SizedBox(width: 6),
                          Text(dDayString,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.bold,
                                  color: dDay < 4 ? colorRed : colorBlue,
                                  leadingDistribution: TextLeadingDistribution.even))
                        ],
                      )
                    ],
                  ),
                  Expanded(child: Container()),
                  // 모두 사용 or 되돌리기 버튼(removed)
                  !map['removed']
                      ? SizedBox(
                          height: 28,
                          width: 72,
                          child: TextButton(
                              onPressed: () {
                                setting['auto']![seq]['removed'] = !setting['auto']![seq]['removed'];
                                setState(() {});
                              },
                              child: Text("모두 사용", style: inter13Black),
                              style: TextButton.styleFrom(
                                  splashFactory: NoSplash.splashFactory,
                                  backgroundColor: Color.fromARGB(25, 34, 34, 34), // colorBlack 10%
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
                        )
                      : SizedBox(
                          height: 28,
                          width: 72,
                          child: TextButton(
                              onPressed: () {
                                setting['auto']![seq]['removed'] = !setting['auto']![seq]['removed'];
                                setState(() {});
                              },
                              child: Text("되돌리기", style: inter13Red),
                              style: TextButton.styleFrom(
                                  splashFactory: NoSplash.splashFactory,
                                  backgroundColor: Color.fromARGB(25, 255, 0, 0), // colorRed 10%
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
                        )
                ],
              ),
              SizedBox(height: 24),
              // 차감 영역
              Column(children: [
                Row(
                  children: [
                    Text("원래 개수",
                        style: TextStyle(
                            fontSize: 13, fontFamily: "Inter", color: Color.fromARGB(255, 149, 149, 149), height: 1)),
                    Expanded(child: Container()),
                    Text(map['amount'], style: interBold13)
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text("자동 차감된 개수",
                        style: TextStyle(
                            fontSize: 13, fontFamily: "Inter", color: Color.fromARGB(255, 149, 149, 149), height: 1)),
                    Expanded(child: Container()),
                    Text(map['amount_subtract'], style: interBold13)
                  ],
                ),
                SizedBox(height: 10),
                // 구분선
                Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
                SizedBox(height: 16),
                // 개수 박스
                Container(
                    width: MediaQuery.of(context).size.width - 48,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 247, 249, 251), borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0), child: Text("남은 개수", style: inter14Black)),
                        Text(map['removed'] ? "0개" : amountString, style: inter14Grey),
                        Expanded(child: Container()),
                        // + 버튼
                        SizedBox(
                            height: 24,
                            width: 24,
                            child: IconButton(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onPressed: () {
                                  if (map['half']) {
                                    // 반개 단위일때
                                    setting['auto']![seq]['amount_result'] += 0.5;
                                  } else {
                                    setting['auto']![seq]['amount_result'] += 1;
                                  }
                                  setState(() {});
                                },
                                icon: Icon(Icons.add, size: 24),
                                padding: EdgeInsets.all(0))),
                        SizedBox(width: 6),
                        // - 버튼
                        SizedBox(
                            // (체크) 뺀 값이 마이너스면 실행취소
                            height: 24,
                            width: 24,
                            child: IconButton(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onPressed: () {
                                  // 뺀 값이 마이너스면 실행 안 됨.
                                  if (map['half'] && map['amount_result'] >= 0.5) {
                                    // 반개 단위
                                    setting['auto']![seq]['amount_result'] -= 0.5;
                                  } else if (!map['half'] && map['amount_result'] >= 1) {
                                    // 1개 단위
                                    setting['auto']![seq]['amount_result'] -= 1;
                                  }
                                  setState(() {});
                                },
                                icon: Icon(Icons.remove, size: 24),
                                padding: EdgeInsets.all(0))),
                      ],
                    )),
                SizedBox(height: 16),
                Container(
                    child: Row(
                  children: [
                    // 반개 단위 체크 버튼
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: TextButton(
                          onPressed: () {
                            setting['auto']![seq]['half'] = !setting['auto']![seq]['half'];
                            setState(() {});
                          },
                          child: Icon(Icons.check, color: Colors.white, size: 16),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              // backgroundColor: info['half'] ? colorPoint : Colors.white,
                              backgroundColor: map['half'] ? colorPoint : Colors.white,
                              shape: RoundedRectangleBorder(
                                  side: BorderSide(color: colorPoint), borderRadius: BorderRadius.circular(100.0)))),
                    ),
                    SizedBox(width: 6),
                    Text("반개 단위", style: inter14Black)
                  ],
                ))
              ]),
            ],
          ),
        ));
  }

  Widget selfList(List minusList, List amountStringList, List unmatchedList) {
    return Column(
      children: [
        // 자동 차감 했더니 개수가 마이너스
        for (int i = 0; i < minusList.length; i++)
          Column(
            children: [
              Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
              minusItemBox(minusList[i], i),
            ],
          ),
        // 냉장고 식재료 단위가 개수x단위 -> 많음~매우적음 으로 조정해야 함
        for (int i = 0; i < amountStringList.length; i++)
          Column(
            children: [
              Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
              amountStringItemBox(amountStringList[i], i),
            ],
          ),
        // 단위가 안 맞음(원래 식재료 개수단위+레시피 자동차감 개수x단위)
        for (int i = 0; i < unmatchedList.length; i++)
          Column(
            children: [
              Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
              unmatchedItemBox(unmatchedList[i], i),
            ],
          ),
      ],
    );
  }

  // 자동 차감 했더니 개수가 마이너스
  Widget minusItemBox(Map map, int seq) {
    // {name, category, amount, expire_date, amount_subtract, removed, edit_required, docid, amount_result} (추가) half
    int dDay = map['expire_date'].toDate().difference(DateTime.now()).inDays.toInt();
    String dDayString = ""; // 디데이 string
    String amountString = ""; // 양(개수) string
    if (dDay > 0) {
      dDayString = "D - " + dDay.toString();
    } else if (dDay == 0) {
      dDayString = "D - Day";
    } else if (dDay < 0) {
      int dDay_minus = dDay * (-1);
      dDayString = "D + " + dDay_minus.toString();
    }
    if (map['amount_result'] % 1 == 0) {
      // 개수 string(정수면 .0 빼기)
      int num = map['amount_result'].toInt();
      amountString = num.toString() + "개";
    } else {
      amountString = map['amount_result'].toString() + "개";
    }
    return Container(
        color: map['edit_required'] ? colorWarning : Colors.white, // 경고색
        child: Padding(
          padding: const EdgeInsets.all(23.0),
          child: Column(
            children: [
              // 식재료 정보 영역
              Row(
                children: [
                  Container(
                      child: Center(
                        child: Image.asset(
                          'src/ingredient_apple.png',
                          width: 40,
                          height: 44,
                        ),
                      ),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: colorBackground),
                      width: 64,
                      height: 64),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      category_box(map['category']),
                      SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(map['name'], style: interBold18),
                          SizedBox(width: 6),
                          Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: colorGrey1),
                              width: 3,
                              height: 3),
                          SizedBox(width: 6),
                          Text(dDayString,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.bold,
                                  color: colorBlue,
                                  leadingDistribution: TextLeadingDistribution.even))
                        ],
                      )
                    ],
                  ),
                  Expanded(child: Container()),
                  // 삭제 or 되돌리기 버튼(removed)
                  !map['removed']
                      ? SizedBox(
                          height: 29,
                          width: 46,
                          child: TextButton(
                              onPressed: () {
                                setting['minus']![seq]['removed'] = !setting['minus']![seq]['removed'];
                                setState(() {});
                              },
                              child: Text("삭제", style: inter13Red),
                              style: TextButton.styleFrom(
                                  splashFactory: NoSplash.splashFactory,
                                  backgroundColor: Color.fromARGB(25, 255, 0, 0), // colorRed 10%
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
                        )
                      : SizedBox(
                          height: 28,
                          width: 72,
                          child: TextButton(
                              onPressed: () {
                                setting['minus']![seq]['removed'] = !setting['minus']![seq]['removed'];
                                setState(() {});
                              },
                              child: Text("되돌리기", style: inter13Red),
                              style: TextButton.styleFrom(
                                  splashFactory: NoSplash.splashFactory,
                                  backgroundColor: Color.fromARGB(25, 255, 0, 0), // colorRed 10%
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
                        )
                ],
              ),
              SizedBox(height: 24),
              // 차감 영역
              Column(children: [
                Row(
                  children: [
                    Text("원래 개수",
                        style: TextStyle(
                            fontSize: 13, fontFamily: "Inter", color: Color.fromARGB(255, 149, 149, 149), height: 1)),
                    Expanded(child: Container()),
                    Text(map['amount'], style: interBold13)
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text("자동 차감된 개수",
                        style: TextStyle(
                            fontSize: 13, fontFamily: "Inter", color: Color.fromARGB(255, 149, 149, 149), height: 1)),
                    Expanded(child: Container()),
                    Text(map['amount_subtract'], style: interBold13)
                  ],
                ),
                SizedBox(height: 10),
                // 구분선
                Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
                SizedBox(height: 16),
                // 개수 박스
                Container(
                    width: MediaQuery.of(context).size.width - 48,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 247, 249, 251), borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0), child: Text("남은 개수", style: inter14Black)),
                        Text(map['removed'] ? "0개" : amountString,
                            style: map['amount_result'] >= 0 || map['removed'] ? inter14Black : inter14Red),
                        Expanded(child: Container()),
                        // + 버튼
                        SizedBox(
                            height: 24,
                            width: 24,
                            child: IconButton(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                //(체크) onPressed => 개수 1 or 0.5 감소(그렇게 계산된 값이 음수라면 취소)
                                onPressed: () {
                                  if (map['half']) {
                                    // 반개 단위일때
                                    setting['minus']![seq]['amount_result'] += 0.5;
                                  } else {
                                    setting['minus']![seq]['amount_result'] += 1;
                                  }
                                  // 더해서 계산된 값이 0 이상이면 edit_required=false
                                  if (setting['minus']![seq]['amount_result'] >= 0) {
                                    setting['minus']![seq]['edit_required'] = false;
                                  }
                                  setState(() {});
                                },
                                icon: Icon(Icons.add, size: 24),
                                padding: EdgeInsets.all(0))),
                        SizedBox(width: 6),
                        // - 버튼
                        SizedBox(
                            height: 24,
                            width: 24,
                            child: IconButton(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onPressed: () {
                                  // 뺀 값이 마이너스면 실행 안 됨.
                                  if (map['half'] && map['amount_result'] >= 0.5) {
                                    // 반개 단위
                                    setting['minus']![seq]['amount_result'] -= 0.5;
                                  } else if (!map['half'] && map['amount_result'] >= 1) {
                                    // 1개 단위
                                    setting['minus']![seq]['amount_result'] -= 1;
                                  }
                                  setState(() {});
                                },
                                icon: Icon(Icons.remove, size: 24),
                                padding: EdgeInsets.all(0))),
                      ],
                    )),
                SizedBox(height: 16),
                Container(
                    child: Row(
                  children: [
                    // 반개 단위 체크 버튼
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: TextButton(
                          onPressed: () {
                            setting['minus']![seq]['half'] = !setting['minus']![seq]['half'];
                            setState(() {});
                          },
                          child: Icon(Icons.check, color: Colors.white, size: 16),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              // backgroundColor: info['half'] ? colorPoint : Colors.white,
                              backgroundColor: map['half'] ? colorPoint : Colors.white,
                              shape: RoundedRectangleBorder(
                                  side: BorderSide(color: colorPoint), borderRadius: BorderRadius.circular(100.0)))),
                    ),
                    SizedBox(width: 6),
                    Text("반개 단위", style: inter14Black)
                  ],
                ))
              ]),
            ],
          ),
        ));
  }

  // 냉장고 식재료 단위가 개수x단위 -> 많음~매우적음 으로 조정해야 함
  Widget amountStringItemBox(Map map, int seq) {
    // {name, category, amount, expire_date, amount_subtract, removed, edit_required, docid, amount_result} (여기에는 half 없음!)
    int dDay = map['expire_date'].toDate().difference(DateTime.now()).inDays.toInt();
    String dDayString = ""; // 디데이 string
    String amountString = ""; // 양(개수) string
    if (dDay > 0) {
      dDayString = "D - " + dDay.toString();
    } else if (dDay == 0) {
      dDayString = "D - Day";
    } else if (dDay < 0) {
      int dDay_minus = dDay * (-1);
      dDayString = "D + " + dDay_minus.toString();
    }
    if (map['amount_result'] < 0) {
      // 많음/보통/적음/매우적음
      switch ((map['amount_result'] * (-1)).toInt()) {
        case 1:
          amountString = "매우적음";
          break;
        case 2:
          amountString = "적음";
          break;
        case 3:
          amountString = "보통";
          break;
        case 4:
          amountString = "많음";
          break;
      }
    } else if (map['amount_result'] % 1 == 0) {
      // 개수 string(정수면 .0 빼기)
      int num = map['amount_result'].toInt();
      amountString = num.toString() + "개";
    } else {
      amountString = map['amount_result'].toString() + "개";
    }
    return Container(
        color: map['edit_required'] ? colorWarning : Colors.white, // 경고색
        child: Padding(
          padding: const EdgeInsets.all(23.0),
          child: Column(
            children: [
              // 식재료 정보 영역
              Row(
                children: [
                  Container(
                      child: Center(
                        child: Image.asset(
                          'src/ingredient_apple.png',
                          width: 40,
                          height: 44,
                        ),
                      ),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: colorBackground),
                      width: 64,
                      height: 64),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      category_box(map['category']),
                      SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(map['name'], style: interBold18),
                          SizedBox(width: 6),
                          Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: colorGrey1),
                              width: 3,
                              height: 3),
                          SizedBox(width: 6),
                          Text(dDayString,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.bold,
                                  color: colorBlue,
                                  leadingDistribution: TextLeadingDistribution.even))
                        ],
                      )
                    ],
                  ),
                  Expanded(child: Container()),
                  // 모두 사용 or 되돌리기 버튼(removed)
                  !map['removed']
                      ? SizedBox(
                          height: 28,
                          width: 72,
                          child: TextButton(
                              onPressed: () {
                                setting['amountString']![seq]['removed'] = !setting['amountString']![seq]['removed'];
                                setState(() {});
                              },
                              child: Text("모두 사용", style: inter13Black),
                              style: TextButton.styleFrom(
                                  splashFactory: NoSplash.splashFactory,
                                  backgroundColor: Color.fromARGB(25, 34, 34, 34), // colorBlack 10%
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
                        )
                      : SizedBox(
                          height: 28,
                          width: 72,
                          child: TextButton(
                              onPressed: () {
                                setting['amountString']![seq]['removed'] = !setting['amountString']![seq]['removed'];
                                setState(() {});
                              },
                              child: Text("되돌리기", style: inter13Red),
                              style: TextButton.styleFrom(
                                  splashFactory: NoSplash.splashFactory,
                                  backgroundColor: Color.fromARGB(25, 255, 0, 0), // colorRed 10%
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
                        )
                ],
              ),
              SizedBox(height: 24),
              // 차감 영역
              Column(children: [
                Row(
                  children: [
                    Text("원래 개수",
                        style: TextStyle(
                            fontSize: 13, fontFamily: "Inter", color: Color.fromARGB(255, 149, 149, 149), height: 1)),
                    Expanded(child: Container()),
                    Text(map['amount'], style: interBold13)
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text("자동 차감된 개수",
                        style: TextStyle(
                            fontSize: 13, fontFamily: "Inter", color: Color.fromARGB(255, 149, 149, 149), height: 1)),
                    Expanded(child: Container()),
                    Text(map['amount_subtract'], style: interBold13Red)
                  ],
                ),
                SizedBox(height: 10),
                // 구분선
                Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
                SizedBox(height: 16),
                // 많음~매우적음 버튼
                Container(
                    width: MediaQuery.of(context).size.width - 48,
                    height: 30,
                    color: Color.fromARGB(255, 247, 249, 251),
                    child: Row(
                      children: [
                        Expanded(
                            child: map['removed']
                                ? unselectedButton("많음", seq)
                                : amountString == "많음"
                                    ? selectedButton("많음", seq)
                                    : unselectedButton("많음", seq)),
                        amountString == "적음" || amountString == "매우적음"
                            ? Container(color: Colors.black, width: 0.5, height: 15)
                            : Container(),
                        Expanded(
                            child: map['removed']
                                ? unselectedButton("보통", seq)
                                : amountString == "보통"
                                    ? selectedButton("보통", seq)
                                    : unselectedButton("보통", seq)),
                        amountString == "많음" || amountString == "매우적음"
                            ? Container(color: Colors.black, width: 0.5, height: 15)
                            : Container(),
                        Expanded(
                            child: map['removed']
                                ? unselectedButton("적음", seq)
                                : amountString == "적음"
                                    ? selectedButton("적음", seq)
                                    : unselectedButton("적음", seq)),
                        amountString == "많음" || amountString == "보통"
                            ? Container(color: Colors.black, width: 0.5, height: 15)
                            : Container(),
                        Expanded(
                            child: map['removed']
                                ? unselectedButton("매우적음", seq)
                                : amountString == "매우적음"
                                    ? selectedButton("매우적음", seq)
                                    : unselectedButton("매우적음", seq)),
                      ],
                    )),
              ]),
            ],
          ),
        ));
  }

  // 단위가 안 맞음(원래 식재료 개수단위+레시피 자동차감 개수x단위)
  Widget unmatchedItemBox(Map map, int seq) {
    // {name, category, amount, expire_date, amount_subtract, removed, edit_required, docid, amount_result} (추가) half
    int dDay = map['expire_date'].toDate().difference(DateTime.now()).inDays.toInt();
    String dDayString = ""; // 디데이 string
    String amountString = ""; // 양(개수) string
    if (dDay > 0) {
      dDayString = "D - " + dDay.toString();
    } else if (dDay == 0) {
      dDayString = "D - Day";
    } else if (dDay < 0) {
      int dDay_minus = dDay * (-1);
      dDayString = "D + " + dDay_minus.toString();
    }
    if (map['amount_result'] % 1 == 0) {
      // 개수 string(정수면 .0 빼기)
      int num = map['amount_result'].toInt();
      amountString = num.toString() + "개";
    } else {
      amountString = map['amount_result'].toString() + "개";
    }
    return Container(
        color: map['edit_required'] ? colorWarning : Colors.white, // 경고색
        child: Padding(
          padding: const EdgeInsets.all(23.0),
          child: Column(
            children: [
              // 식재료 정보 영역
              Row(
                children: [
                  Container(
                      child: Center(
                        child: Image.asset(
                          'src/ingredient_apple.png',
                          width: 40,
                          height: 44,
                        ),
                      ),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: colorBackground),
                      width: 64,
                      height: 64),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      category_box(map['category']),
                      SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(map['name'], style: interBold18),
                          SizedBox(width: 6),
                          Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: colorGrey1),
                              width: 3,
                              height: 3),
                          SizedBox(width: 6),
                          Text(dDayString,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.bold,
                                  color: colorBlue,
                                  leadingDistribution: TextLeadingDistribution.even))
                        ],
                      )
                    ],
                  ),
                  Expanded(child: Container()),
                  // 모두 사용 or 되돌리기 버튼(removed)
                  !map['removed']
                      ? SizedBox(
                          height: 28,
                          width: 72,
                          child: TextButton(
                              onPressed: () {
                                setting['unmatched']![seq]['removed'] = !setting['unmatched']![seq]['removed'];
                                setState(() {});
                              },
                              child: Text("모두 사용", style: inter13Black),
                              style: TextButton.styleFrom(
                                  splashFactory: NoSplash.splashFactory,
                                  backgroundColor: Color.fromARGB(25, 34, 34, 34), // colorBlack 10%
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
                        )
                      : SizedBox(
                          height: 28,
                          width: 72,
                          child: TextButton(
                              onPressed: () {
                                setting['unmatched']![seq]['removed'] = !setting['unmatched']![seq]['removed'];
                                setState(() {});
                              },
                              child: Text("되돌리기", style: inter13Red),
                              style: TextButton.styleFrom(
                                  splashFactory: NoSplash.splashFactory,
                                  backgroundColor: Color.fromARGB(25, 255, 0, 0), // colorRed 10%
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
                        )
                ],
              ),
              SizedBox(height: 24),
              // 차감 영역
              Column(children: [
                Row(
                  children: [
                    Text("원래 개수",
                        style: TextStyle(
                            fontSize: 13, fontFamily: "Inter", color: Color.fromARGB(255, 149, 149, 149), height: 1)),
                    Expanded(child: Container()),
                    Text(map['amount'], style: interBold13)
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text("자동 차감된 개수",
                        style: TextStyle(
                            fontSize: 13, fontFamily: "Inter", color: Color.fromARGB(255, 149, 149, 149), height: 1)),
                    Expanded(child: Container()),
                    Text(map['amount_subtract'], style: interBold13Red)
                  ],
                ),
                SizedBox(height: 10),
                // 구분선
                Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
                SizedBox(height: 16),
                // 개수 박스
                Container(
                    width: MediaQuery.of(context).size.width - 48,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 247, 249, 251), borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0), child: Text("남은 개수", style: inter14Black)),
                        Text(map['removed'] ? "0개" : amountString, style: inter14Grey),
                        Expanded(child: Container()),
                        // + 버튼
                        SizedBox(
                            height: 24,
                            width: 24,
                            child: IconButton(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onPressed: () {
                                  if (map['half']) {
                                    // 반개 단위일때
                                    setting['unmatched']![seq]['amount_result'] += 0.5;
                                  } else {
                                    setting['unmatched']![seq]['amount_result'] += 1;
                                  }
                                  setting['unmatched']![seq]['edit_required'] = false;
                                  setState(() {});
                                },
                                icon: Icon(Icons.add, size: 24),
                                padding: EdgeInsets.all(0))),
                        SizedBox(width: 6),
                        // - 버튼
                        SizedBox(
                            height: 24,
                            width: 24,
                            child: IconButton(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onPressed: () {
                                  // 뺀 값이 마이너스면 실행 안 됨.
                                  if (map['half'] && map['amount_result'] >= 0.5) {
                                    // 반개 단위
                                    setting['unmatched']![seq]['amount_result'] -= 0.5;
                                  } else if (!map['half'] && map['amount_result'] >= 1) {
                                    // 1개 단위
                                    setting['unmatched']![seq]['amount_result'] -= 1;
                                  }
                                  setting['unmatched']![seq]['edit_required'] = false;
                                  setState(() {});
                                },
                                icon: Icon(Icons.remove, size: 24),
                                padding: EdgeInsets.all(0))),
                      ],
                    )),
                SizedBox(height: 16),
                Container(
                    child: Row(
                  children: [
                    // 반개 단위 체크 버튼
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: TextButton(
                          onPressed: () {
                            setting['unmatched']![seq]['half'] = !setting['unmatched']![seq]['half'];
                            setState(() {});
                          },
                          child: Icon(Icons.check, color: Colors.white, size: 16),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              // backgroundColor: info['half'] ? colorPoint : Colors.white,
                              backgroundColor: map['half'] ? colorPoint : Colors.white,
                              shape: RoundedRectangleBorder(
                                  side: BorderSide(color: colorPoint), borderRadius: BorderRadius.circular(100.0)))),
                    ),
                    SizedBox(width: 6),
                    Text("반개 단위", style: inter14Black)
                  ],
                ))
              ]),
            ],
          ),
        ));
  }

  Widget selectedButton(String name, int seq) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: ElevatedButton(
          onPressed: () {
            setting['amountString']![seq]['edit_required'] = false;
            setState(() {});
          }, // 선택해봤자 의미 없음. 하지만 누르면 edit_required = false;
          child: Text(name, style: interBold13White),
          style: ElevatedButton.styleFrom(
              primary: colorPoint,
              onPrimary: colorPoint,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)))),
    );
  }

  Widget unselectedButton(String name, int seq) {
    int amount = 0;
    switch (name) {
      case "많음":
        amount = -4;
        break;
      case "보통":
        amount = -3;
        break;
      case "적음":
        amount = -2;
        break;
      case "매우적음":
        amount = -1;
        break;
    }
    return Container(
        child: ElevatedButton(
            onPressed: () {
              setting['amountString']![seq]['amount_result'] = amount;
              setting['amountString']![seq]['edit_required'] = false;
              setState(() {});
            }, // 누르면 위치 바뀜. edit_required = false
            child: Text(
              name,
              style: inter13Black,
            ),
            style: ElevatedButton.styleFrom(primary: Color.fromARGB(255, 247, 249, 251), elevation: 0)));
  }
}
