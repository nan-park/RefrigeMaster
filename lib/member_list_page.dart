import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:refrige_master/backside/app_design_comp.dart';
import 'package:refrige_master/main.dart';

class MemberListPage extends StatefulWidget {
  MemberListPage({Key? key}) : super(key: key);
  @override
  State<MemberListPage> createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> {
  bool searched = false;
  bool searchSucceed = false;
  String userName = "Loading...";
  String inputText = "";
  Map user = {};
  var emailFocusNode = FocusNode();
  var emailInputController = TextEditingController();
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
              Container(height: 1, width: MediaQuery.of(context).size.width, color: Color.fromARGB(77, 34, 34, 34)),
              FractionallySizedBox(
                widthFactor: 0.9,
                child: Container(
                  height: 40,
                  child: Row(
                    children: [
                      Text(
                        "냉장고 멤버",
                        style: TextStyle(fontFamily: "Inter", fontSize: 14, color: Color.fromARGB(128, 34, 34, 34)),
                      )
                    ],
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.9,
                child: SizedBox(
                  height: 44,
                  child: TextFormField(
                    controller: emailInputController,
                    focusNode: emailFocusNode,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: "멤버 닉네임을 입력하세요",
                      hintStyle: inter14Grey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      hintMaxLines: 1,
                      fillColor: Color.fromARGB(255, 239, 241, 245),
                      filled: true,
                    ),
                    onChanged: (text) {
                      inputText = text;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
