import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:refrige_master/backside/app_design_comp.dart';
import 'package:refrige_master/food_search_page.dart';
import 'main.dart';

class FoodAddPage extends StatefulWidget {
  FoodAddPage({Key? key}) : super(key: key);

  @override
  State<FoodAddPage> createState() => _FoodAddPageState();
}

// 전역 변수
List<Map<String, dynamic>> setting = [];

class _FoodAddPageState extends State<FoodAddPage> {
  @override
  Widget build(BuildContext context) {
    // 변수들(빌드 이후)
    final args = ModalRoute.of(context)!.settings.arguments as Map; //item_selected
    List item_selected = args['item_selected'];
    DateTime? date_time;
    List temp = [];
    for (int i = 0; i < item_selected.length; i++) {
      temp = item_selected[i].split("/");
      // 직접추가면 ["식재료이름", ""]
      if (temp[1] == "") {
        temp[1] = "기타";
      }
      setting.add({
        'name': temp[0],
        'category': temp[1],
        'location': "냉장",
        'expire_date': date_time,
        'amount': 0.0,
        'half': false
      });
      //  [{name: 사과, category: 과일, location: 냉장, expire_date: null(TimeStamp), amount: 0, half: false}]
    }
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        // 캘린더 한국어로 바꾸기
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        supportedLocales: const [Locale('ko', 'KR')],
        home: SafeArea(
          child: Scaffold(
              body: Column(
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
                                    child: Text("품목설정", style: interBold17))), // (체크) fontweight Semibold로 바꾸기
                          ],
                        )),
                  ],
                ),
                color: Color.fromARGB(245, 255, 255, 255),
                height: 55,
              ),
              // 구분선
              Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey),
              // 식재료 세팅 박스
              Expanded(child: SingleChildScrollView(child: settingList(setting)))
            ],
          )),
        ));
  }

  Widget settingList(List<Map> setting) {
    return Column(
      children: [
        for (int i = 0; i < item_selected.length; i++)
          Column(
            children: [
              item(i, setting[i]),
              // 구분선
              Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey)
            ],
          )
      ], // 여기는 이 화면에서 품목 삭제하지 않는 한 리스트 번호 매겨서 체크해도 될듯?
    );
  }

  Widget item(int seq, Map info) {
    // 유통기한 변환
    String expire_date = "";
    if (info['expire_date'] != null) {
      expire_date = intl.DateFormat('yyyy.MM.dd').format(info['expire_date']);
    }
    // 양 변환
    double amount = info['amount'];
    String amountString = "";
    if (amount < 0) {
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
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 320,
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
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
                  ],
                )
              ],
            ),
            SizedBox(height: 16),
            // 냉장/냉동/기타 선택 박스
            Container(
                width: MediaQuery.of(context).size.width - 48,
                height: 30,
                color: Color.fromARGB(255, 247, 249, 251),
                child: Row(
                  children: [
                    Expanded(child: info['location'] == "냉장" ? selectedButton(seq, "냉장") : unselectedButton(seq, "냉장")),
                    info['location'] == "기타" ? Container(color: Colors.black, width: 0.5, height: 15) : Container(),
                    Expanded(child: info['location'] == "냉동" ? selectedButton(seq, "냉동") : unselectedButton(seq, "냉동")),
                    info['location'] == "냉장" ? Container(color: Colors.black, width: 0.5, height: 15) : Container(),
                    Expanded(child: info['location'] == "기타" ? selectedButton(seq, "기타") : unselectedButton(seq, "기타")),
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
                            child: Text(expire_date, style: inter14Grey))), // (체크) 실제 유통기한
                    Expanded(child: Container()),
                    SizedBox(
                        height: 20,
                        width: 20,
                        child: IconButton(
                            //(체크) onPressed => date_picker
                            onPressed: () async {
                              final now = DateTime.now();
                              final afterMonth = now.add(Duration(days: 30 * 12 * 20));
                              setting[seq]['expire_date'] = (await showDatePicker(  // (체크) 캘린더 한국어로 바꾸기
                                context: navigatorKey.currentState?.context as BuildContext,
                                initialDate: now,
                                firstDate: DateTime(now.year, now.month, now.day),
                                lastDate: DateTime(afterMonth.year, afterMonth.month, afterMonth.day),
                              ))!;
                              setState(() {});
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
                            //(체크) onPressed => 개수 1 or 0.5 감소(그렇게 계산된 값이 음수라면 취소)
                            onPressed: () {
                              setState(() {
                                if (info['half']) {
                                  // 반개 단위
                                  setting[seq]['amount'] += 0.5;
                                } else if (!info['half']) {
                                  // 1개 단위
                                  setting[seq]['amount'] += 1;
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
                            onPressed: () {
                              setState(() {
                                if (info['half'] && amount >= 0.5) {
                                  // 반개 단위
                                  setting[seq]['amount'] -= 0.5;
                                } else if (!info['half'] && amount >= 1) {
                                  // 1개 단위
                                  setting[seq]['amount'] -= 1;
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
                          setting[seq]['half'] = !setting[seq]['half'];
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
        ),
      ),
    );
  }

  Widget selectedButton(int seq, String name) {
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

  Widget unselectedButton(int seq, String name) {
    return Container(
        child: ElevatedButton(
            onPressed: () {
              setState(() {
                setting[seq]['location'] = name;
              });
            },
            child: Text(
              name,
              style: inter13Black,
            ),
            style: ElevatedButton.styleFrom(primary: Color.fromARGB(255, 247, 249, 251), elevation: 0)));
  }
}
