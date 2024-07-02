import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:refrige_master/backside/app_design_comp.dart';
import 'package:refrige_master/main.dart';

Future<List> getMemberList(String refId) async {
  DocumentSnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance.collection("Refrigerators").doc(refId).get();
  List lists = snapshot.get("member");
  List result = [];

  for (var element in lists) {
    Map maps = {};
    maps["uid"] = element;
    maps["username"] = await getNicknamebyUid(element);
    result.add(maps);
    print(maps);
  }

  print(result);

  return result;
}

//uid로 닉네임 불러오기
Future<String> getNicknamebyUid(String uid) async {
  DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance.collection("Users").doc(uid).get();

  return snapshot.get("nickname");
}

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
    getMemberList(args["refId"]);
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
                                    icon: Icon(Icons.arrow_back, size: 24))),
                          ),
                          // 제목
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              height: 24,
                              child: Text(args["refName"], style: interBold17),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                padding: EdgeInsets.all(0),
                                onPressed: () {
                                  navigatorKey.currentState?.pushNamed(
                                    '/member_invite_page',
                                    arguments: {"refId": args["refId"]},
                                  );
                                },
                                icon: Icon(Icons.person_add_alt_1_outlined),
                                color: Color.fromARGB(128, 34, 34, 34),
                              ),
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
              SizedBox(height: 10),
              FractionallySizedBox(
                widthFactor: 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      FutureBuilder(
                          future: getMemberList(args["refId"]),
                          builder: (BuildContext context, AsyncSnapshot snapshot) {
                            if (snapshot.hasData == false) {
                              return const Text("Loading...",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Inter',
                                    fontSize: 20,
                                  ));
                            } else {
                              return Column(
                                children: [
                                  for (int i = 0; i < snapshot.data.length; i++)
                                    Column(
                                      children: [
                                        // 프로필 사진
                                        SizedBox(
                                          height: 72,
                                          child: Row(
                                            children: [
                                              Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                      color: colorBackground,
                                                      borderRadius: BorderRadius.circular(100))),
                                              SizedBox(width: 16),
                                              // 유저 이름
                                              Text(
                                                snapshot.data?.elementAt(i)['username'],
                                              )
                                            ],
                                          ),
                                        ),
                                        // 구분선
                                        Container(
                                            height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
                                      ],
                                    )
                                ],
                              );
                            }
                          })
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
