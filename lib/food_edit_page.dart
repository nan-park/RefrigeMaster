import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:refrige_master/backside/app_design_comp.dart';
import 'package:refrige_master/main.dart';

class FoodEditPage extends StatefulWidget {
  FoodEditPage({Key? key}) : super(key: key);

  @override
  State<FoodEditPage> createState() => _FoodEditPageState();
}

bool selectAllChackBox = false;

class _FoodEditPageState extends State<FoodEditPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
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
                                      navigatorKey.currentState?.pop();
                                    },
                                    padding: EdgeInsets.all(0.0),
                                    splashRadius: 10,
                                    icon: Icon(Icons.close_rounded, size: 24))),
                          ),
                          // 제목
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              height: 24,
                              child: Text("냉장고 이름", style: interBold17),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                color: Color.fromARGB(245, 255, 255, 255),
                height: 55,
              ),
              // 전체 선택 Layout-------------------------------
              Container(
                height: 56,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      side: MaterialStateBorderSide.resolveWith((states) => BorderSide(width: 2.0, color: colorPoint)),
                      checkColor: Colors.white,
                      value: selectAllChackBox,
                      shape: CircleBorder(),
                      onChanged: (bool? value) {
                        setState(() {
                          selectAllChackBox = value!;
                        });
                      },
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "전체 선택",
                          style: TextStyle(color: colorPoint),
                        ),
                        SizedBox(height: 4)
                      ],
                    )
                  ],
                ),
              ),
              // 리스트 Layout-------------------------------
              // 구분선
              Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey),
              // 식재료 목록
            ],
          ),
        ),
      ),
    );
  }
}
