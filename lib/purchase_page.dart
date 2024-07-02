import 'package:flutter/material.dart';
import 'package:refrige_master/backside/app_design_comp.dart';

import 'main.dart';

class PurchasePage extends StatefulWidget {
  PurchasePage({Key? key}) : super(key: key);

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
                // 전체 영역
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
                                      child: Text("장 보러 가기", style: interBold17))), // (체크) fontweight Semi bold
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
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 50.0),
                    child: Column(
                      children: [
                        // 프로필 사진  (체크) args['category']에 카테고리 넣어놨으니까 그거 참고해서 사진 나중에 넣기.
                        Container(
                            decoration: BoxDecoration(color: colorBackground, borderRadius: BorderRadius.circular(100)),
                            width: 74,
                            height: 74),
                        SizedBox(height: 10),
                        Text(args['name'],
                            style:
                                TextStyle(fontSize: 17, fontFamily: "Inter", fontWeight: FontWeight.bold, height: 1)),
                        SizedBox(height: 40),
                        // 이커머스 영역
                        for (int i = 0; i < 5; i++)
                          Column(
                            children: [eCommerceBox(), SizedBox(height: 24)],
                          )
                      ],
                    ))
              ],
            ))));
  }

  Widget eCommerceBox() {
    return Container(
        width: MediaQuery.of(context).size.width - 32.0,
        height: 50,
        decoration: BoxDecoration(color: colorBlue, borderRadius: BorderRadius.circular(10)),
        child: TextButton(
            onPressed: () {}, // (체크) onPressed => 각각의 이커머스로 연결. 식재료 이름 전달해서 검색.
            child: Text("이커머스 이름",
                style:
                    TextStyle(color: Colors.white, fontSize: 17, fontFamily: "Inter", fontWeight: FontWeight.bold))));
  }
}
