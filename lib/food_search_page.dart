import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:refrige_master/backside/app_design_comp.dart';
import 'main.dart';

// 유저 정보에서 자주 사는 항목 찾기
Future<List> oftenGetDocumentList() async {
  List<String> lists = [];
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection("Users/" + FirebaseAuth.instance.currentUser!.uid + "/OftenItems")
      .orderBy("register_count", descending: true)
      .limit(6)
      .get();

  snapshot.docs.forEach((element) {
    lists.add(element.id);
  });

  return lists;
}

Future<Map> oftenGetDocument() async {
  List lists = await oftenGetDocumentList();
  Map<String, Map<String, dynamic>?> map = {}; // {docid : [Map]}

  for (int i = 0; i < lists.length; i++) {
    final documentData = await FirebaseFirestore.instance
        .collection("Users/" + FirebaseAuth.instance.currentUser!.uid + "/OftenItems")
        .doc(lists[i])
        .get();
    map[lists[i]] = documentData.data(); // ex. map = {사과 : {category: 과일, register_count: 3}}
  }
  print(map);
  return map;
}

// Template에서 검색 항목만 가져오기
Future<List> templateGetDocumentList(String inputText) async {
  List<String> lists = [];
  QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection("Templates").where("name", isEqualTo: inputText).get();
  // (현재)(체크) 검색은 되는데 비슷한 것까지 다 가져옴. 임시로 isEqualTo로 바꿈.
  snapshot.docs.forEach((element) {
    lists.add(element.id);
  });

  return lists;
}

Future<Map> templateGetDocument(String inputText) async {
  List lists = await templateGetDocumentList(inputText);
  Map<String, Map<String, dynamic>?> map = {}; // {docid : [Map]}

  for (int i = 0; i < lists.length; i++) {
    final documentData = await FirebaseFirestore.instance.collection("Templates").doc(lists[i]).get();
    map[lists[i]] = documentData.data(); // ex. map = {docid : {category: 과일, name: 사과}}
  }

  return map;
}

// 전역 변수(global)
List<String> item_selected = []; // ex. ["사과/과일", "가지/채소"]

class FoodSearchPage extends StatefulWidget {
  FoodSearchPage({Key? key}) : super(key: key);

  @override
  State<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  // 변수들
  String inputText = "";
  int searchedItemCount = 5; // 검색 결과 항목 개수
  int selectedItemCount = 1; // 추가하기로 선택한 항목 개수
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(), // 키보드 이외의 영역 선택하면 키보드 사라짐
                // 전체 영역 div
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //appBar 상단바
                    Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Stack(
                                children: [
                                  // 뒤로가기 버튼
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: IconButton(
                                            onPressed: () {
                                              item_selected = []; // 선택 항목 리스트 초기화
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
                                          child: Text("품목추가", style: interBold17))), // (체크) fontweight Semibold로 바꾸기
                                  // 완료 버튼 (체크) 디자인과 별개로 일단 넣어봤음. 나중에 디자인 확정되면 바꿀 수도?
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: IconButton(
                                            icon: Icon(Icons.check),
                                            padding: EdgeInsets.all(0.0),
                                            onPressed: () {
                                              navigatorKey.currentState?.pushNamed('/food_add_page', arguments: {
                                                "item_selected": item_selected
                                              }); //(체크) 직접 입력한 경우 카테고리가 없어서 "수박/" 이런식으로 될 수 있으니 예외 처리 주의.
                                            }),
                                      ))
                                ],
                              )),
                        ],
                      ),
                      color: Color.fromARGB(245, 255, 255, 255),
                      height: 55,
                    ),
                    // 검색창
                    Container(
                        height: 56,
                        color: Color.fromARGB(245, 255, 255, 255),
                        child: Padding(
                          padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 4, bottom: 10),
                          child: TextField(
                            autofocus: true,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                                hintText: "품목명을 입력하세요",
                                hintStyle: inter14Grey,
                                border: InputBorder.none,
                                hintMaxLines: 1,
                                fillColor: Color.fromARGB(255, 239, 241, 245),
                                filled: true),
                            onChanged: (text) {
                              // (체크) 리스너로 바꿀까..?
                              setState(() {
                                inputText = text;
                              });
                            },
                          ),
                        )),
                    // 구분선
                    Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey),
                    // 선택 항목(item_selected 비어있으면 안 나옴)
                    item_selected.isNotEmpty ? selectedItemBox() : Container(),
                    Expanded(
                      child: SingleChildScrollView(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 식재료 리스트(자주 사는 항목)  //(체크) 자주 산 항목 하나도 없으면 전체 항목 보여주자
                          inputText == "" ? oftenItemList() : searchItemList(inputText)
                        ],
                      )),
                    )
                  ],
                ),
              ),
            )));
  }

  Widget selectedItemBox() {
    print(item_selected);
    return Container(
        width: MediaQuery.of(context).size.width,
        height: 150,
        color: Color.fromARGB(255, 239, 241, 245),
        child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("선택 항목", style: inter17),
                SizedBox(height: 18),
                // 리스트
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < item_selected.length; i++)
                        Row(
                          children: [
                            selectedItem(
                                item_selected[i].split("/")[0], // 식재료 이름
                                item_selected[i].split("/")[1]), // 카테고리
                            SizedBox(width: 16),
                          ],
                        )
                    ],
                  ),
                )
              ],
            )));
  }

  Widget selectedItem(String name, String category) {
    return Column(
      children: [
        // 사진 + 취소 버튼
        Container(
          height: 52,
          width: 52,
          child: Stack(
            children: [
              // 사진
              Align(
                  alignment: Alignment.center,
                  child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: Colors.white))),
              Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: IconButton(
                          onPressed: () {
                            setState(() {
                              item_selected.remove(name + "/" + category);
                            });
                          },
                          padding: EdgeInsets.all(0.0),
                          splashRadius: 10,
                          icon: Icon(Icons.cancel, size: 18, color: Color.fromARGB(255, 235, 88, 40)))))
            ],
          ),
        ),
        SizedBox(height: 8),
        // 식재료 이름
        Text(name, style: inter14Black)
      ],
    );
  }

  Widget oftenItemList() {
    //(체크) 자주 사는 항목 없을 때 unfocus 가능하도록 expanded로 채워넣기. "자주 사는 항목" 텍스트도 빼기.
    // 자주 사는 항목. 아무리 많아도 7개 이하.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 10),
            child: Text("자주 사는 항목", style: inter17)),
        FutureBuilder(
            future: oftenGetDocument(),
            builder: (context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData) {
                return Container();
              } else {
                return Column(
                  children: [
                    for (int i = 0; i < snapshot.data.length; i++)
                      item(
                          snapshot.data.keys.elementAt(i), // 식재료 이름
                          snapshot.data.values.elementAt(i)['category']) // 카테고리
                  ],
                );
              }
            }),
      ],
    );
  }

  Widget searchItemList(String inputText) {
    // 검색 항목. Template 참고해서 실시간으로 가져옴
    return FutureBuilder(
        future: templateGetDocument(inputText),
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return Container();
          } else {
            return Column(
              children: [
                for (int i = 0; i < snapshot.data.length; i++)
                  item(
                      snapshot.data.values.elementAt(i)['name'], // 식재료 이름
                      snapshot.data.values.elementAt(i)['category']) // 카테고리
              ],
            );
          }
        });
  }

  Widget item(String name, String category) {
    return Container(
        // (중요)(체크) 클릭하면 선택항목에 추가되도록 하고(오른쪽 체크 버튼), oftenItem에 추가횟수 늘리고, 그 정보 가져와서 Refrigerators에 추가하기(writeDoc)
        height: 73,
        child: Column(
          children: [
            Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
                child: Row(children: [
                  // 식재료 사진
                  Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100), color: Color.fromARGB(255, 242, 242, 246))),
                  SizedBox(width: 16),
                  // 식재료 이름
                  Text(name, style: inter14Black),
                  SizedBox(width: 8),
                  Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100), color: Color.fromARGB(255, 34, 34, 34))),
                  SizedBox(width: 8),
                  // 카테고리
                  Text(category, style: inter14Black),
                  Expanded(child: Container()),
                  // 체크 버튼
                  SizedBox(
                      height: 20,
                      width: 20,
                      child: TextButton(
                          onPressed: () {
                            setState(() {
                              if (item_selected.contains(name + "/" + category)) {
                                item_selected.remove(name + "/" + category);
                              } else {
                                item_selected.add(name + "/" + category);
                              }
                            });
                          },
                          child: Icon(Icons.check, color: Colors.white, size: 16),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor:
                                  item_selected.contains(name + "/" + category) ? colorPoint : Colors.white,
                              shape: RoundedRectangleBorder(
                                  side: BorderSide(color: colorPoint), borderRadius: BorderRadius.circular(100.0))))),
                ])),
            // 구분선
            Container(height: 0.5, width: MediaQuery.of(context).size.width * 0.9, color: colorGrey)
          ],
        ));
  }
}
