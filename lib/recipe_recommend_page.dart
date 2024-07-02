import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:refrige_master/backside/app_design_comp.dart';
import 'dart:math' as math;

import 'main.dart';
import 'recipe_detail_page.dart';

// 식재료 포함하는 (고정)레시피들 모두 가져오기 (체크) (재료 미포함)
Future<Map> getRecommendRecipeDocument(String ingredient) async {
  Map<String, Map<String, dynamic>?> map = {}; // {docid : [Map]}

  final snapshot = await FirebaseFirestore.instance
      .collection("RecipeTemplates")
      .where('ingredients', arrayContains: ingredient)
      .get();
  for (int i = 0; i < snapshot.docs.length; i++) {
    String docid = snapshot.docs[i].id;
    map[docid] = snapshot.docs[i].data();
  }
  print(map);
  return map;
}

// 냉장고 식재료 다 가져와서 expire_date 순으로 배열
Future<List> getIngredientNameList() async {
  List list = [];

  final refSnapshot = await FirebaseFirestore.instance
      .collection("Refrigerators")
      .where('member', arrayContains: FirebaseAuth.instance.currentUser!.uid)
      .get();
  final refDocId = refSnapshot.docs[0].id; // 냉장고 docid

  final ingSnapshot = await FirebaseFirestore.instance
      .collection("Refrigerators/" + refDocId + "/Ingredients")
      .orderBy('expire_date', descending: false)
      .get();

  for (int i = 0; i < ingSnapshot.docs.length; i++) {
    list.add(ingSnapshot.docs[i].data()['name']);
  }
  return list;
}

class DietRecommendPage extends StatefulWidget {
  DietRecommendPage({Key? key}) : super(key: key);

  @override
  State<DietRecommendPage> createState() => _DietRecommendPageState();
}

// dietTap 안의 페이지
class _DietRecommendPageState extends State<DietRecommendPage> {
  List nameList = [];
  List fourList = [];
  int foutListIndex = 0;
  int selectedIndex = 0;
  int pageIndex = 0;
  String selectedName = "";
  bool executed = false;
  bool pageChanged = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: colorBackground,
        body: Column(
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
                                  height: 24, child: Text("추천 식단", style: interBold17))), // (체크) fontweight Semi bold
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 56,
                              height: 28,
                              child: TextButton(
                                onPressed: () {
                                  navigatorKey.currentState?.pushNamed('/recipe_storage_page');
                                },
                                child: Text("보관함", style: inter13Blue),
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
            Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey3),
            // 상단바 이외 영역 -------
            Expanded(
              child: SingleChildScrollView(
                child: FutureBuilder(
                    // 식재료 가져와서 expire_date 순으로 배열
                    future: getIngredientNameList(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text("Error"));
                      } else if (snapshot.hasData) {
                        if (!executed) {
                          // 처음 실행
                          nameList = snapshot.data;
                          int itemCount = 0;
                          int fourCount = 0;
                          int listCount = 0;
                          for (int i = 0; i < nameList.length; i++) {
                            // 4개 단위로 끊어서 리스트화하기
                            if (fourCount == 4) {
                              listCount++;
                              fourCount = 0;
                            }
                            if (fourCount == 0) {
                              fourList.add([nameList[i]]);
                            } else {
                              fourList[listCount].add(nameList[i]);
                            }
                            fourCount++;
                            itemCount++;
                          }
                          executed = true;
                        }
                        if (pageChanged) {
                          // 화살표 눌렀을 때 selectedIndex 초기화
                          selectedIndex = 0;
                          pageChanged = false;
                        }
                        selectedName = fourList[pageIndex][selectedIndex];
                        print(fourList);
                        return Column(
                          children: [
                            SizedBox(height: 24),
                            // 식재료 선택 박스
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10.0),
                                        border: Border.all(color: colorPoint, width: 1.0)),
                                    width: MediaQuery.of(context).size.width - 32.0,
                                    height: 120,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                                      child: Row(children: [
                                        // 왼쪽 버튼
                                        SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: Transform.rotate(
                                              angle: 180 * math.pi / 180,
                                              child: IconButton(
                                                splashColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                padding: EdgeInsets.zero,
                                                icon: Icon(Icons.arrow_forward_ios,
                                                    size: 24,
                                                    color: pageIndex != 0
                                                        ? Color.fromARGB(255, 50, 50, 50)
                                                        : Color.fromARGB(125, 50, 50, 50)),
                                                onPressed: () {
                                                  if (pageIndex != 0) {
                                                    pageIndex -= 1;
                                                    pageChanged = true;
                                                  }
                                                  setState(() {});
                                                },
                                              ),
                                            )),
                                        expireItemList(fourList[pageIndex], selectedIndex),
                                        // 오른쪽 버튼
                                        SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: IconButton(
                                              splashColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              padding: EdgeInsets.zero,
                                              icon: Icon(Icons.arrow_forward_ios,
                                                  size: 24,
                                                  color: pageIndex != fourList.length - 1
                                                      ? Color.fromARGB(255, 50, 50, 50)
                                                      : Color.fromARGB(125, 50, 50, 50)),
                                              onPressed: () {
                                                if (pageIndex != fourList.length - 1) {
                                                  pageIndex += 1;
                                                  pageChanged = true;
                                                  setState(() {});
                                                }
                                              },
                                            )),
                                      ]),
                                    ))),
                            SizedBox(height: 16),
                            // 메뉴 박스
                            recommendRecipeList(selectedName),
                          ],
                        );
                      } else {
                        return Container();
                      }
                    }),
              ),
            ),
          ],
        ));
  }

  Widget expireItemList(List fourNameList, int selectedIndex) {
    // (체크) 눌렀을 때 색깔 변화 나중에 넣기
    int remainNum = 4 - fourNameList.length;
    return Expanded(
      child: Container(
          child: Row(
        children: [
          for (int i = 0; i < fourNameList.length; i++)
            selectedIndex == i ? expireItemBox(true, fourNameList[i], i) : expireItemBox(false, fourNameList[i], i),
          for (int i = 0; i < remainNum; i++) Expanded(child: Container())
        ],
      )),
    );
  }

  Widget expireItemBox(bool selected, String name, int index) {
    // (체크) 원래는 expire_date도 넣어야 하는데.. 나중에 하자 급하다..
    Color backColor;
    Color expireColor;
    Color nameColor;
    if (selected) {
      backColor = colorBlue;
      expireColor = Colors.white;
      nameColor = Colors.white;
    } else {
      backColor = Colors.white;
      expireColor = colorRed; // (체크) 원래는 파란색, 빨간색 유통기한 따라 나뉨.
      nameColor = colorBlack;
    }
    return Expanded(
        child: GestureDetector(
      onTap: () {
        selectedIndex = index;
        setState(() {});
      }, // 클릭하면 index 이걸로 바뀜.
      child: Container(
        decoration: BoxDecoration(color: backColor, borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            Text("D-1", style: TextStyle(fontSize: 14, fontFamily: "Inter", color: expireColor, height: 1)),
            SizedBox(height: 6),
            Container(
              child: Center(
                child: Image.asset(
                  'src/ingredient_apple.png',
                  width: 18,
                  height: 18,
                ),
              ),
              decoration: BoxDecoration(color: colorBackground, borderRadius: BorderRadius.circular(100)),
              height: 36,
              width: 36,
            ),
            SizedBox(height: 8),
            Text(name, style: TextStyle(fontSize: 12, fontFamily: "Inter", color: nameColor, height: 1))
          ]),
        ),
      ),
    ));
  }

  Widget recommendRecipeList(String ingredient) {
    return FutureBuilder(
        future: getRecommendRecipeDocument(ingredient),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error"));
          } else if (snapshot.hasData) {
            return Column(
              children: [
                for (int i = 0; i < snapshot.data.length; i++)
                  Column(
                    children: [
                      recommendRecipeBox(snapshot.data.keys.elementAt(i), snapshot.data.values.elementAt(i)['name']),
                      SizedBox(height: 16),
                    ],
                  )
              ],
            );
          } else {
            return Container();
          }
        });
  }

  // 식단 박스
  Widget recommendRecipeBox(String docid, String name) {
    return GestureDetector(
      onTap: () async {
        // (체크) onTap => 각각의 레시피 상세로 들어갈 수 있게끔 정보 넘겨줘야 함
        await navigatorKey.currentState
            ?.pushNamed('/recipe_detail_page', arguments: {'recipe_uid': docid, 'name': name});
        setState(() {}); // (체크) 일단 이렇게 썼는데 맞는 플로우인지 확인하기
      },
      child: Container(
          width: MediaQuery.of(context).size.width - 32.0,
          height: 112,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 음식 사진
                Container(
                    child: Center(
                      child: Image.asset(
                        'src/meal_meat_spaghetti.png',
                        width: 60,
                        height: 60,
                      ),
                    ),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: colorBackground)),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 메뉴 이름
                    Text(name, style: interBold17), // (체크) SemiBold
                    SizedBox(height: 13),
                    // 유통기한 식재료(최대 2개, 글자수 최대 4자) (체크)
                    Row(
                      children: [
                        expireDateItemBox(),
                        const SizedBox(width: 12),
                        expireDateItemBox()
                      ], // (체크) 나중엔 개수를 변수로 하여 itemList 위젯 만들기
                    )
                  ],
                )
              ],
            ),
          )),
    );
  }

  Widget expireDateItemBox() {
    return Container(
        child: Row(children: [
      Container(
          child: Center(
            child: Image.asset(
              'src/ingredient_apple.png',
              width: 18,
              height: 18,
            ),
          ),
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: colorBackground, borderRadius: BorderRadius.circular(100))),
      SizedBox(width: 4),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("D-1", style: TextStyle(color: Color.fromARGB(255, 235, 88, 40), fontFamily: "Inter", fontSize: 12)),
        Text("아스파라...", style: TextStyle(color: colorBlack, fontFamily: "Inter", fontSize: 12)),
      ]),
    ]));
  }
}
