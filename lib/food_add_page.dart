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
    final args = ModalRoute.of(context)!.settings.arguments as Map;
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
                    // 구분선
                    Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey),
                    // 품목 설정 박스
                    settingList(args["item_selected"])
                  ],
                ),
                color: Color.fromARGB(245, 255, 255, 255),
                height: 55,
              ),
            ],
          )),
        ));
  }

  Widget settingList(List item_selected) {
    //(현재)
    List<Map<String, String>> list = [];
    for (int i = 0; i < item_selected.length; i++) {
      list.add({
        "name": item_selected[i].split("/")[0],
        "category": item_selected[i].split("/")[1]
      }); // (체크)직접추가면 category == ""
    } // ex) list = [{"name": "사과", "category": "과일"}]
    return Column(
      children: [
        for (int i = 0; i < item_selected.length; i++) item(list[i])
      ], // 여기는 이 화면에서 품목 삭제하지 않는 한 리스트 번호 매겨서 체크해도 될듯?
    );
  }

  Widget item(Map<String, String> map) {
    return Column(
      children: [],
    );
  }
}
