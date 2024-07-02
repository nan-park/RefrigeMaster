import 'dart:collection';

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' as intl;

import 'package:refrige_master/backside/app_design_comp.dart';
import 'package:refrige_master/ref_detail_page.dart';
import 'recipe_recommend_page.dart';
import 'main.dart';
import 'backside/login_view_model.dart';
import 'backside/kakao_login.dart';
import 'recipe_detail_page.dart';

// (중요 체크) 현재 홈화면 탭 누르면 초기화되도록 만들기(홈화면일때도 스크롤돼있으면 초기화). 홈화면 상태에서 뒤로가기 못하게 만들기(willpopscope)
// 전역 변수
int _currentIndex = 0;

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

// 함수들 ------------------------

// 현재 냉장고 하나만 가져오기
Future<Map?> refGetDocument() async {
  Map<String, Map<String, dynamic>?> map = {}; // {docid : [Map]}

  // final snapshot = await FirebaseFirestore.instance
  //     .collection("Refrigerators")
  //     .where('present_member', arrayContains: FirebaseAuth.instance.currentUser?.uid)
  //     .get() as DocumentSnapshot;
  final snapshot = await FirebaseFirestore.instance
      .collection("Refrigerators")
      .where('member', arrayContains: FirebaseAuth.instance.currentUser!.uid)
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
  // 유통기한 임박순(expire_date)
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection("Refrigerators/" + docid + "/Ingredients")
      .where('location', isEqualTo: location)
      .orderBy('expire_date', descending: false)
      .limit(6)
      .get();
  snapshot.docs.forEach((element) {
    // (체크) 사실 여기서 바로 docs.data 가져와서 한 번에 할 수 있는데 굉장한 손해.. 나중에 수정하자.
    lists.add(element.id);
  });

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

// 랜덤으로 3개의 추천 식단을 갖고 와서 보여주기. 나중에는 제대로 알고리즘 짜서 유통기한 임박 식재료도 같이 보여줘야 함.
Future<Map> limit_getRecommendRecipeDocument() async {
  // List lists = await limit_ingredientGetDocumentList(); //
  Map map = {}; // {docid : [Map]}

  QuerySnapshot snapshot = await FirebaseFirestore.instance.collection("RecipeTemplates").limit(3).get();
  snapshot.docs.forEach((element) {
    map[element.id] = element.data();
  });
  return map;
}

Future<Map> getTodayMenu(DateTime selectedDate) async {
  Map map = {};
  final snapshot = await FirebaseFirestore.instance
      .collection("Users/" +
          FirebaseAuth.instance.currentUser!.uid +
          "/Calendar/" +
          intl.DateFormat('yyyy.MM.dd').format(selectedDate) +
          "/MealPlans")
      .orderBy('sequence', descending: false) // 순서 0, 1, 2... 순서대로
      .get(); // (체크) 여기에서 length 불러올 수 없다는 오류 뜨는데 일단 넘어가고 나중에 고치기.

  snapshot.docs.forEach((element) {
    map[element.id] = element.data();
  });

  return map;
}

Future<Map> getUserInfo() async {
  Map map = {};
  final snapshot =
      await FirebaseFirestore.instance.collection("Users").doc(FirebaseAuth.instance.currentUser!.uid).get();
  map[FirebaseAuth.instance.currentUser!.uid] = snapshot.data();
  return map;
}

// Page Tap -----------------------

class _HomePageState extends State<HomePage> {
  final _navigatorKeyList = List.generate(3, (index) => GlobalKey<NavigatorState>());
  // 바텀 내비게이션 변수
  final _children = [RefTap(), DietTap(), MyTap()];
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
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
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
                items: [
                  BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      "src/ref_icon.svg",
                      color: _currentIndex == 0 ? colorPoint : Color.fromARGB(127, 34, 34, 34),
                    ),
                    label: ('냉장고'),
                  ),
                  BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      "src/calendar_icon.svg",
                      color: _currentIndex == 1 ? colorPoint : Color.fromARGB(127, 34, 34, 34),
                    ),
                    label: ('식단기록'),
                  ),
                  BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      "src/my_icon.svg",
                      color: _currentIndex == 2 ? colorPoint : Color.fromARGB(127, 34, 34, 34),
                    ),
                    label: ('마이페이지'),
                  ),
                ],
              ),
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

// 냉장고 관리 탭
class RefTap extends StatefulWidget {
  @override
  State<RefTap> createState() => _RefTapState();
}

class _RefTapState extends State<RefTap> {
  //변수
  int refPageSelected = 1; // 홈화면 변수(냉장/냉동/기타)
  String pre_docid = ""; // present_document_id
  int _index = 0;
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'src/logo.png',
                        width: 100,
                        height: 20,
                      ),
                    ),
                    // 알림 버튼
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: IconButton(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
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
            // 구분선
            Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
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
                      SizedBox(width: 16),
                      Text("오늘의 메뉴", style: TextStyle(fontFamily: "Inter", fontSize: 24, fontWeight: FontWeight.bold)),
                      Expanded(child: Container()),
                      SizedBox(
                          width: 16,
                          child: IconButton(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              padding: EdgeInsets.all(0),
                              onPressed: () {},
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: colorGrey3,
                              ))),
                      SizedBox(width: 20),
                    ],
                  ),
                  SizedBox(height: 16),
                  // (체크) 스와이프 카드(오늘의 메뉴) (or gesture detector)
                  menuSwipeCard(),
                ],
              ),
            ),
            FutureBuilder(
                future: refGetDocument(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error"));
                  }
                  if (!snapshot.hasData) {
                    //(체크) 이걸 생성된 냉장고가 없는 상태로 무조건 판단할 수 있을까? 예외가 있나?
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
                                refGetDocument();
                              });
                            },
                            child: Text("냉장고 추가하기", style: inter17White),
                            style: TextButton.styleFrom(
                                splashFactory: NoSplash.splashFactory,
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
                                          onTap: () async {
                                            await Navigator.of(context)
                                                .push(MaterialPageRoute(builder: (context) => RefDetailPage()));
                                            setState(() {});
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
                                      splashFactory: NoSplash.splashFactory,
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
                                      splashFactory: NoSplash.splashFactory,
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
                                      splashFactory: NoSplash.splashFactory,
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
          heroTag: 'refTap',
          onPressed: () {
            navigatorKey.currentState?.pushNamed('/food_search_page');
          },
          backgroundColor: colorPoint,
          child: Icon(Icons.add)),
    );
  }

  Widget menuSwipeCard() {
    int count;
    return FutureBuilder(
        future: getTodayMenu(DateTime.now()),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error"));
          } else if (snapshot.hasData) {
            count = snapshot.data.length ?? 0;
            if (count == 0) {
              return Center(child: Text("데이터 없음"));
            } else {
              return Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 136,
                    child: PageView.builder(
                        controller: PageController(initialPage: 0),
                        itemCount: count,
                        onPageChanged: (int index) => setState(() => _index = index),
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Container(
                                decoration: BoxDecoration(
                                    color: colorBlue, borderRadius: BorderRadius.all(Radius.circular(20))),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    // 내용
                                    children: [
                                      // 요리 프로필 사진
                                      Container(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Center(
                                              child: Image.asset(
                                                'src/meal_meat_spaghetti.png',
                                                width: 80,
                                                height: 80,
                                              ),
                                            ),
                                          ),
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(Radius.circular(20)))),
                                      SizedBox(width: 16),
                                      // 요리 정보 영역
                                      Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.restaurant_menu, color: Colors.white, size: 18),
                                                SizedBox(width: 4),
                                                Text(
                                                    "식사 " +
                                                        (snapshot.data.values.elementAt(_index)['sequence'] + 1)
                                                            .toString(),
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontFamily: "Inter",
                                                        height: 1,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold)), // (체크) SemiBold
                                              ],
                                            ),
                                            Text(snapshot.data.values.elementAt(_index)['name'],
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    fontFamily: "Inter",
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)),
                                          ])
                                    ],
                                  ),
                                )),
                          );
                        }),
                  ),
                  SizedBox(height: 10),
                  // 스와이프 순서
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < count; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: i == _index ? colorBlue : Color.fromARGB(76, 0, 122, 255), // colorBlue 투명도 30%
                              )),
                        )
                    ],
                  )
                ],
              );
            }
          } else {
            return Container();
          }
        });
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
                    // 식재료 사진  // (체크) 나중에 카테고리 따라 사진 넣기.
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
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: colorBackground)),
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
            Container(height: 0.5, width: MediaQuery.of(context).size.width * 0.9, color: colorGrey1)
          ],
        ));
  }
}

// 식단 탭
class DietTap extends StatefulWidget {
  @override
  State<DietTap> createState() => _DietTapState();
}

class _DietTapState extends State<DietTap> {
  bool executed = false;
  late DateTime _selectedCalendarDate;
  late DateTime _focusedCalendarDate;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  @override
  Widget build(BuildContext context) {
    // 빌드 이후 변수
    double widthPadding = MediaQuery.of(context).size.width - 32.0; //가로 패딩(양옆 16)
    double dateWidth = (MediaQuery.of(context).size.width - 32) / 7;
    if (!executed) {
      // 한 번만 실행
      initializeDateFormatting(Localizations.localeOf(context).languageCode); // DeateFormat 초기화
      _focusedCalendarDate = DateTime.now();
      _selectedCalendarDate = _focusedCalendarDate;
      executed = true;
    }

    // 몇째 주인지 알아내기(weekNumOfMonth) <= _selectedCalendarDate
    DateTime firstDayOfMonth = DateTime(_selectedCalendarDate.year, _selectedCalendarDate.month, 1);
    int firstMonday = 1 + (7 - (firstDayOfMonth.weekday - DateTime.monday)) % 7;
    print(firstMonday);
    int difference = _selectedCalendarDate.day - firstMonday;
    int weekNumOfMonth;
    if (difference < 0) {
      weekNumOfMonth = 1;
    } else {
      weekNumOfMonth = difference ~/ 7 + 2;
    }
    if (firstMonday == 1) {
      weekNumOfMonth -= 1;
    }
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 239, 241, 245), // 배경색
      // floatingActionButton: FloatingActionButton(
      //     heroTag: 'dietTap',
      //     onPressed: () {},
      //     backgroundColor: colorPoint,
      //     child: Icon(Icons.add)), // (체크) 누르면 focus 되고 추천 레시피 보기/레시피 직접 작성 버튼 나옴.
      body: SingleChildScrollView(
        child: Column(
          // 전체 영역
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //appBar 상단바
            Container(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    // 로고
                    Image.asset(
                      'src/logo.png',
                      width: 100,
                      height: 20,
                    ),
                    Expanded(child: Container()),
                    // 보관함 버튼
                    SizedBox(
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
                              color: colorPoint, width: 0.5), // (체크) figma 줄 두께는 0.5인데 에뮬레이터로 보면 너무 얇아 보임. 실제 기기에서 확인하기
                          splashFactory: NoSplash.splashFactory,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              color: Color.fromARGB(245, 255, 255, 255),
              height: 50,
            ),
            // 구분선
            Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
            SizedBox(height: 16),
            // 주차 선택(월별/주별 보기) 영역 // (체크) 이거는 inkWell로 하는 게 더 예쁘지 않을까? 전체적 splash에 관해서 나중에 디자이너와 토의해보기
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(_focusedCalendarDate.month.toString() + "월 " + weekNumOfMonth.toString() + "주차",
                      style: interBold24),
                  Expanded(child: Container()),
                  // 저번주 버튼
                  SizedBox(
                      height: 24,
                      width: 24,
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.keyboard_arrow_left, size: 24, color: colorGrey3),
                        onPressed: () {
                          if (_calendarFormat == CalendarFormat.week) {
                            // 주별 보기
                            _focusedCalendarDate = _focusedCalendarDate.add(Duration(days: -7));
                            _selectedCalendarDate = _focusedCalendarDate;
                          } else {
                            // 월별 보기
                            _focusedCalendarDate =
                                DateTime(_focusedCalendarDate.year, _focusedCalendarDate.month - 1, 1);
                            _selectedCalendarDate = _focusedCalendarDate;
                          }
                          setState(() {});
                        },
                      )),
                  // 다음주 버튼
                  SizedBox(
                      height: 24,
                      width: 24,
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.keyboard_arrow_right, size: 24, color: colorGrey3),
                        onPressed: () {
                          if (_calendarFormat == CalendarFormat.week) {
                            // 주별 보기
                            _focusedCalendarDate = _focusedCalendarDate.add(Duration(days: 7));
                            _selectedCalendarDate = _focusedCalendarDate;
                          } else {
                            // 월별 보기
                            _focusedCalendarDate =
                                DateTime(_focusedCalendarDate.year, _focusedCalendarDate.month + 1, 1);
                            _selectedCalendarDate = _focusedCalendarDate;
                          }
                          setState(() {});
                        },
                      )),
                  SizedBox(width: 16),
                  // 주별보기/월별보기 버튼
                  SizedBox(
                    width: 48,
                    height: 28,
                    child: TextButton(
                      onPressed: () {
                        if (_calendarFormat == CalendarFormat.week) {
                          _calendarFormat = CalendarFormat.month;
                        } else {
                          _calendarFormat = CalendarFormat.week;
                        }
                        setState(() {});
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(_calendarFormat == CalendarFormat.week ? "주" : "월",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: "Inter",
                                  color: colorGrey3,
                                  height: 1,
                                  leadingDistribution: TextLeadingDistribution.even)),
                          SizedBox(width: 4),
                          Transform.rotate(
                              angle: 90 * math.pi / 180,
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: colorGrey3,
                              )),
                        ],
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.fromLTRB(10, 6, 10, 6),
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // 날짜 선택 영역
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //   child: Container(height: 70, color: Colors.white),
            // ),
            TableCalendar(
              locale: 'ko-KR',
              firstDay: DateTime.utc(2020, 01, 01),
              lastDay: DateTime.utc(2050, 12, 31),
              focusedDay: _focusedCalendarDate,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerVisible: false,
              calendarFormat: _calendarFormat,
              // 요일
              daysOfWeekHeight: 18,
              rowHeight: 55, // (체크) 나중에 조정
              daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontSize: 13, fontFamily: "Inter", color: colorGrey2, height: 1.5),
                  weekendStyle: TextStyle(fontSize: 13, fontFamily: "Inter", color: colorGrey2, height: 1.5)),
              // 날짜
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                // isTodayHighlighted: false,
                defaultTextStyle: TextStyle(fontSize: 16, fontFamily: "Inter", color: colorBlue, height: 1.5),
                weekendTextStyle: TextStyle(fontSize: 16, fontFamily: "Inter", color: colorBlue, height: 1.5),
                selectedDecoration: BoxDecoration(shape: BoxShape.circle, color: colorBlue), // (체크) 임시
                selectedTextStyle:
                    TextStyle(fontSize: 16, fontFamily: "Inter", color: Colors.white, height: 1.5), // (체크) 임시
                todayDecoration:
                    BoxDecoration(shape: BoxShape.circle, color: Color.fromARGB(25, 0, 122, 255)), // (체크) 임시
                todayTextStyle: TextStyle(fontSize: 16, fontFamily: "Inter", color: colorBlue, height: 1.5), // (체크) 임시
              ),
              // function
              selectedDayPredicate: (currentSelectedDate) {
                return (isSameDay(_selectedCalendarDate, currentSelectedDate));
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedCalendarDate, selectedDay)) {
                  setState(() {
                    _selectedCalendarDate = selectedDay;
                    _focusedCalendarDate = focusedDay;
                  });
                }
              },
              // cellBuilder
              calendarBuilders: _calendarBuilder(),
              // // events
              // eventLoader: (day) {
              //   return _getEventsForDay(day);
              // },
            ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //   child: Row(
            //     children: [
            //       Container(width: dateWidth * (_focusedCalendarDate.weekday - DateTime.monday)),
            //       Container(width: dateWidth, height: 3, color: colorBlue),
            //     ],
            //   ),
            // ),
            SizedBox(height: 16),
            _calendarFormat == CalendarFormat.week
                ?
                // 주별 보기인 경우 ----------
                Column(
                    children: [
                      FutureBuilder(
                          future: getTodayMenu(_selectedCalendarDate),
                          builder: (context, AsyncSnapshot snapshot) {
                            if (snapshot.hasError) {
                              return Container(child: Text("Error"));
                            } else if (snapshot.hasData) {
                              if (snapshot.data.isEmpty) {
                                // 메뉴 없을 때
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Container(
                                      height: 112,
                                      width: widthPadding,
                                      decoration: BoxDecoration(
                                          border: Border.all(color: colorGrey1),
                                          borderRadius: BorderRadius.all(Radius.circular(13.0))),
                                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Text("오늘의 식단이 없습니다.", style: inter17Grey3),
                                        Text("여기를 눌러 추가하세요", style: inter17Blue)
                                      ])),
                                );
                              } else {
                                // 메뉴 존재할 때
                                return menuList(snapshot.data);
                              }
                            } else {
                              return Container();
                            }
                          }),
                      SizedBox(height: 24),
                      // 추천 식단 영역
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 제목
                            Text("추천 식단", style: interBold24),
                            Expanded(child: Container()),
                            // 더보기 버튼
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
                                  onTap: () async {
                                    await Navigator.of(context)
                                        .push(MaterialPageRoute(builder: (context) => DietRecommendPage()));
                                    setState(() {});
                                  },
                                )),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // 추천 식단 박스
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: recommendRecipeList(3),
                      ),
                    ],
                  )
                :
                // 월별 보기인 경우 ----------  // (체크) 그 month의 1~5주차 요약 보여줌
                Column(
                    children: [],
                  ),
          ],
        ),
      ),
    );
  }

  // 캘린더 커스텀 builder
  CalendarBuilders _calendarBuilder() {
    return CalendarBuilders();
  }

  // List<dynamic> _getEventsForDay(DateTime day) {
  //   return events[day] ?? [];
  // }

  // Map<DateTime, List> events = {};
  // Map<DateTime, List<Map>> events = {
  //   // 예시
  //   DateTime.now(): [
  //     {'completed': false, 'name': "미트 스파게티"}
  //   ]
  // };
  // final events = LinkedHashMap(equals: isSameDay,)

  Widget recommendRecipeList(int count) {
    // (체크) 일단 임시로 모든 레시피 리스트 중 3개만 가져오는 걸로. 나중에 랜덤 알고리즘 짜기
    return FutureBuilder(
        future: limit_getRecommendRecipeDocument(),
        builder: (context, AsyncSnapshot snapshot) {
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
        });
  }

  // 식단 박스  (체크) 오늘의 메뉴와 다름. 유통기한 임박 식재료까지 보여줘야 함. 나중에 구분해주기.
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
                        diet_expireDateItemBox(),
                        const SizedBox(width: 12),
                        diet_expireDateItemBox()
                      ], // (체크) 나중엔 개수를 변수로 하여 itemList 위젯 만들기
                    )
                  ],
                )
              ],
            ),
          )),
    );
  }

  Widget diet_expireDateItemBox() {
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

  Widget menuList(Map map) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            for (int i = 0; i < map.length; i++)
              Column(
                children: [
                  menuBox(
                      map.keys.elementAt(i),
                      map.values.elementAt(i)['name'],
                      map.values.elementAt(i)['sequence'],
                      map.values.elementAt(i)['completed'],
                      map.values.elementAt(i)['recipe_uid'],
                      map.values.elementAt(i)['num_of_plates'],
                      _selectedCalendarDate),
                  SizedBox(height: 16)
                ],
              )
          ],
        ));
  }

  // 오늘의 메뉴 박스
  Widget menuBox(String docid, String name, int sequence, bool completed, String recipeUid, int numOfPlates,
      DateTime menuDateTime) {
    // 여기서 docid는 menu 자동 uid
    Color completeColor;
    if (completed) {
      completeColor = colorBlue;
    } else {
      completeColor = colorGrey3;
    }
    return GestureDetector(
      onTap: () async {
        if (completed) {
          // 이미 완료된 거면 일반 레시피로 취급
          await navigatorKey.currentState
              ?.pushNamed('/recipe_detail_page', arguments: {'recipe_uid': recipeUid, 'name': name});
          setState(() {});
        } else {
          // 미완료 상태면 '완료하기' 버튼 있는 메뉴 페이지로 이동
          await navigatorKey.currentState?.pushNamed('/menu_detail_page', arguments: {
            'docid': docid,
            'recipe_uid': recipeUid,
            'name': name,
            'num_of_plates': numOfPlates,
            'menuDateTime': menuDateTime
          });
          setState(() {});
        }
      },
      // (체크) onTap => menu_detail_page 들어가서 완료버튼 있는 버전 볼 수 있음. 이미 완료된 거면 recipe_detail_page로 들어가기.
      child: Container(
          width: MediaQuery.of(context).size.width - 32.0,
          height: 112,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            // 전체 박스
            children: [
              // 완료 표시 영역
              Container(
                  width: 23,
                  decoration: BoxDecoration(
                    color: completeColor,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                  ),
                  child: completed
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Text("완", style: inter12White), Text("료", style: inter12White)],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("미", style: inter12White),
                            Text("완", style: inter12White),
                            Text("료", style: inter12White),
                          ],
                        )),
              // 메뉴 정보 영역
              Expanded(
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              //(체크) 캘린더 날짜마다 다른 식단 있으면 그 박스도 보여주고 식사 2로 순서 바뀌어야 함.
                              Icon(Icons.restaurant_menu, color: completed ? colorBlue : colorGrey3, size: 18),
                              SizedBox(width: 4),
                              Text("식사 " + (sequence + 1).toString(),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: "Inter",
                                      height: 1,
                                      color: completed ? colorBlue : colorGrey3,
                                      fontWeight: FontWeight.bold)) // (체크) SemiBold
                            ],
                          ),
                          // 메뉴 이름
                          Text(name, style: interBold17), // (체크) SemiBold
                        ],
                      )
                    ],
                  ),
                ),
              ),
              // 메뉴 설정 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          if (await menuBottomSheet()) {
                            // (체크) 아직 기능은 하나도 넣지 않았음.
                            // 창 닫았을 때
                            setState(() {});
                          }
                        },
                        icon: Icon(Icons.more_vert, size: 24, color: colorGrey3))),
              ),
            ],
          )),
    );
  }

// 메뉴 바텀 시트
  Future<bool> menuBottomSheet() async {
    await showModalBottomSheet(
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: SizedBox(
              height: 260,
              child: Column(
                children: [
                  Container(
                      height: 182,
                      width: MediaQuery.of(context).size.width - 32,
                      margin: EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                      child: Column(
                        children: [
                          // 완료 버튼
                          SizedBox(
                            height: 60,
                            width: MediaQuery.of(context).size.width - 32,
                            child: TextButton(
                                onPressed: () {}, // (체크) 아직 안 됨. 데이터 가져와서 해야 함.. 나중에 하기.
                                child: Text("완료 표시", style: inter17Blue),
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    splashFactory: NoSplash.splashFactory,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(13), topRight: Radius.circular(13))))),
                          ),
                          Container(height: 0.8, width: MediaQuery.of(context).size.width - 32, color: colorGrey1),
                          SizedBox(
                            height: 60,
                            width: MediaQuery.of(context).size.width - 32,
                            child: TextButton(
                                onPressed: () {},
                                child: Text("삭제", style: inter17Blue),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  splashFactory: NoSplash.splashFactory,
                                  backgroundColor: Colors.white,
                                )),
                          ),
                          Container(height: 0.8, width: MediaQuery.of(context).size.width - 32, color: colorGrey1),
                          SizedBox(
                            height: 60,
                            width: MediaQuery.of(context).size.width - 32,
                            child: TextButton(
                                onPressed: () {},
                                child: Text("순서 변경", style: inter17Blue),
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    splashFactory: NoSplash.splashFactory,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(13), bottomRight: Radius.circular(13))))),
                          ),
                        ],
                      )),
                  SizedBox(height: 8),
                  Container(
                      height: 60,
                      width: MediaQuery.of(context).size.width - 32,
                      margin: EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                      child: SizedBox(
                          height: 60,
                          width: MediaQuery.of(context).size.width - 32,
                          child: TextButton(
                              onPressed: () {
                                navigatorKey.currentState?.pop();
                              },
                              child: Text("취소",
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontFamily: "Inter",
                                      color: colorBlue,
                                      fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  splashFactory: NoSplash.splashFactory,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)))))),
                  SizedBox(height: 10),
                ],
              ),
            ),
          );
        });
    return true;
  }
}

// 마이페이지 탭
class MyTap extends StatefulWidget {
  @override
  State<MyTap> createState() => _MyTapState();
}

class _MyTapState extends State<MyTap> {
  final viewModel = LoginViewModel(KakaoLogin());
  List info = ['이용약관', "개인정보보호정책", "고객지원", "버전정보"];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: Column(children: [
        //appBar 상단바
        Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // (체크)(중요) 전체적인 상단바 padding 수정하기
                  child: Stack(
                    children: [
                      // 제목
                      Align(
                          alignment: Alignment.center,
                          child: Container(
                              height: 24, child: Text("마이페이지", style: interBold17))), // (체크) fontweight Semi bold
                    ],
                  )),
            ],
          ),
          color: Color.fromARGB(245, 255, 255, 255),
          height: 50, // (체크) 원래 44인데 좀 늘림. 나중에 실제 앱에서 확인해보기
        ),
        // 상단바 이외의 영역 ---
        // 유저 정보
        FutureBuilder(
            future: getUserInfo(), // 닉네임과 이메일, 알림설정여부 가져오기.
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error"));
              } else if (snapshot.hasData) {
                return Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                            height: 96,
                            width: MediaQuery.of(context).size.width - 32,
                            child: Row(
                              children: [
                                // 프로필 사진
                                Container(
                                  decoration:
                                      BoxDecoration(borderRadius: BorderRadius.circular(100), color: colorBackground),
                                  width: 64,
                                  height: 64,
                                ),
                                SizedBox(width: 16),
                                // 사용자 정보(닉네임/이메일)
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(snapshot.data.values.elementAt(0)['nickname'],
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: "Inter",
                                              fontWeight: FontWeight.bold,
                                              color: colorBlue,
                                              height: 1)),
                                      SizedBox(height: 8),
                                      Text(snapshot.data.values.elementAt(0)['email'],
                                          style: TextStyle(
                                              fontSize: 14, fontFamily: "Inter", color: colorBlack, height: 1))
                                    ],
                                  ),
                                ),
                                // 유저 정보 보기 버튼
                                SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: IconButton(
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        onPressed: () async {
                                          await navigatorKey.currentState?.pushNamed('/profile_manage_page');
                                          setState(() {});
                                        }, // 프로필 관리 페이지로 이동
                                        icon: Icon(Icons.arrow_forward_ios, size: 24, color: colorGrey3))),
                              ],
                            )),
                      ),
                    ),
                    // 구분선
                    Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
                    SizedBox(height: 8),
                    // 알림 설정 버튼 영역
                    Container(
                        height: 67,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            children: [
                              Text("알림 설정", style: inter16),
                              Expanded(child: Container()),
                              //switch 버튼 들어가야 함. (체크) 일단 사진으로 대체..
                            ],
                          ),
                        ))
                  ],
                );
              } else {
                return Container();
              }
            }),
        // 이외의 버튼 영역
        for (int i = 0; i < info.length; i++)
          Column(
            children: [
              // 구분선
              Container(
                  height: 1,
                  width: MediaQuery.of(context).size.width * 0.9,
                  color: colorGrey1), // (체크) width 0.5로 하면 하나씩 안보여서 일단 1로 변경.
              Container(
                  height: 67,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [Text(info[i], style: inter16)],
                    ),
                  )),
            ],
          ),
        SizedBox(height: 8),
        // 로그아웃 버튼
        Container(
          height: 67,
          width: MediaQuery.of(context).size.width,
          color: Colors.white,
          child: TextButton(
            onPressed: () async {
              print("my uid is " + FirebaseAuth.instance.currentUser!.uid);
              await viewModel.logout();
              setState(() {});
              navigatorKey.currentState?.pushNamedAndRemoveUntil('/login_page', (route) => false);
            },
            style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
            child: Container(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("로그아웃", style: TextStyle(fontSize: 16, fontFamily: "Inter", height: 1.29, color: colorGrey3)),
                ],
              ),
            )),
          ),
        ),
        // ElevatedButton(
        //     onPressed: () async {
        //       print("my uid is " + FirebaseAuth.instance.currentUser!.uid);
        //       await viewModel.logout();
        //       setState(() {});
        //       navigatorKey.currentState?.pushNamedAndRemoveUntil('/login_page', (route) => false);
        //     },
        //     child: Text("Logout")),
        Expanded(
          child: Container(color: Colors.white),
        )
      ]),
    );
  }
}
