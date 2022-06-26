import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:refrige_master/backside/app_design_comp.dart';
import 'package:refrige_master/main.dart';

// 이메일에 해당하는 유저 가져오기
Future<Map> getUserByEmail(String email) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance.collection("Users").where('email', isEqualTo: email).get();

  var maps = {};

  if (snapshot.docs.isNotEmpty) {
    maps["id"] = snapshot.docs.first.id;
    maps["email"] = email;
    maps["nickname"] = snapshot.docs.first.get("nickname");
    return maps;
  } else {
    return maps;
  }
}

class MemberInvitePage extends StatefulWidget {
  MemberInvitePage({Key? key}) : super(key: key);
  @override
  State<MemberInvitePage> createState() => _MemberInvitePageState();
}

class _MemberInvitePageState extends State<MemberInvitePage> {
  bool searched = false;
  bool searchSucceed = false;
  String userName = "Loading...";
  String inputText = "";
  var emailFocusNode = FocusNode();
  var emailInputController = TextEditingController();
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
                              child: Text("냉장고 멤버 초대", style: interBold17),
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
              if (!searched)
                (Column(
                  children: [
                    const SizedBox(height: 48),
                    const Text(
                      "냉장고 멤버로 초대할 사람의\n아이디를 검색해주세요",
                      style: TextStyle(fontFamily: "Inter", fontSize: 14, color: Color.fromARGB(128, 0, 0, 0)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                  ],
                )),
              if (searched) (const SizedBox(height: 32)),
              FractionallySizedBox(
                widthFactor: 0.9,
                child: SizedBox(
                  height: 44,
                  child: TextFormField(
                    controller: emailInputController,
                    focusNode: emailFocusNode,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: "이메일을 입력하세요",
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
              const SizedBox(height: 24),
              FractionallySizedBox(
                widthFactor: 0.9,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      emailFocusNode.unfocus();
                      Map user = await getUserByEmail(inputText);
                      print(user);
                      setState(() {
                        searched = true;
                        if (user.isEmpty) {
                          searchSucceed = false;
                          userName = "검색 결과 없음";
                        } else {
                          searchSucceed = true;
                          userName = user["nickname"];
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      primary: Color.fromARGB(255, 0, 122, 255),
                    ),
                    child: const Text(
                      "검색하기",
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (searched)
                FractionallySizedBox(
                  widthFactor: 0.9,
                  child: (Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Color.fromARGB(255, 239, 241, 245),
                    ),
                    height: 240,
                    child: Column(
                      children: [
                        Spacer(),
                        Text(userName),
                        Spacer(),
                        if (searchSucceed)
                          (SizedBox(
                            width: 130,
                            height: 43,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                primary: Color.fromARGB(255, 0, 122, 255),
                              ),
                              child: const Text(
                                "추가하기",
                                style: TextStyle(
                                  fontFamily: "Inter",
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )),
                        if (searchSucceed) Spacer(),
                      ],
                    ),
                  )),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
