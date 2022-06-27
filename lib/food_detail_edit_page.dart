import 'package:flutter/material.dart';
import 'package:refrige_master/backside/app_design_comp.dart';
import 'package:refrige_master/main.dart';

class FoodDetailEditPage extends StatefulWidget {
  FoodDetailEditPage({Key? key}) : super(key: key);

  @override
  State<FoodDetailEditPage> createState() => _FoodDetailEditPageState();
}

class _FoodDetailEditPageState extends State<FoodDetailEditPage> {
  List setting = [];
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
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
                                        child: Text("식재료 상세", style: interBold17))), // (체크) fontweight Semi bold
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // 완료 버튼
                                        SizedBox(
                                            width: 44,
                                            height: 28,
                                            child: TextButton(
                                                child: Text("완료", style: inter13Blue),
                                                onPressed: () async {
                                                  // (체크) onPressed
                                                },
                                                style: TextButton.styleFrom(
                                                    padding: EdgeInsets.all(0),
                                                    backgroundColor: Color.fromARGB(25, 0, 122, 255))))
                                      ],
                                    ))
                              ],
                            )),
                      ],
                    ),
                    color: Color.fromARGB(245, 255, 255, 255),
                    height: 55,
                  ),
                ],
              ),
            )));
  }
}
