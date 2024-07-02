import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:refrige_master/backside/app_design_comp.dart';

import 'main.dart';
// 전역변수

// 함수들

// 현재 냉장고 하나만 가져오기
Future<Map?> refGetDocument() async {
  Map<String, Map<String, dynamic>?> map = {}; // {docid : [Map]}

  // final snapshot = await FirebaseFirestore.instance
  //     .collection("Refrigerators")
  //     .where('present_member', arrayContains: FirebaseAuth.instance.currentUser?.uid)
  //     .get() as DocumentSnapshot;
  final snapshot = await FirebaseFirestore.instance
      .collection("Refrigerators")
      .where('member', arrayContains: FirebaseAuth.instance.currentUser?.uid)
      .get();
  // print(snapshot.data());
  for (int i = 0; i < snapshot.docs.length; i++) {
    String docid = snapshot.docs[i].id;
    map[docid] = snapshot.docs[i].data();
    return map;
  }
  return null;
}

// 냉장고에서 재료 가져오기(ref_detail_page 전용. 개수제한 없음)
Future<List> ingredientGetDocumentList(String docid, int refPage, int buttonChecked) async {
  List lists = [];
  String location = "";
  if (refPage == 1) {
    location = "냉장";
  } else if (refPage == 2) {
    location = "냉동";
  } else if (refPage == 3) {
    location = "기타";
  }

  if (buttonChecked == 1) {
    // 유통기한 임박순(expire_date)
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("Refrigerators/" + docid + "/Ingredients")
        .where('location', isEqualTo: location)
        .orderBy('expire_date', descending: false)
        .get();
    snapshot.docs.forEach((element) {
      lists.add(element.id);
    });
  } else if (buttonChecked == 2) {
    // 자주 사는 식재료순(register_count) // (체크) 수정 필요
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("Refrigerators/" + docid + "/Ingredients")
        .where('location', isEqualTo: location)
        .orderBy('register_count', descending: true)
        .get();
    snapshot.docs.forEach((element) {
      lists.add(element.id);
    });
  } else {
    // 등록순(register_date)
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("Refrigerators/" + docid + "/Ingredients")
        .where('location', isEqualTo: location)
        .orderBy('register_date', descending: true)
        .get();
    snapshot.docs.forEach((element) {
      lists.add(element.id);
    });
  }

  return lists;
}

Future<Map> ingredientGetDocument(String docid, int refPage, int buttonChecked) async {
  List lists = await ingredientGetDocumentList(docid, refPage, buttonChecked); //
  Map<String, Map<String, dynamic>?> map = {}; // {docid : [Map]}

  for (int i = 0; i < lists.length; i++) {
    final documentData =
        await FirebaseFirestore.instance.collection("Refrigerators/" + docid + "/Ingredients").doc(lists[i]).get();
    map[lists[i]] = documentData.data();
  }
  print(map);
  return map;
}

class RefDetailPage extends StatefulWidget {
  RefDetailPage({Key? key}) : super(key: key);

  @override
  State<RefDetailPage> createState() => _RefDetailPageState();
}

class _RefDetailPageState extends State<RefDetailPage> {
  // 변수들
  int refPageSelected = 1;
  String pre_docid = "";
  int buttonChecked = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: refGetDocument(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error"));
            }
            if (!snapshot.hasData) {
              //(체크) 냉장고 없을 때 추가 유도 해야함.. 근데 detail page라 굳이 안넣어도 되려나
              return Center(child: Text("No data"));
            } else {
              pre_docid = snapshot.data.keys.elementAt(0);
              return Column(
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
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    padding: EdgeInsets.all(0.0),
                                    splashRadius: 10,
                                    icon: Icon(Icons.arrow_back, size: 24),
                                  ),
                                ),
                              ),
                              // 제목
                              Align(
                                alignment: Alignment.center,
                                child: Container(
                                    height: 24,
                                    child: Text(snapshot.data.values.elementAt(0)['ref_name'], style: interBold17)),
                              ), // (체크) fontweight Semibold로 바꾸기
                              Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // 검색 버튼
                                      SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: IconButton(
                                              splashColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              padding: EdgeInsets.all(0),
                                              onPressed: () {},
                                              icon: Icon(Icons.search),
                                              color: Color.fromARGB(128, 34, 34, 34))),
                                      SizedBox(width: 12),
                                      // 설정 버튼
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: IconButton(
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          padding: EdgeInsets.all(0),
                                          onPressed: () {
                                            // (체크) 지금은 멤버 리스트만 보여주지만 나중에 선택지 바텀시트 보여줘야 함.
                                            navigatorKey.currentState?.pushNamed(
                                              '/member_list_page',
                                              arguments: {
                                                "refId": pre_docid,
                                                "refName": snapshot.data.values.elementAt(0)['ref_name'],
                                              },
                                            );
                                          },
                                          icon: Icon(Icons.settings),
                                          color: Color.fromARGB(128, 34, 34, 34),
                                        ),
                                      ),
                                    ],
                                  ))
                            ],
                          ),
                        ),
                      ],
                    ),
                    color: Color.fromARGB(245, 255, 255, 255),
                    height: 44,
                  ),
                  // 냉장/냉동/기타 탭(refPageSelected)
                  Container(
                      // (체크) 구분선과 클릭 범위 간에 공백 있는데 왜일까
                      child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          child: TextButton(
                            child: Text("냉장", style: inter14Blue),
                            onPressed: () {
                              setState(() {
                                refPageSelected = 1;
                              });
                            },
                            style: ElevatedButton.styleFrom(splashFactory: NoSplash.splashFactory),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          child: TextButton(
                            child: Text("냉동", style: inter14Blue),
                            onPressed: () {
                              setState(() {
                                refPageSelected = 2;
                              });
                            },
                            style: ElevatedButton.styleFrom(splashFactory: NoSplash.splashFactory),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          child: TextButton(
                            child: Text("기타", style: inter14Blue),
                            onPressed: () {
                              setState(() {
                                refPageSelected = 3;
                              });
                            },
                            style: ElevatedButton.styleFrom(splashFactory: NoSplash.splashFactory),
                          ),
                        ),
                      ),
                    ],
                  )),
                  // 구분선(refPageSelected)
                  Row(
                    children: [
                      // 냉장
                      Container(
                          height: 0.5,
                          width: MediaQuery.of(context).size.width / 3,
                          color: refPageSelected == 1 ? colorPoint : colorGrey1),
                      // 냉동
                      Container(
                          height: 0.5,
                          width: MediaQuery.of(context).size.width / 3,
                          color: refPageSelected == 2 ? colorPoint : colorGrey1),
                      // 기타
                      Container(
                          height: 0.5,
                          width: MediaQuery.of(context).size.width / 3,
                          color: refPageSelected == 3 ? colorPoint : colorGrey1),
                    ],
                  ),
                  // 스크롤 가능 영역
                  Expanded(
                    child: SingleChildScrollView(
                        child: Column(
                      children: [
                        Container(
                            height: 54,
                            child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Row(
                                  children: [
                                    Align(
                                      // 식재료 소팅 버튼(bottom sheet)
                                      // (체크) 커스텀 이미지랑 같이 넣기
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // (체크) 순서정렬 잘 되는지 확인
                                            if (await foodSortBottomSheet()) {
                                              setState(() {});
                                            }
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                buttonChecked == 1
                                                    ? "유통기한 임박순"
                                                    : buttonChecked == 2
                                                        ? "자주 사는 식재료순"
                                                        : "등록순",
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontFamily: "Inter",
                                                  fontSize: 13,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Container(
                                                width: 20,
                                                height: 20,
                                                child: Image(
                                                  image: AssetImage("src/down.png"),
                                                ),
                                              ),
                                            ],
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                            primary: Color.fromARGB(0, 0, 0, 0),
                                            elevation: 0.0,
                                            side: BorderSide(
                                              color: Color.fromARGB(40, 34, 34, 34),
                                              width: 1,
                                            ),
                                            splashFactory: NoSplash.splashFactory,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Spacer(),
                                    Align(
                                      // 편집 버튼(식재료 삭제)
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        child: Text("편집", style: inter14Black),
                                        onPressed: () {
                                          navigatorKey.currentState?.pushNamed("/food_edit_page");
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          splashFactory: NoSplash.splashFactory,
                                        ),
                                      ),
                                    )
                                  ],
                                ))),
                        // 구분선
                        Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
                        // 식재료 목록
                        foodList(snapshot.data.keys.elementAt(0), refPageSelected),
                      ],
                    )),
                  ),
                ],
              );
            }
          }),
      // 플로팅 버튼(식재료 추가)
      floatingActionButton: FloatingActionButton(
          heroTag: 'refDetailTap',
          onPressed: () {
            navigatorKey.currentState?.pushNamed('/food_search_page');
          },
          backgroundColor: colorPoint,
          child: Icon(Icons.add)),
    );
  }

  // 식재료 소팅 바텀시트
  Future<bool> foodSortBottomSheet() async {
    await showModalBottomSheet(
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
            return SafeArea(
                //시트 전체
                child: Container(
                    height: 245,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0), // 공백 상하 27 / 좌우 16
                      child: Stack(children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("선택한 상태 보기", style: interBold17),
                              SizedBox(height: 16),
                              Container(height: 0.5, width: MediaQuery.of(context).size.width * 0.9, color: colorGrey1),
                              SizedBox(height: 16),
                              Text("유통기한 임박순", style: inter17),
                              SizedBox(height: 16),
                              Container(height: 0.5, width: MediaQuery.of(context).size.width * 0.9, color: colorGrey1),
                              SizedBox(height: 16),
                              Text("자주 사는 식재료순", style: inter17),
                              SizedBox(height: 16),
                              Container(height: 0.5, width: MediaQuery.of(context).size.width * 0.9, color: colorGrey1),
                              SizedBox(height: 16),
                              Text("등록순", style: inter17)
                            ],
                          ),
                        ),
                        Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              children: [
                                // 나가기 버튼(닫기)
                                SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: TextButton(
                                        onPressed: () {
                                          navigatorKey.currentState?.pop();
                                        },
                                        child: Icon(Icons.clear, size: 20, color: Color.fromARGB(153, 60, 60, 67)),
                                        style: TextButton.styleFrom(
                                            splashFactory: NoSplash.splashFactory,
                                            padding: EdgeInsets.zero,
                                            backgroundColor: Color.fromARGB(255, 242, 242, 247),
                                            shape:
                                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.0))))),
                                SizedBox(height: 33),
                                // 유통기한 임박순 버튼 //(체크) 버튼 누르면 자동으로 바텀시트 닫히고 업데이트 되도록 하는 게 좋을까?
                                SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            buttonChecked = 1;
                                          });
                                        },
                                        child: buttonChecked == 1
                                            ? Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(shape: BoxShape.circle, color: colorPoint))
                                            : Container(),
                                        style: TextButton.styleFrom(
                                            splashFactory: NoSplash.splashFactory,
                                            padding: EdgeInsets.zero,
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                side: BorderSide(color: colorPoint),
                                                borderRadius: BorderRadius.circular(100.0))))),
                                SizedBox(height: 33),
                                // 자주 사는 식재료순 버튼
                                SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            buttonChecked = 2;
                                          });
                                        },
                                        child: buttonChecked == 2
                                            ? Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(shape: BoxShape.circle, color: colorPoint))
                                            : Container(),
                                        style: TextButton.styleFrom(
                                            splashFactory: NoSplash.splashFactory,
                                            padding: EdgeInsets.zero,
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                side: BorderSide(color: colorPoint),
                                                borderRadius: BorderRadius.circular(100.0))))),
                                SizedBox(height: 33),
                                // 등록순 버튼
                                SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            buttonChecked = 3;
                                          });
                                        },
                                        child: buttonChecked == 3
                                            ? Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(shape: BoxShape.circle, color: colorPoint))
                                            : Container(),
                                        style: TextButton.styleFrom(
                                            splashFactory: NoSplash.splashFactory,
                                            padding: EdgeInsets.zero,
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                side: BorderSide(color: colorPoint),
                                                borderRadius: BorderRadius.circular(100.0))))),
                              ],
                            ))
                      ]),
                    )));
          });
        });
    // 바텀 시트 닫혔을 때
    print("Bottom sheet closed");
    return true;
  }

  Widget foodList(String docid, int refPageSelected) {
    return FutureBuilder(
        future: ingredientGetDocument(docid, refPageSelected, buttonChecked),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return Container();
          } else {
            return Column(
              // name, amount, expire_date
              children: [
                for (int i = 0; i < snapshot.data.length; i++)
                  food(
                    docid,
                    snapshot.data.keys.elementAt(i),
                    snapshot.data.values.elementAt(i)['name'],
                    snapshot.data.values.elementAt(i)['amount'].toDouble(),
                    snapshot.data.values.elementAt(i)['expire_date'].toDate(),
                  )
              ],
            ); // (체크) 개수 적으면 나머지 화면 빈공간으로 채워줘야 함
          }
        });
  }

  Widget food(String ref_docid, String ing_docid, String name, double amount, DateTime expire_date) {
    int dDay = expire_date.difference(DateTime.now()).inDays.toInt();
    String dDayString = ""; // 디데이 string
    String amountString = ""; // 개수 String
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
    return GestureDetector(
        onTap: () async {
          await navigatorKey.currentState
              ?.pushNamed('/food_detail_page', arguments: {"ref_docid": ref_docid, "ing_docid": ing_docid});
          setState(() {});
        },
        child: Column(
          children: [
            // 식재료 박스
            Container(
                height: 96,
                width: MediaQuery.of(context).size.width,
                child: Row(
                  children: [
                    SizedBox(width: 10),
                    Container(
                        child: Center(
                          child: Image.asset(
                            'src/ingredient_apple.png',
                            width: 40,
                            height: 40,
                          ),
                        ),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: colorBackground)), //(체크) 프로필 배경 사진 이외에도 이 색깔인지 확인하기.
                    SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 디데이
                        Text(dDayString,
                            style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Inter",
                                fontWeight: FontWeight.bold,
                                color: dDay < 4 ? colorRed : colorBlue)), //(체크) semi bold
                        SizedBox(height: 5),
                        Row(
                          children: [
                            // 식재료 이름
                            Text(name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Inter",
                                )),
                            Container(
                              height: 3,
                              width: 3,
                              margin: EdgeInsets.all(10),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: Colors.black),
                            ),
                            // 개수
                            Text(amountString,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Inter",
                                )),
                          ],
                        ),
                      ],
                    )
                  ],
                )),
            // 구분선
            Container(height: 0.5, width: MediaQuery.of(context).size.width * 0.9, color: colorGrey1)
          ],
        ));
  }
}
