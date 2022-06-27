import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:refrige_master/backside/app_design_comp.dart';
import 'package:refrige_master/food_detail_page.dart';
import 'package:refrige_master/main.dart';
import 'package:intl/intl.dart' as intl;

class FoodDetailEditPage extends StatefulWidget {
  FoodDetailEditPage({Key? key}) : super(key: key);

  @override
  State<FoodDetailEditPage> createState() => _FoodDetailEditPageState();
}

Future<Map> getIngredientDoc(String ref_docid, String ing_docid) async {
  Map<String, Map<String, dynamic>?> map = {};
  final snapshot =
      await FirebaseFirestore.instance.collection("Refrigerators/" + ref_docid + "/Ingredients").doc(ing_docid).get();

  String docid = snapshot.id;
  map[docid] = snapshot.data();
  print(map);
  return map;
}

Future<bool> editIngredientDoc(Map info, String ref_docid, String ing_docid) async {
  await FirebaseFirestore.instance
      .collection("Refrigerators/" + ref_docid + "/Ingredients")
      .doc(ing_docid)
      .update({'location': info['location'], 'expire_date': info['expire_date'], 'amount': info['amount']});
  return true;
}

class _FoodDetailEditPageState extends State<FoodDetailEditPage> {
  List setting = [];
  bool executed = false;
  Map info = {};
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  //appBar 상단바
                  Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
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
                                            navigatorKey.currentState?.pop();
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
                                        child: Text("식재료 상세", style: interBold17))), // (체크) fontweight Semi bold
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // 완료 버튼
                                        SizedBox(
                                            width: 44,
                                            height: 28,
                                            child: TextButton(
                                                child: Text("완료", style: inter13Blue),
                                                onPressed: () async {
                                                  // (체크) onPressed
                                                  if (await editIngredientDoc(
                                                      info, args['ref_docid'], args['ing_docid'])) {
                                                    navigatorKey.currentState?.pop();
                                                  }
                                                },
                                                style: TextButton.styleFrom(
                                                    padding: EdgeInsets.all(0),
                                                    backgroundColor: Color.fromARGB(25, 0, 122, 255))))
                                      ],
                                    ))
                              ],
                            )),
                      ],
                    ),
                    color: Color.fromARGB(245, 255, 255, 255),
                    height: 55,
                  ),
                  //구분선
                  Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey),
                  // 편집 영역
                  Padding(padding: EdgeInsets.all(24.0), child: settingList(args['ref_docid'], args['ing_docid']))
                ],
              ),
            )));
  }

  Widget settingList(String ref_docid, String ing_docid) {
    return FutureBuilder(
        future: getIngredientDoc(ref_docid, ing_docid),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (!executed) {
              info = snapshot.data.values.elementAt(0);
              info['half'] = false;
              executed = true;
            }
            print(info['expire_date']);
            DateTime expire_date = info['expire_date'].toDate();
            int dDay = expire_date.difference(DateTime.now()).inDays.toInt();
            String dDayString = ""; // 디데이 String
            String amountString = ""; // 개수 String
            double amount = info['amount'].toDouble();
            String expire_date_string = intl.DateFormat("yyyy.MM.dd").format(expire_date);
            if (dDay > 0) {
              dDayString = "D - " + dDay.toString();
            } else if (dDay == 0) {
              dDayString = "D - Day";
            } else if (dDay < 0) {
              int dDay_minus = dDay * (-1);
              dDayString = "D + " + dDay_minus.toString();
            }
            if (amount < 0) {
              // 많음/보통/적음/매우적음
              switch ((amount * (-1)).toInt()) {
                case 1:
                  amountString = "매우 적음";
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
            } else if (amount % 1 == 0) {
              // 개수 string(정수면 .0 빼기)
              int num = amount.toInt();
              amountString = num.toString() + "개";
            } else {
              amountString = amount.toString() + "개";
            }
            return Column(
              children: [
                // 식재료 정보 박스
                Row(
                  children: [
                    // 식재료 사진
                    Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100), color: Color.fromARGB(255, 242, 242, 246))),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 카테고리 박스
                        category_box(info['category']),
                        SizedBox(height: 6),
                        // 식재료 이름 (체크) info 있으면 옆에 아이콘 있도록
                        Text(info['name'], style: TextStyle(fontSize: 18, fontFamily: "Inter")),
                        SizedBox(height: 8),
                        // 디데이(D-Day)
                        Text(dDayString,
                            style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Inter",
                                fontWeight: FontWeight.bold,
                                color: dDay < 4 ? colorRed : colorBlue)), //(체크) semi bold

                        SizedBox(height: 16),
                      ],
                    )
                  ],
                ),
                // 냉장/냉동/기타 선택 박스
                Container(
                    width: MediaQuery.of(context).size.width - 48,
                    height: 30,
                    color: Color.fromARGB(255, 247, 249, 251),
                    child: Row(
                      children: [
                        Expanded(child: info['location'] == "냉장" ? selectedButton("냉장") : unselectedButton("냉장")),
                        info['location'] == "기타" ? Container(color: Colors.black, width: 0.5, height: 15) : Container(),
                        Expanded(child: info['location'] == "냉동" ? selectedButton("냉동") : unselectedButton("냉동")),
                        info['location'] == "냉장" ? Container(color: Colors.black, width: 0.5, height: 15) : Container(),
                        Expanded(child: info['location'] == "기타" ? selectedButton("기타") : unselectedButton("기타")),
                      ],
                    )),
                SizedBox(height: 16),
                // 유통기한 선택(date_picker) 박스
                Container(
                    width: MediaQuery.of(context).size.width - 48,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 247, 249, 251), borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Row(
                      children: [
                        Container(
                            height: 42,
                            width: 80,
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(12, 12, 0, 12), child: Text("유통기한", style: inter14Black))),
                        Container(
                            height: 42,
                            child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(expire_date_string, style: inter14Grey))), // (체크) 실제 유통기한
                        Expanded(child: Container()),
                        SizedBox(
                            height: 20,
                            width: 20,
                            child: IconButton(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                //(체크) onPressed => date_picker
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final afterMonth = now.add(Duration(days: 30 * 12 * 20));
                                  final date = await showDatePicker(
                                    // (체크) 캘린더 한국어로 바꾸기  //(현재) 여기서 리스트가 배가 됨
                                    context: navigatorKey.currentState?.context as BuildContext,
                                    initialDate: now,
                                    firstDate: DateTime(now.year, now.month, now.day),
                                    lastDate: DateTime(afterMonth.year, afterMonth.month, afterMonth.day),
                                  );
                                  setState(() {
                                    info['expire_date'] = Timestamp.fromDate(date as DateTime);
                                  });
                                },
                                icon: Icon(Icons.calendar_today, size: 20),
                                padding: EdgeInsets.all(0))),
                        SizedBox(width: 12),
                      ],
                    )),
                SizedBox(height: 16),
                // 개수 박스
                Container(
                    width: MediaQuery.of(context).size.width - 48,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 247, 249, 251), borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Row(
                      children: [
                        Container(
                            height: 42,
                            width: 80,
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(25, 12, 0, 12), child: Text("개수", style: inter14Black))),
                        Container(
                            height: 42,
                            child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(amountString, style: inter14Grey))), // (체크) 실제 개수
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
                                  setState(() {
                                    if (info['half']) {
                                      // 반개 단위
                                      info['amount'] += 0.5;
                                    } else if (!info['half']) {
                                      // 1개 단위
                                      info['amount'] += 1;
                                    }
                                  });
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
                                  setState(() {
                                    if (info['half'] && amount >= 0.5) {
                                      // 반개 단위
                                      info['amount'] -= 0.5;
                                    } else if (!info['half'] && amount >= 1) {
                                      // 1개 단위
                                      info['amount'] -= 1;
                                    }
                                  });
                                },
                                icon: Icon(Icons.remove, size: 24),
                                padding: EdgeInsets.all(0))),
                      ],
                    )),
                SizedBox(height: 16),
                Container(
                    child: Row(
                  children: [
                    // 체크 버튼
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: TextButton(
                          onPressed: () {
                            setState(() {
                              info['half'] = !info['half'];
                            });
                          },
                          child: Icon(Icons.check, color: Colors.white, size: 16),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: info['half'] ? colorPoint : Colors.white,
                              shape: RoundedRectangleBorder(
                                  side: BorderSide(color: colorPoint), borderRadius: BorderRadius.circular(100.0)))),
                    ),
                    SizedBox(width: 6),
                    Text("반개 단위", style: inter14Black)
                  ],
                ))
              ],
            );
          } else {
            return Container();
          }
        });
  }

  Widget selectedButton(String name) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: ElevatedButton(
          onPressed: () {},
          child: Text(name, style: interBold13White),
          style: ElevatedButton.styleFrom(
              primary: colorPoint,
              onPrimary: colorPoint,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)))),
    );
  }

  Widget unselectedButton(String name) {
    return Container(
        child: ElevatedButton(
            onPressed: () {
              setState(() {
                info['location'] = name;
              });
            },
            child: Text(
              name,
              style: inter13Black,
            ),
            style: ElevatedButton.styleFrom(primary: Color.fromARGB(255, 247, 249, 251), elevation: 0)));
  }
}
