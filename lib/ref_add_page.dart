import 'package:flutter/material.dart';
import 'package:refrige_master/backside/app_design_comp.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'main.dart';

// Add new refrigerator on DB
void writeRefAndUpdatePresent(String refName) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection("Refrigerators")
      .where('present_member', arrayContains: FirebaseAuth.instance.currentUser?.uid)
      .get();
  String pre_docid = snapshot.docs[0].id;
  // remove
  await FirebaseFirestore.instance.collection("Refrigerators").doc(pre_docid).update({
    "present_member": FieldValue.arrayRemove([FirebaseAuth.instance.currentUser?.uid])
  });

  // add
  await FirebaseFirestore.instance
      .collection("Refrigerators")
      .add({
        "member": [FirebaseAuth.instance.currentUser?.uid],
        "present_member": [FirebaseAuth.instance.currentUser?.uid],
        "ref_name": refName
      })
      .then((value) => value.collection("Ingredients").doc().set({})) //(check) not to make an empty document
      .catchError((error) => print("Failed to add: $error"));
}

class RefAddPage extends StatefulWidget {
  @override
  State<RefAddPage> createState() => _RefAddPageState();
}

class _RefAddPageState extends State<RefAddPage> {
  // 변수들
  String inputText = "";
  @override
  Widget build(BuildContext context) {
    // 빌드 이후 변수
    double widthPadding = MediaQuery.of(context).size.width - 32.0; // 가로 패딩 16.0
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: SafeArea(
                // 전체 영역
                child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // 키보드 이외의 영역 선택하면 키보드 사라짐
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
                                    child: Text("냉장고 추가", style: interBold17))) // (체크) fontweight Semibold로 바꾸기
                          ],
                        )),
                  ],
                ),
                color: Color.fromARGB(245, 255, 255, 255),
                height: 55,
              ),
              //구분선
              Container(height: 1, width: MediaQuery.of(context).size.width, color: Color.fromARGB(77, 34, 34, 34)),
              SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 48),
                    Center(
                        child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Text(
                              "새로운 냉장고를 생성하고 멤버를 초대할 수 있습니다.",
                              style:
                                  TextStyle(fontSize: 14, fontFamily: "Inter", color: Color.fromARGB(124, 34, 34, 34)),
                              textAlign: TextAlign.center,
                            ))),
                    SizedBox(height: 48),
                    // 냉장고 이름 입력 (체크) 글자수 제한 있어야 할것같음
                    Container(
                        height: 42,
                        color: Color.fromARGB(245, 255, 255, 255),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: TextField(
                            autofocus: true,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: "냉장고 이름을 입력하세요",
                              hintStyle: inter14Grey,
                              border: InputBorder.none,
                              hintMaxLines: 1,
                              fillColor: Color.fromARGB(255, 239, 241, 245),
                              filled: true,
                            ),
                            onChanged: (text) {
                              setState(() {
                                inputText = text;
                              });
                            },
                          ),
                        )),
                    SizedBox(height: 24),
                    // 냉장고 추가 버튼
                    SizedBox(
                      height: 52,
                      width: MediaQuery.of(context).size.width - 32,
                      child: TextButton(
                          onPressed: () {
                            if (inputText == "") {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("냉장고 이름을 입력해주세요!"), duration: Duration(seconds: 5)));
                            } else {
                              writeRefAndUpdatePresent(inputText);
                              navigatorKey.currentState?.pop(); // (체크) bottom sheet까지 다 없애고 refresh하는 방법은 없을까?
                            }
                          },
                          child: Text("냉장고 추가하기", style: inter17White),
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(colorPoint),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))))),
                    ),
                  ],
                ),
              ),
              Expanded(
                  child: Container(
                color: Color.fromARGB(245, 255, 255, 255),
              )) // (해결) 아래에 스크롤되지 않을 만큼의 빈 공간 만들어야 함. focus 풀리도록
            ],
          ),
        ))));
  }
}
