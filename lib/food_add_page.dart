import 'package:flutter/material.dart';
import 'package:refrige_master/backside/app_design_comp.dart';

import 'main.dart';

class FoodAddPage extends StatefulWidget {
  FoodAddPage({Key? key}) : super(key: key);

  @override
  State<FoodAddPage> createState() => _FoodAddPageState();
}

class _FoodAddPageState extends State<FoodAddPage> {
  // 변수들
  String inputText = "";
  int searchedItemCount = 5; // 검색 결과 항목 개수
  int oftenItemCount = 5; // 자주 사는 항목 개수. 아무리 많아도 5개 이하.
  int selectedItemCount = 1; // 추가하기로 선택한 항목 개수
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SafeArea(
            child: Scaffold(
                body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // 키보드 이외의 영역 선택하면 키보드 사라짐
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // 전체 영역 div
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
                                    child: Text("품목 추가", style: interBold17))) // (체크) fontweight Semibold로 바꾸기
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
                        setState(() {
                          inputText = text;
                        });
                      },
                    ),
                  )),
              Expanded(
                child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [ // (체크) 검색창에 무언가 넣었을 때는 '자주 사는 항목' 사라지고 검색 결과 나와야 함.
                    Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 4, bottom: 10),
                        child: Text("자주 사는 항목", style: inter17)),
                    // 식재료 리스트(자주 사는 항목) // (체크) 나중에 실제 데이터 넣기
                    for (int i = 0; i < oftenItemCount; i++) item()
                  ],
                )),
              )
            ],
          ),
        ))));
  }

  Widget item() {
    return Container(
        height: 72,
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
            child: Row(children: [
              // 식재료 사진
              Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100), color: Color.fromARGB(255, 242, 242, 246))),
              SizedBox(width: 16),
              // name
              Text("사과", style: inter14Black),
              SizedBox(width: 8),
              Container(
                  width: 3,
                  height: 3,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(100), color: Color.fromARGB(255, 34, 34, 34))),
              SizedBox(width: 8),
              // category
              Text("과일", style: inter14Black),
              Expanded(child: Container()),
              SizedBox(
                  height: 20,
                  width: 20,
                  child: TextButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: Icon(Icons.check, color: Colors.white, size: 16),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: colorPoint,
                          shape: RoundedRectangleBorder(
                              side: BorderSide(color: colorPoint), borderRadius: BorderRadius.circular(100.0))))),
            ])));
  }
}
