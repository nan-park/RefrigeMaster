import 'package:flutter/material.dart';

import 'package:refrige_master/backside/app_design_comp.dart';
import 'package:refrige_master/food_search_page.dart';
import 'main.dart';

class FoodAddPage extends StatefulWidget {
  FoodAddPage({Key? key}) : super(key: key);

  @override
  State<FoodAddPage> createState() => _FoodAddPageState();
}

class _FoodAddPageState extends State<FoodAddPage> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map; //item_selected
    List<Map> setting = [];

    return MaterialApp(
        debugShowCheckedModeBanner: false,
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
              Expanded(child: SingleChildScrollView(child: settingList(args["item_selected"])))
            ],
          )),
        ));
  }

  Widget settingList(List<String> item_selected) {
    //(현재)
    List list = [];
    for (int i = 0; i < item_selected.length; i++) {
      list.add(item_selected[i].split("/")); // (체크) 직접추가면 ["식재료이름", ""]
    } // ex) list = [[사과, 과일], [가지, 채소]]
    return Column(
      children: [
        for (int i = 0; i < item_selected.length; i++)
          Column(
            children: [
              item(list[i][0], list[i][1]),
              // 구분선
              Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey)
            ],
          )
      ], // 여기는 이 화면에서 품목 삭제하지 않는 한 리스트 번호 매겨서 체크해도 될듯?
    );
  }

  Widget item(String name, String category) {
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
                    category_box(category),
                    SizedBox(height: 6),
                    // 식재료 이름 (체크) info 있으면 옆에 아이콘 있도록
                    Text(name, style: TextStyle(fontSize: 18, fontFamily: "Inter")),
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
                    Expanded(child: selectedButton("냉장")),
                    Expanded(child: unselectedButton("냉동")),
                    Container(color: Colors.black, width: 0.5, height: 15),
                    Expanded(child: unselectedButton("기타")),
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
                            child: Text("2022.04.04", style: inter14Grey))), // (체크) 실제 유통기한
                    Expanded(child: Container()),
                    SizedBox(
                        height: 20,
                        width: 20,
                        child: IconButton(
                            //(체크) onPressed => date_picker
                            onPressed: () {},
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
                            child: Text("6.5개", style: inter14Grey))), // (체크) 실제 개수
                    Expanded(child: Container()),
                    // + 버튼
                    SizedBox(
                        height: 24,
                        width: 24,
                        child: IconButton(
                            //(체크) onPressed => 개수 1 or 0.5 감소(그렇게 계산된 값이 음수라면 취소)
                            onPressed: () {},
                            icon: Icon(Icons.add, size: 24),
                            padding: EdgeInsets.all(0))),
                    SizedBox(width: 6),
                    // - 버튼
                    SizedBox(
                        height: 24,
                        width: 24,
                        child: IconButton(
                            //(체크) onPressed => 개수 1 or 0.5 증가
                            onPressed: () {},
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
                      onPressed: () {}, // (체크)onPressed
                      child: Icon(Icons.check, color: Colors.white, size: 16),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: colorPoint, // (체크)
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

  Widget selectedButton(String name) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: ElevatedButton(
          onPressed: () {},
          child: Text("냉장", style: interBold13White),
          style: ElevatedButton.styleFrom(
              primary: colorPoint,
              onPrimary: colorPoint,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)))),
    );
  }

  Widget unselectedButton(String name) {
    return Container(
        child: ElevatedButton(
            onPressed: () {},
            child: Text(
              name,
              style: inter13Black,
            ),
            style: ElevatedButton.styleFrom(primary: Color.fromARGB(255, 247, 249, 251), elevation: 0)));
  }
}
