import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:refrige_master/backside/app_design_comp.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' as intl;

import 'main.dart';

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

// 해당 날짜에 (고정)레시피 추가하기. 이미 들어있으면 뒷순서로 넣기
Future<bool> writeDietCalendar(String recipe_uid, String name, DateTime selectedDate) async {
  final snapshot = await FirebaseFirestore.instance
      .collection("Users/" +
          FirebaseAuth.instance.currentUser!.uid +
          "/Calendar/" +
          intl.DateFormat('yyyy.MM.dd').format(selectedDate) +
          "/MealPlans")
      .get();

  int nextSequence = snapshot.docs.length; // 순서
  await FirebaseFirestore.instance
      .collection("Users/" +
          FirebaseAuth.instance.currentUser!.uid +
          "/Calendar/" +
          intl.DateFormat('yyyy.MM.dd').format(selectedDate) +
          "/MealPlans")
      .add({
    'completed': false,
    'name': name,
    'num_of_plates': 1,
    'provided': true, // (체크) 나중에 직접 추가 생기면 따로 설정 필요
    'recipe_uid': recipe_uid,
    'sequence': nextSequence
  });
  await FirebaseFirestore.instance
      .collection("Users/" + FirebaseAuth.instance.currentUser!.uid + "/Calendar")
      .doc(intl.DateFormat('yyyy.MM.dd').format(selectedDate))
      .set({'default': true}); // 문서 필드 하나라도 넣으려고..

  return true;
}

class CalendarAddPage extends StatefulWidget {
  CalendarAddPage({Key? key}) : super(key: key);

  @override
  State<CalendarAddPage> createState() => _CalendarAddPageState();
}

class _CalendarAddPageState extends State<CalendarAddPage> {
  bool executed = false;
  late DateTime _selectedCalendarDate;
  late DateTime _focusedCalendarDate;
  int nextSequence = 0;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map; // 레시피 고정 recipe_uid, 레시피 이름 name
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          backgroundColor: colorBackground,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          // 플로팅 버튼(이 날짜에 추가하기)
          floatingActionButton: SafeArea(
            child: SizedBox(
              height: 52,
              width: MediaQuery.of(context).size.width - 32,
              child: FloatingActionButton.extended(
                  heroTag: 'calendarAdd',
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13.0)),
                  onPressed: () async {
                    // (체크) 누르면 해당 날짜에 순서 마지막으로 식단 추가되고 홈페이지로 가기. (체크) 홈페이지로 갔을 때 자동으로 setState 되는지 확인하기.
                    if (await writeDietCalendar(args['recipe_uid'], args['name'], _selectedCalendarDate)) {
                      navigatorKey.currentState?.pushNamedAndRemoveUntil('/home_page', (route) => false);
                    }
                  },
                  backgroundColor: colorBlue,
                  label: Text("이 날짜에 추가하기",
                      style: TextStyle(
                          fontSize: 17, fontFamily: "Inter", color: Colors.white, fontWeight: FontWeight.bold))),
            ),
          ), // (체크) SemiBold
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
                                      child: Text("날짜 선택", style: interBold17))), // (체크) fontweight Semi bold
                            ],
                          )),
                    ],
                  ),
                  color: Color.fromARGB(245, 255, 255, 255),
                  height: 50, // (체크) 원래 44인데 좀 늘림. 나중에 실제 앱에서 확인해보기
                ),
                // 구분선
                Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
                // 상단바 이외 영역 ----
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
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
                                      Text("주",
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontFamily: "Inter",
                                              color: Color.fromARGB(255, 127, 127, 127),
                                              height: 1)),
                                      SizedBox(width: 4),
                                      Transform.rotate(
                                          angle: 90 * math.pi / 180,
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            size: 12,
                                            color: Color.fromARGB(255, 137, 137, 137),
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
                              weekdayStyle:
                                  TextStyle(fontSize: 13, fontFamily: "Inter", color: colorGrey2, height: 1.5),
                              weekendStyle:
                                  TextStyle(fontSize: 13, fontFamily: "Inter", color: colorGrey2, height: 1.5)),
                          // 날짜
                          calendarStyle: const CalendarStyle(
                            outsideDaysVisible: false,
                            isTodayHighlighted: true,
                            defaultTextStyle:
                                TextStyle(fontSize: 16, fontFamily: "Inter", color: colorBlue, height: 1.5),
                            weekendTextStyle:
                                TextStyle(fontSize: 16, fontFamily: "Inter", color: colorBlue, height: 1.5),
                            selectedDecoration: BoxDecoration(shape: BoxShape.circle, color: colorBlue), // (체크) 임시
                            selectedTextStyle: TextStyle(
                                fontSize: 16, fontFamily: "Inter", color: Colors.white, height: 1.5), // (체크) 임시
                            todayDecoration: BoxDecoration(
                                shape: BoxShape.circle, color: Color.fromARGB(25, 0, 122, 255)), // (체크) 임시
                            todayTextStyle:
                                TextStyle(fontSize: 16, fontFamily: "Inter", color: colorBlue, height: 1.5), // (체크) 임시
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
                        ),
                        FutureBuilder(
                            future: getTodayMenu(_selectedCalendarDate),
                            builder: (context, AsyncSnapshot snapshot) {
                              if (snapshot.hasError) {
                                return Container(child: Text("Error"));
                              } else if (snapshot.hasData) {
                                if (snapshot.data.isEmpty) {
                                  // 메뉴 없을 때
                                  return Column(
                                    children: [
                                      Container(),
                                      recipeBox(args['recipe_uid'], args['name'], 0),
                                    ],
                                  );
                                } else {
                                  // 메뉴 존재할 때
                                  nextSequence = snapshot.data.length;
                                  return Column(
                                    children: [
                                      menuList(snapshot.data),
                                      recipeBox(args['recipe_uid'], args['name'], nextSequence),
                                      SizedBox(height: 80),
                                    ],
                                  );
                                }
                              } else {
                                return Container();
                              }
                            }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
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
                    false,
                  ),
                  SizedBox(height: 16)
                ],
              ),
          ],
        ));
  }

  // 오늘의 메뉴 박스
  Widget menuBox(String recipe_uid, String name, int sequence, bool completed) {
    Color completeColor;
    if (completed) {
      completeColor = colorBlue;
    } else {
      completeColor = colorGrey3;
    }
    return GestureDetector(
      // (체크) onTap => menu_detail_page 들어가서 완료버튼 있는 버전 볼 수 있음. 이미 완료된 거면 recipe_detail_page로 들어가기.
      child: Container(
          width: MediaQuery.of(context).size.width - 32.0,
          height: 112,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
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
          )),
    );
  }

  // 레시피 박스  (유통기한 식재료 없는 버전)
  Widget recipeBox(String recipe_uid, String name, int nextSequence) {
    return GestureDetector(
      // 여기는 onTap 필요 없음
      child: Container(
          width: MediaQuery.of(context).size.width - 32.0,
          height: 112,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: colorBlue, width: 1.0)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        Icon(Icons.restaurant_menu, color: colorBlue, size: 18),
                        SizedBox(width: 4),
                        Text("식사 " + (nextSequence + 1).toString(),
                            style: TextStyle(
                                fontSize: 12,
                                fontFamily: "Inter",
                                height: 1,
                                color: colorBlue,
                                fontWeight: FontWeight.bold)) // (체크) SemiBold
                      ],
                    ),
                    // 메뉴 이름
                    Text(name, style: interBold17), // (체크) SemiBold
                  ],
                )
              ],
            ),
          )),
    );
  }
}
