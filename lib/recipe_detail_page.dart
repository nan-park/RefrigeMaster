import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:refrige_master/backside/app_design_comp.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart' as intl;
import 'package:fluttertoast/fluttertoast.dart';

import 'calendar_add_page.dart';
import 'main.dart';

Future<bool> writeStorageDoc(String recipe_uid, String name) async {
  print(recipe_uid + name);
  await FirebaseFirestore.instance
      .collection("Users/" + FirebaseAuth.instance.currentUser!.uid + "/Storage")
      .doc(recipe_uid)
      .set({'name': name, 'register_date': Timestamp.now()});
  // 이미 있는 레시피라면 등록날짜만 업데이트 되고 변하지 않는다.
  return true;
}

// recipe_uid에 해당하는 (고정)레시피 가져와서 재료 문서 리스트 긁어오기
Future<List> getRecipeDocumentList(String recipe_uid) async {
  List lists = [];

  final snapshot = await FirebaseFirestore.instance.collection("RecipeTemplates/" + recipe_uid + "/Ingredients").get();

  snapshot.docs.forEach((element) {
    lists.add(element.id);
  });
  return lists;
}

Future<Map> getRecipeDocument(String recipe_uid) async {
  List lists = await getRecipeDocumentList(recipe_uid); // 식재료 문서들
  Map<String, Map<String, dynamic>?> map = {}; // {recipe_uid : [Map]}

  for (int i = 0; i < lists.length; i++) {
    final documentData = await FirebaseFirestore.instance
        .collection("RecipeTemplates/" + recipe_uid + "/Ingredients")
        .doc(lists[i])
        .get();
    map[lists[i]] = documentData.data();
  } // key가 식재료 이름. {가지: {is_countable,category,amount_double?,amount_string?,unit_string?}, 간장: {}...}
  return map;
}

Future<Map> getRefData(String ref_docid, Map recipeData) async {
  Map refData = {};
  final ingredientDocSnapshot =
      await FirebaseFirestore.instance.collection("Refrigerators/" + ref_docid + "/Ingredients").get();

  for (int i = 0; i < ingredientDocSnapshot.docs.length; i++) {
    final each = ingredientDocSnapshot.docs[i];
    // final temp =
    //     await FirebaseFirestore.instance.collection("Refrigerators/" + ref_docid + "/Ingredients").doc(each.id).get();
    final temp = each.data();
    if (recipeData.keys.contains(temp['name'])) {
      // 레시피에 이 식재료가 있을 때
      refData[temp['name']] = temp['amount']; // 냉장고 속 식재료가 레시피 재료에 포함되면 map에 넣기 {가지: 3}
    }
  }

  // ingredientDocSnapshot.docs.forEach((element) async {
  //   // Ingredients
  //   final temp = await FirebaseFirestore.instance
  //       .collection("Refrigerators/" + ref_docid + "/Ingredients")
  //       .doc(element.id)
  //       .get();
  //   if (recipeData.keys.contains(temp.data()!['name'])) {
  //     // 레시피에 이 식재료가 있을 때
  //     refData[temp['name']] = temp['amount']; // 냉장고 속 식재료가 레시피 재료에 포함되면 map에 넣기 {가지: 3}
  //     print(refData);
  //     print("aj");
  //   }
  // });
  // 위의 함수가 안되는 이유 -> forEach 함수가 다 끝나기 전에 다음으로 넘어감

  return refData;
}

Future<Map> getEnoughOrLack(String recipe_uid) async {
  // (체크) 냉장고에 식재료가 중복으로 들어있을 때는 생각 안함..! 일단 중복 없다고 가정
  List lists = [];
  Map recipeData =
      await getRecipeDocument(recipe_uid); // 레시피 재료 {가지: {amount_double:1, category:채소, is_countable:true}...}
  Map refData = {}; // 냉장고 재료  {가지: 3}
  List enoughList = [];
  List lackList = [];
  final refSnapshot = await FirebaseFirestore.instance
      .collection("Refrigerators")
      .where('member', arrayContains: FirebaseAuth.instance.currentUser?.uid)
      .get();

  refData = await getRefData(refSnapshot.docs[0].id, recipeData); // 레시피 재료에 해당하는 냉장고 재료 정보 가져오기 {가지: 3, 사과: 1}
  // enough or lack 판단
  recipeData.forEach((key, value) {
    // 레시피 재료 {가지: {amount_double:1, category:채소, is_countable:true}...}
    value['name'] = key;
    if (!refData.keys.contains(key)) {
      // 레시피 재료가 냉장고에 아예 없는 경우 => 부족
      lackList.add(value);
      // lackMap[key] = value;
    } else {
      if (value['is_countable'] == false) {
        // 레시피 개수x 단위
        if (refData[key] > 0) {
          // 냉장고 개수 단위 => 부족
          lackList.add(value);
        } else if (refData[key] == -1) {
          // 냉장고 개수x 단위 + 매우적음 => 부족
          lackList.add(value);
        } else {
          // 냉장고 개수x 단위 + 매우적음x => 충분
          enoughList.add(value);
        }
      } else {
        // 레시피 개수 단위
        if (refData[key] > 0) {
          // 냉장고 개수 단위
          if (refData[key] - value['amount_double'] < 0) {
            // 냉장고-레시피 < 0 => 부족
            lackList.add(value);
          } else {
            // 냉장고-레시피 >= 0 => 충분
            enoughList.add(value);
          }
        } else {
          // 냉장고 개수x 단위
          if (refData[key] > 0) {
            // 냉장고 개수 단위 => 부족
            lackList.add(value);
          } else if (refData[key] == -1) {
            // 냉장고 개수x 단위 + 매우적음 => 부족
            lackList.add(value);
          } else {
            // 냉장고 개수x 단위 + 매우적음x => 충분
            enoughList.add(value);
          }
        }
      }
    }
  });
  Map enoughOrLack = {};
  enoughOrLack['enough'] = enoughList;
  enoughOrLack['lack'] = lackList;
  print(enoughOrLack);
  final recipe = await FirebaseFirestore.instance.collection("RecipeTemplates").doc(recipe_uid).get(); // 레시피 만드는법 가져오기
  enoughOrLack['how_to'] = recipe.data()!['how_to'];
  enoughOrLack['name_english'] = recipe.data()!['name_english'];
  return enoughOrLack;
}

class RecipeDetailPage extends StatefulWidget {
  RecipeDetailPage({Key? key}) : super(key: key);

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  List enoughList = [];
  List lackList = [];
  List howTo = [];
  String name = "";
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map; // 고정 레시피 recipe_uid, 요리 이름 name
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0), // (체크)(중요) 전체적인 상단바 padding 수정하기
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
                                      child: Text("레시피 상세 보기", style: interBold17))), // (체크) fontweight Semi bold
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
                    child: Column(
                      children: [
                        SizedBox(height: 24),
                        // 요리 정보 박스
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 23.0),
                          child: Row(children: [
                            // 요리 프로필 사진
                            Container(
                                child: Center(
                                  child: Image.asset(
                                    'src/meal_meat_spaghetti.png',
                                    width: 72,
                                    height: 72,
                                  ),
                                ),
                                width: 96,
                                height: 96,
                                decoration:
                                    BoxDecoration(color: colorBackground, borderRadius: BorderRadius.circular(12.0))),
                            SizedBox(width: 10),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              // 1인분 버튼 //(체크)(중요) 이거는 식단에 추가되지 않았을 경우 고정되지 않음. 프론트 변수로만 취급할 예정. 메뉴에 추가한 식단은 따로 diet_detail_page를 만드는 게 낫겠다.
                              SizedBox(
                                width: 72,
                                height: 29,
                                child: TextButton(
                                  onPressed: () {}, // (체크) 나중에 몇인분 선택할 수 있게 만들어야 함.
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text("1인분", style: inter14Blue),
                                      SizedBox(width: 6),
                                      Transform.rotate(
                                          angle: 90 * math.pi / 180,
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            size: 12,
                                            color: colorBlue,
                                          )),
                                    ],
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Color.fromARGB(25, 0, 122, 255),
                                    padding: EdgeInsets.fromLTRB(10, 6, 10, 6),
                                    splashFactory: NoSplash.splashFactory,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(args['name'],
                                  style: TextStyle(fontSize: 18, fontFamily: "Inter", fontWeight: FontWeight.bold))
                            ])
                          ]),
                        ),
                        // 버튼 영역
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 23.0, vertical: 24.0),
                          child: Row(children: [
                            Expanded(
                                child: TextButton(
                              child: Text("보관함에 담기", style: inter14Blue),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                splashFactory: NoSplash.splashFactory,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: BorderSide(color: colorBlue, width: 1)),
                              ),
                              onPressed: () async {
                                if (await writeStorageDoc(args['recipe_uid'], args['name'])) {
                                  // (체크) toast message 뜸
                                  Fluttertoast.showToast(
                                      msg: "보관함에 담기 완료",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: colorGrey3,
                                      textColor: Colors.white,
                                      fontSize: 14.0);
                                  print("toast message");
                                }
                              },
                            )),
                            SizedBox(width: 10),
                            Expanded(
                                child: TextButton(
                              child: Text("내 식단에 추가", style: inter14White),
                              style: TextButton.styleFrom(
                                backgroundColor: colorBlue,
                                splashFactory: NoSplash.splashFactory,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                              ),
                              onPressed: () {
                                navigatorKey.currentState?.pushNamed('/calendar_add_page', arguments: {
                                  'recipe_uid': args['recipe_uid'],
                                  'name': args['name']
                                }); //(체크) 레시피 recipe_uid, name 넘겨서 db 연결 안해도 되게 하자.
                              }, // (체크) onPressed. 날짜에 추가했을 땐 그 페이지에서 바로 homepage로 넘어가게 하기. + 그냥 뒤로 갔을 땐 그대로..
                            ))
                          ]),
                        ),
                        // 구분선
                        Container(height: 0.5, width: MediaQuery.of(context).size.width - 46.0, color: colorGrey1),
                        FutureBuilder(
                            future: getEnoughOrLack(args['recipe_uid']),
                            // Map<String, List>
                            // {'enough': [{name:가지,is_countable:true,amount_double:2}...] 'lack': [...]}
                            builder: (context, AsyncSnapshot snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text("Error"),
                                );
                              } else if (snapshot.hasData) {
                                enoughList = snapshot.data['enough'];
                                lackList = snapshot.data['lack'];
                                howTo = snapshot.data['how_to'];
                                name = snapshot.data['name_english'];
                                return Column(
                                  children: [
                                    // 재료 영역
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 23.0, vertical: 24.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("재료", style: interBold17),
                                          SizedBox(height: 16),
                                          ingredientBox(true, enoughList), // 사용 가능한 재료
                                          SizedBox(height: 16),
                                          ingredientBox(false, lackList), // 부족한 재료 (체크) 부족한 재료는 이름 누르면 이커머스 페이지 연결해야 함.
                                        ],
                                      ),
                                    ),
                                    // 구분선
                                    Container(
                                        height: 0.5,
                                        width: MediaQuery.of(context).size.width - 46.0,
                                        color: colorGrey1),
                                    // 만드는 법 영역
                                    Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 23.0, vertical: 24.0),
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text("만드는 법", style: interBold17),
                                          SizedBox(height: 24),
                                          howToList(howTo, name),
                                        ])),
                                  ],
                                );
                              } else {
                                return Container();
                              }
                            }),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )),
    );
  }

  Widget ingredientBox(bool isEnough, List itemList) {
    if (itemList.length == 0) {
      return Container();
    } else {
      List<List> fourList = [];
      int itemCount = 0;
      int fourCount = 0;
      int listCount = 0;
      int remainCount;
      Color backColor;
      for (int i = 0; i < itemList.length; i++) {
        // 4개 단위로 끊어서 리스트화하기
        if (fourCount == 4) {
          listCount++;
          fourCount = 0;
        }
        if (fourCount == 0) {
          fourList.add([itemList[i]]);
        } else {
          fourList[listCount].add(itemList[i]);
        }
        fourCount++;
        itemCount++;
      }
      remainCount = 4 - itemCount % 4;
      for (int i = 0; i < remainCount; i++) {
        fourList[listCount].add({});
      }
      print(fourList);

      if (isEnough) {
        backColor = Color.fromARGB(12, 0, 122, 255);
      } else {
        backColor = Color.fromARGB(12, 255, 0, 0);
      }
      return Container(
        height: 114 + 104 * listCount.toDouble(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  SizedBox(height: 10),
                  for (int i = 0; i < listCount + 1; i++)
                    Row(
                      children: [for (int k = 0; k < 4; k++) itemBox(fourList[i][k])],
                    )
                ],
              ),
            ),
            Container(
                width: 25,
                child: isEnough
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("사", style: inter12Blue),
                          Text("용", style: inter12Blue),
                          Text("가", style: inter12Blue),
                          Text("능", style: inter12Blue)
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Text("부", style: inter12Red), Text("족", style: inter12Red)],
                      ))
          ],
        ),
        decoration: BoxDecoration(color: backColor, borderRadius: BorderRadius.circular(10.0)),
      );
    }
  }

  Widget itemBox(Map map) {
    if (map.isNotEmpty) {
      String name;
      String amount;
      name = map['name'];
      // amount 판단
      if (map['is_countable']) {
        amount = map['amount_double'].toString() + "개";
      } else {
        amount = "(" + map['amount_string'] + map['unit_string'] + ")";
      }
      return Expanded(
          child: Container(
        height: 94,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            child: Center(
              child: Image.asset(
                'src/ingredient_apple.png',
                width: 20,
                height: 20,
              ),
            ),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
            height: 40,
            width: 40,
          ),
          SizedBox(height: 8),
          Text(name, style: TextStyle(fontSize: 12, fontFamily: "Inter", color: colorBlack, height: 1.2)),
          Text(amount, style: TextStyle(fontSize: 12, fontFamily: "Inter", color: colorBlack, height: 1.2)),
        ]),
      ));
    } else {
      return Expanded(child: Container());
    }
  }

  Widget howToList(List howTo, String name) {
    return Column(
      children: [
        for (int i = 0; i < howTo.length; i++)
          Column(
            children: [howToBox(i + 1, howTo[i], name), SizedBox(height: 24)],
          )
      ],
    );
  }

  Widget howToBox(int sequence, String eachText, name) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(sequence.toString() + ". " + eachText, style: inter15)),
        Container(
          width: (MediaQuery.of(context).size.width - 46.0) / 2,
          height: (MediaQuery.of(context).size.width - 46.0) / 2,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0)),
          child: Image.asset(
            'src/' + name + sequence.toString() + '.png',
            width: (MediaQuery.of(context).size.width - 46.0) / 2,
            height: (MediaQuery.of(context).size.width - 46.0) / 2,
          ),
        )
      ],
    );
  }
}
