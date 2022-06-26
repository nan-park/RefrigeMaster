import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:refrige_master/backside/app_design_comp.dart';
import 'main.dart';
import 'backside/login_view_model.dart';
import 'backside/kakao_login.dart';

// (중요 체크) 현재 홈화면 탭 누르면 초기화되도록 만들기(홈화면일때도 스크롤돼있으면 초기화). 홈화면 상태에서 뒤로가기 못하게 만들기(willpopscope)
// 전역 변수
int _currentIndex = 0;
int buttonChecked = 3;

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

// 함수들 ------------------------

// 자신의 냉장고들 리스트 찾아오기
Future<List> refGetDocumentList() async {
  List<String> lists = [];
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection("Refrigerators")
      .where('member', arrayContains: FirebaseAuth.instance.currentUser?.uid)
      .get();

  snapshot.docs.forEach((element) {
    lists.add(element.id);
  });

  return lists;
}

// 냉장고들 가져오기(내가 갖고있는 냉장고 전체)
Future<Map> refGetDocument() async {
  List lists = await refGetDocumentList(); //
  Map<String, Map<String, dynamic>?> map = {}; // {docid : [Map]}

  for (int i = 0; i < lists.length; i++) {
    final documentData = await FirebaseFirestore.instance.collection("Refrigerators").doc(lists[i]).get();
    map[lists[i]] = documentData.data();
  }
  print(map);
  return map;
}

// 현재 냉장고 하나만 가져오기
Future<Map?> presentRefGetDocument() async {
  Map<String, Map<String, dynamic>?> map = {}; // {docid : [Map]}

  // final snapshot = await FirebaseFirestore.instance
  //     .collection("Refrigerators")
  //     .where('present_member', arrayContains: FirebaseAuth.instance.currentUser?.uid)
  //     .get() as DocumentSnapshot;
  final snapshot = await FirebaseFirestore.instance
      .collection("Refrigerators")
      .where('present_member', arrayContains: FirebaseAuth.instance.currentUser?.uid)
      .get();
  // print(snapshot.data());
  for (int i = 0; i < snapshot.docs.length; i++) {
    String docid = snapshot.docs[i].id;
    map[docid] = snapshot.docs[i].data();
    return map;
  }
  return null;
}

// 냉장고에서 재료 가져오기(6개 제한. homepage 미리보기 전용.)
Future<List> limit_ingredientGetDocumentList(String docid, int refPage) async {
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
        .limit(6)
        .get();
    snapshot.docs.forEach((element) {
      lists.add(element.id);
    });
  } else if (buttonChecked == 2) {
    // 자주 사는 식재료순(register_count)
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("Refrigerators/" + docid + "/Ingredients")
        .where('location', isEqualTo: location)
        .orderBy('register_count', descending: true)
        .limit(6)
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
        .limit(6)
        .get();
    snapshot.docs.forEach((element) {
      lists.add(element.id);
    });
  }

  return lists;
}

Future<Map> limit_ingredientGetDocument(String docid, int refPage) async {
  List lists = await limit_ingredientGetDocumentList(docid, refPage); //
  Map<String, Map<String, dynamic>?> map = {}; // {docid : [Map]}

  for (int i = 0; i < lists.length; i++) {
    final documentData =
        await FirebaseFirestore.instance.collection("Refrigerators/" + docid + "/Ingredients").doc(lists[i]).get();
    map[lists[i]] = documentData.data();
  }
  print(map);
  return map;
}

// 냉장고에서 재료 가져오기(ref_detail_page 전용. 개수제한 없음)
Future<List> ingredientGetDocumentList(String docid, int refPage) async {
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
    // 자주 사는 식재료순(register_count)
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

Future<Map> ingredientGetDocument(String docid, int refPage) async {
  List lists = await limit_ingredientGetDocumentList(docid, refPage); //
  Map<String, Map<String, dynamic>?> map = {}; // {docid : [Map]}

  for (int i = 0; i < lists.length; i++) {
    final documentData =
        await FirebaseFirestore.instance.collection("Refrigerators/" + docid + "/Ingredients").doc(lists[i]).get();
    map[lists[i]] = documentData.data();
  }
  print(map);
  return map;
}

Future<bool> editPresentRef(String pre_docid, String docid) async {
  // remove
  await FirebaseFirestore.instance.collection("Refrigerators").doc(pre_docid).update({
    "present_member": FieldValue.arrayRemove([FirebaseAuth.instance.currentUser?.uid])
  });

  // add
  await FirebaseFirestore.instance.collection(("Refrigerators")).doc(docid).update({
    "present_member": FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.uid])
  });
  return true;
}

// Page Tap -----------------------

class _HomePageState extends State<HomePage> {
  final _navigatorKeyList = List.generate(3, (index) => GlobalKey<NavigatorState>());
  // 바텀 내비게이션 변수
  final _children = [RefTap(), MealTap(), MyTap()];
  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 55,
            child: BottomNavigationBar(
              elevation: 0.0,
              backgroundColor: Colors.white,
              selectedLabelStyle: const TextStyle(
                fontSize: 10,
                fontFamily: 'Inter',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 10,
                fontFamily: 'Inter',
              ),
              selectedItemColor: colorPoint,
              unselectedItemColor: Color.fromARGB(127, 34, 34, 34),
              onTap: _onTap,
              currentIndex: _currentIndex,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.question_answer_outlined),
                  label: ('냉장고'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  label: ('식단기록'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.question_answer_outlined),
                  label: ('마이페이지'),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: IndexedStack(
              // 안의 페이지 들어가서도 하단바 유지되도록
              index: _currentIndex,
              children: _children.map((child) {
                int index = _children.indexOf(child);
                return Navigator(
                    key: _navigatorKeyList[index],
                    onGenerateRoute: (_) {
                      return MaterialPageRoute(builder: (context) => child);
                    });
              }).toList()),
        ),
      ),
    );
  }
}

class RefTap extends StatefulWidget {
  @override
  State<RefTap> createState() => _RefTapState();
}

class _RefTapState extends State<RefTap> {
  //변수
  int refPageSelected = 1; // 홈화면 변수(냉장/냉동/기타)
  String pre_docid = ""; // present_document_id
  @override
  Widget build(BuildContext context) {
    // 빌드 이후 변수
    double widthPadding = MediaQuery.of(context).size.width - 32.0; //가로 패딩(양옆 16)
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            //appBar 상단바
            Container(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Stack(
                  children: [
                    Align(alignment: Alignment.centerLeft, child: Text("LOGO", style: interBold20Blue)),
                    // 알림 버튼
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {},
                              icon: Icon(Icons.notifications_none, size: 24))),
                    ),
                  ],
                ),
              ),
              color: Color.fromARGB(245, 255, 255, 255),
              height: 50,
            ),
            // 오늘의 메뉴 박스
            Container(
              color: Color.fromARGB(255, 242, 242, 246),
              height: 243,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(width: 10),
                      Text("오늘의 메뉴", style: TextStyle(fontFamily: "Inter", fontSize: 24, fontWeight: FontWeight.bold)),
                      Expanded(child: Container()),
                      SizedBox(
                          width: 16,
                          child: IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Color.fromARGB(130, 34, 34, 34),
                              ))),
                      SizedBox(width: 20),
                    ],
                  ),
                  SizedBox(height: 16),
                  // (체크) 스와이프 카드(오늘의 메뉴) (or gesture detector)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: widthPadding,
                        height: 136,
                        decoration:
                            BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(20))),
                      )
                    ],
                  )
                ],
              ),
            ),
            FutureBuilder(
                future: presentRefGetDocument(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error"));
                  }
                  if (!snapshot.hasData) {
                    //(현재)(체크) 이걸 생성된 냉장고가 없는 상태로 무조건 판단할 수 있을까? 예외가 있나?
                    return Column(children: [
                      SizedBox(height: 10),
                      Text("현재 생성된 냉장고가 없습니다. 냉장고를 추가해주세요!", style: inter14Black),
                      SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        width: MediaQuery.of(context).size.width - 32,
                        child: TextButton(
                            onPressed: () async {
                              await navigatorKey.currentState?.pushNamed('/ref_add_page');
                              setState(() {
                                presentRefGetDocument();
                              });
                            },
                            child: Text("냉장고 추가하기", style: inter17White),
                            style: TextButton.styleFrom(
                                backgroundColor: colorPoint,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)))),
                      )
                    ]);
                  } else {
                    pre_docid = snapshot.data.keys.elementAt(0);
                    return Column(
                      children: [
                        //냉장고 박스 div
                        Container(
                            child: Column(
                          children: [
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 냉장고 이름 //(체크) 영어일때, 한글일 때 글자 세로간격이 다른듯?
                                  Text(snapshot.data?.values.elementAt(0)['ref_name'],
                                      style: TextStyle(fontFamily: "Inter", fontSize: 24, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                  // 냉장고 목록 버튼
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: Transform.rotate(
                                      angle: 90 * math.pi / 180,
                                      child: IconButton(
                                          padding: EdgeInsets.all(0.0),
                                          onPressed: () async {
                                            if (await refAddBottomSheet(pre_docid)) {
                                              // 창 닫았을 때
                                              setState(() {});
                                            }
                                            // (체크)냉장고 개수에 따라 크기 바뀌어야 함
                                          },
                                          icon: Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Color.fromARGB(130, 34, 34, 34),
                                          )),
                                    ),
                                  ),
                                  Expanded(child: Container()),
                                  // 냉장고 더보기 버튼
                                  SizedBox(
                                      width: 58,
                                      height: 18,
                                      child: InkWell(
                                          //(체크) 누를 때 splash가 딱 맞는 직사각형이라 좀 어색해보임. 나중에 수정하기(디자이너에게 질문)
                                          child: Row(
                                            children: const [
                                              Text("더보기",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontFamily: "Inter",
                                                    color: Color.fromARGB(130, 34, 34, 34),
                                                    height: 1.2,
                                                  )),
                                              SizedBox(width: 2),
                                              SizedBox(
                                                height: 16,
                                                width: 16,
                                                child: Icon(Icons.arrow_forward_ios,
                                                    size: 16, color: Color.fromARGB(130, 34, 34, 34)),
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            Navigator.of(context)
                                                .push(MaterialPageRoute(builder: (context) => RefDetailPage()));
                                          })),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            // 냉장/냉동/기타 탭(refPageSelected)
                            Row(
                              children: [
                                SizedBox(width: 10),
                                // 냉장 버튼
                                TextButton(
                                  onPressed: () {
                                    if (refPageSelected != 1) {
                                      setState(() {
                                        refPageSelected = 1;
                                      });
                                    }
                                  },
                                  child: Text("냉장",
                                      style: TextStyle(
                                        fontFamily: "Inter",
                                        fontSize: 14,
                                        color: refPageSelected == 1 ? Colors.white : Colors.blue,
                                      )),
                                  style: TextButton.styleFrom(
                                      backgroundColor:
                                          refPageSelected == 1 ? Colors.blue : Color.fromARGB(255, 242, 242, 246),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
                                ),
                                SizedBox(width: 10),
                                // 냉동 버튼
                                TextButton(
                                  onPressed: () {
                                    if (refPageSelected != 2) {
                                      setState(() {
                                        refPageSelected = 2;
                                      });
                                    }
                                  },
                                  child: Text("냉동",
                                      style: TextStyle(
                                        fontFamily: "Inter",
                                        fontSize: 14,
                                        color: refPageSelected == 2 ? Colors.white : Colors.blue,
                                      )),
                                  style: TextButton.styleFrom(
                                      backgroundColor:
                                          refPageSelected == 2 ? Colors.blue : Color.fromARGB(255, 242, 242, 246),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
                                ),
                                SizedBox(width: 10),
                                // 기타 버튼
                                TextButton(
                                  onPressed: () {
                                    if (refPageSelected != 3) {
                                      setState(() {
                                        refPageSelected = 3;
                                      });
                                    }
                                  },
                                  child: Text("기타",
                                      style: TextStyle(
                                        fontFamily: "Inter",
                                        fontSize: 14,
                                        color: refPageSelected == 3 ? Colors.white : Colors.blue,
                                      )),
                                  style: TextButton.styleFrom(
                                      backgroundColor:
                                          refPageSelected == 3 ? Colors.blue : Color.fromARGB(255, 242, 242, 246),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Container(height: 1, color: Color.fromARGB(77, 34, 34, 34)),
                            // 식재료 목록
                            foodList(snapshot.data.keys.elementAt(0), refPageSelected), // docid
                          ],
                        )),
                      ],
                    );
                  }
                }),
          ],
        ),
      ),
      // 플로팅 버튼(식재료 추가)
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            navigatorKey.currentState?.pushNamed('/food_search_page');
          },
          backgroundColor: colorPoint,
          child: Icon(Icons.add)),
    );
  }

  // 냉장고 추가 바텀 시트
  Future<bool> refAddBottomSheet(String pre_docid) async {
    await showModalBottomSheet(
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return FutureBuilder(
              future: refGetDocument(),
              builder: (context, AsyncSnapshot snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: Text("로딩중..."));
                } else {
                  print("pre_docid: " + pre_docid);
                  int refCount = snapshot.data.length; // 냉장고 개수
                  double _height = 290 + 130 * (refCount - 1);
                  if (_height > MediaQuery.of(context).size.height * 0.8) {
                    _height = MediaQuery.of(context).size.height * 0.8;
                  }
                  return Container(
                      // (체크)height이 냉장고 개수에 따라 달라져야 함
                      height: _height,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.only(topLeft: Radius.circular(13.0), topRight: Radius.circular(13.0)),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12), // (체크)
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start, // 원래 "내 냉장고" 텍스트 외에는 중앙 배치인데 그냥 start로 맞춤(width로 아무튼 중앙임)
                                children: [
                                  Text("내 냉장고", style: interBold17),
                                  SizedBox(height: 12),
                                  Container(
                                      height: 1,
                                      width: MediaQuery.of(context).size.width - 32,
                                      color: Color.fromARGB(77, 34, 34, 34)),
                                  SizedBox(height: 24),
                                  // 냉장고 목록
                                  for (int i = 0; i < refCount; i++)
                                    Column(
                                      children: [
                                        // 개별 냉장고 박스
                                        GestureDetector(
                                          onTap: () async {
                                            if (snapshot.data.keys.elementAt(i) != pre_docid) {
                                              // 다른 냉장고 선택했을 때
                                              if (await editPresentRef(pre_docid, snapshot.data.keys.elementAt(i))) {
                                                navigatorKey.currentState?.pop();
                                              }
                                            } else {
                                              navigatorKey.currentState?.pop();
                                            }
                                          },
                                          child: Container(
                                              width: MediaQuery.of(context).size.width - 32,
                                              height: 114,
                                              decoration: BoxDecoration(
                                                  color: Color.fromARGB(255, 242, 242, 246),
                                                  borderRadius: BorderRadius.circular(20.0)),
                                              child: Padding(
                                                  padding: EdgeInsets.all(16.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(snapshot.data.values.elementAt(i)['ref_name'],
                                                          style: inter17),
                                                      SizedBox(height: 12),
                                                      // 식재료 이미지
                                                      Row(
                                                        children: [
                                                          Container(
                                                            height: 48,
                                                            width: 48,
                                                            decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(100),
                                                                color: Colors.white),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Container(
                                                              height: 48,
                                                              width: 48,
                                                              decoration: BoxDecoration(
                                                                  borderRadius: BorderRadius.circular(100),
                                                                  color: Colors.white))
                                                        ],
                                                      )
                                                    ],
                                                  ))),
                                        ),
                                        SizedBox(height: 16)
                                      ],
                                    ),
                                  SizedBox(height: 8),
                                  // 냉장고 추가 버튼
                                  SizedBox(
                                    height: 52,
                                    width: MediaQuery.of(context).size.width - 32,
                                    child: TextButton(
                                        onPressed: () async {
                                          //(체크) 냉장고 개수 제한이 있어야 할지 고민
                                          await navigatorKey.currentState?.pushNamed('/ref_add_page');
                                          navigatorKey.currentState?.pop();
                                        },
                                        child: Text("냉장고 추가하기", style: inter17White),
                                        style: TextButton.styleFrom(
                                            backgroundColor: colorPoint,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)))),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ));
                }
              });
        });
    return true;
  }

  Widget foodList(String docid, int refPageSelected) {
    return FutureBuilder(
        future: limit_ingredientGetDocument(docid, refPageSelected),
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
                    snapshot.data.values.elementAt(i)['expire_date'].toDate(), //(체크) 나중에 카테고리도 받아서 그거에 따라 사진 추가해야 함
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
        // (체크) 박스 터치 전체로 바꾸기
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
                    // 식재료 사진
                    Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100), color: Color.fromARGB(255, 242, 242, 246))),
                    SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dDayString,
                            style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Inter",
                                fontWeight: FontWeight.bold,
                                color: dDay < 4 ? colorRed : colorBlue)),
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
            Container(height: 0.5, width: MediaQuery.of(context).size.width * 0.9, color: colorGrey)
          ],
        ));
  }
}

// RefTap 안의 페이지
class RefDetailPage extends StatefulWidget {
  RefDetailPage({Key? key}) : super(key: key);

  @override
  State<RefDetailPage> createState() => _RefDetailPageState();
}

class _RefDetailPageState extends State<RefDetailPage> {
  // 변수들
  int refPageSelected = 1;
  String pre_docid = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: presentRefGetDocument(),
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                        height: 24,
                                        child: Text(snapshot.data.values.elementAt(0)['ref_name'], style: interBold17)),
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: IconButton(
                                          padding: EdgeInsets.all(0.0),
                                          onPressed: () async {
                                            if (await refAddBottomSheet(pre_docid)) {
                                              // 창 닫았을 때
                                              setState(() {});
                                            }
                                            // (체크)냉장고 개수에 따라 크기 바뀌어야 함
                                          },
                                          icon: Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 24,
                                            color: Color.fromARGB(130, 34, 34, 34),
                                          )),
                                    ),
                                  ],
                                ),
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
                                          padding: EdgeInsets.all(0),
                                          onPressed: () {
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
                        )),
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
                        )),
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
                        )),
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
                          color: refPageSelected == 1 ? colorPoint : colorGrey),
                      // 냉동
                      Container(
                          height: 0.5,
                          width: MediaQuery.of(context).size.width / 3,
                          color: refPageSelected == 2 ? colorPoint : colorGrey),
                      // 기타
                      Container(
                          height: 0.5,
                          width: MediaQuery.of(context).size.width / 3,
                          color: refPageSelected == 3 ? colorPoint : colorGrey),
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
                                child: Stack(
                                  children: [
                                    Align(
                                        // 식재료 소팅 버튼(bottom sheet)
                                        // (체크) 커스텀 이미지랑 같이 넣기
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                            onPressed: () async {
                                              // (체크) 순서정렬 잘 되는지 확인
                                              if (await foodSortBottomSheet()) {
                                                setState(() {});
                                              }
                                            },
                                            child: Text("전체"),
                                            style: TextButton.styleFrom(padding: EdgeInsets.zero))),
                                    Align(
                                      // 편집 버튼(식재료 삭제)
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                          child: Text("편집", style: inter14Black),
                                          onPressed: () {},
                                          style: TextButton.styleFrom(padding: EdgeInsets.zero)),
                                    )
                                  ],
                                ))),
                        // 구분선
                        Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey),
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
          onPressed: () {
            navigatorKey.currentState?.pushNamed('/food_search_page');
          },
          backgroundColor: colorPoint,
          child: Icon(Icons.add)),
    );
  }

  // 냉장고 추가 바텀 시트
  Future<bool> refAddBottomSheet(String pre_docid) async {
    await showModalBottomSheet(
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return FutureBuilder(
              future: refGetDocument(),
              builder: (context, AsyncSnapshot snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: Text("로딩중..."));
                } else {
                  print("pre_docid: " + pre_docid);
                  int refCount = snapshot.data.length; // (체크)냉장고 개수
                  return Container(
                      // (체크)height이 냉장고 개수에 따라 달라져야 함
                      // height: ,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.only(topLeft: Radius.circular(13.0), topRight: Radius.circular(13.0)),
                      ),
                      child: SingleChildScrollView(
                        // (체크) 이거 나중에 container height 맞춘 후에는 지워야 함
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 27.0, horizontal: 16.0), // 공백 상하 27 / 좌우 16
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start, // 원래 "내 냉장고" 텍스트 외에는 중앙 배치인데 그냥 start로 맞춤(width로 아무튼 중앙임)
                                children: [
                                  Text("내 냉장고", style: interBold17),
                                  SizedBox(height: 12),
                                  Container(
                                      height: 1,
                                      width: MediaQuery.of(context).size.width - 32,
                                      color: Color.fromARGB(77, 34, 34, 34)),
                                  SizedBox(height: 24),
                                  // 냉장고 목록
                                  for (int i = 0; i < refCount; i++)
                                    Column(
                                      children: [
                                        // 개별 냉장고 박스
                                        GestureDetector(
                                          onTap: () async {
                                            if (snapshot.data.keys.elementAt(i) != pre_docid) {
                                              // 다른 냉장고 선택했을 때
                                              if (await editPresentRef(pre_docid, snapshot.data.keys.elementAt(i))) {
                                                navigatorKey.currentState?.pop();
                                              }
                                            } else {
                                              navigatorKey.currentState?.pop();
                                            }
                                          },
                                          child: Container(
                                              width: MediaQuery.of(context).size.width - 32,
                                              height: 114,
                                              decoration: BoxDecoration(
                                                  color: Color.fromARGB(255, 242, 242, 246),
                                                  borderRadius: BorderRadius.circular(20.0)),
                                              child: Padding(
                                                  padding: EdgeInsets.all(16.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(snapshot.data.values.elementAt(i)['ref_name'],
                                                          style: inter17),
                                                      SizedBox(height: 12),
                                                      // 식재료 이미지
                                                      Row(
                                                        children: [
                                                          Container(
                                                            height: 48,
                                                            width: 48,
                                                            decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(100),
                                                                color: Colors.white),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Container(
                                                              height: 48,
                                                              width: 48,
                                                              decoration: BoxDecoration(
                                                                  borderRadius: BorderRadius.circular(100),
                                                                  color: Colors.white))
                                                        ],
                                                      )
                                                    ],
                                                  ))),
                                        ),
                                        SizedBox(height: 16)
                                      ],
                                    ),
                                  SizedBox(height: 8),
                                  // 냉장고 추가 버튼
                                  SizedBox(
                                    height: 52,
                                    width: MediaQuery.of(context).size.width - 32,
                                    child: TextButton(
                                        onPressed: () async {
                                          //(체크) 냉장고 개수 제한이 있어야 할지 고민
                                          await navigatorKey.currentState?.pushNamed('/ref_add_page');
                                          navigatorKey.currentState?.pop();
                                        },
                                        child: Text("냉장고 추가하기", style: inter17White),
                                        style: TextButton.styleFrom(
                                            backgroundColor: colorPoint,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)))),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ));
                }
              });
        });
    return true;
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
                              Container(height: 0.5, width: MediaQuery.of(context).size.width * 0.9, color: colorGrey),
                              SizedBox(height: 16),
                              Text("유통기한 임박순", style: inter17),
                              SizedBox(height: 16),
                              Container(height: 0.5, width: MediaQuery.of(context).size.width * 0.9, color: colorGrey),
                              SizedBox(height: 16),
                              Text("자주 사는 식재료순", style: inter17),
                              SizedBox(height: 16),
                              Container(height: 0.5, width: MediaQuery.of(context).size.width * 0.9, color: colorGrey),
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
        future: ingredientGetDocument(docid, refPageSelected),
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
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100), color: Color.fromARGB(255, 242, 242, 246))),
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
            Container(height: 0.5, width: MediaQuery.of(context).size.width * 0.9, color: colorGrey)
          ],
        ));
  }
}

// 식단 탭
class MealTap extends StatefulWidget {
  @override
  State<MealTap> createState() => _MealTapState();
}

class _MealTapState extends State<MealTap> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Container());
  }
}

// 마이페이지 탭
class MyTap extends StatefulWidget {
  @override
  State<MyTap> createState() => _MyTapState();
}

class _MyTapState extends State<MyTap> {
  final viewModel = LoginViewModel(KakaoLogin());
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Center(
      // 로그아웃 버튼
      child: ElevatedButton(
          onPressed: () async {
            print("my uid is " + FirebaseAuth.instance.currentUser!.uid);
            await viewModel.logout();
            setState(() {});
            navigatorKey.currentState?.pushNamedAndRemoveUntil('/login_page', (route) => false);
          },
          child: Text("Logout")),
    ));
  }
}
