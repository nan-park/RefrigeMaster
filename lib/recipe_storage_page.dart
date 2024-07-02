import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:refrige_master/backside/app_design_comp.dart';
import 'package:intl/intl.dart' as intl;

import 'main.dart';

Future<List> getStorageDocument() async {
  List<Map> list = [];
  final snapshot = await FirebaseFirestore.instance
      .collection("Users/" + FirebaseAuth.instance.currentUser!.uid + "/Storage")
      .orderBy('register_date', descending: true) // 최근 추가한 것이 맨 위에 오도록
      .get();

  snapshot.docs.forEach((element) {
    list.add({'recipe_uid': element.id, 'name': element.data()['name']});
  });
  return list; // {'recipe_uid': 레시피uid, 'name': 요리이름} 리스트
}

class RecipeStoragePage extends StatefulWidget {
  RecipeStoragePage({Key? key}) : super(key: key);

  @override
  State<RecipeStoragePage> createState() => _RecipeStoragePageState();
}

class _RecipeStoragePageState extends State<RecipeStoragePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            backgroundColor: colorBackground,
            body: SafeArea(
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
                                      height: 24, child: Text("보관함", style: interBold17))), // (체크) fontweight Semi bold
                              Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  width: 44,
                                  height: 28,
                                  child: TextButton(
                                    onPressed:
                                        () {}, // (체크) 누르면 편집 페이지로 넘어감. 선택해서 삭제할 수 있음. 완료하면 await로 감지해서 setState 해야 함.
                                    child: Text("편집", style: inter13Blue),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.fromLTRB(10, 6, 10, 6),
                                      side: BorderSide(
                                          color: colorPoint,
                                          width: 0.5), // (체크) figma 줄 두께는 0.5인데 에뮬레이터로 보면 너무 얇아 보임. 실제 기기에서 확인하기
                                      splashFactory: NoSplash.splashFactory,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6.0),
                                      ),
                                    ),
                                  ),
                                ),
                              )
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
                FutureBuilder(
                    future: getStorageDocument(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text("Error"),
                        );
                      } else if (snapshot.hasData) {
                        return Expanded(
                            child: SingleChildScrollView(
                                child: Column(
                          children: [
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Row(
                                  children: [
                                    Text("담은 레시피",
                                        style:
                                            TextStyle(fontSize: 14, fontFamily: "Inter", color: colorGrey3, height: 1)),
                                    SizedBox(width: 4),
                                    Text("(" + snapshot.data.length.toString() + ")", style: inter14Blue)
                                  ],
                                )),
                            recipeList(snapshot.data),
                          ],
                        )));
                      } else {
                        return Container();
                      }
                    })
              ],
            ))));
  }

  Widget recipeList(List mapList) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          for (int i = 0; i < mapList.length; i++)
            Column(
              children: [
                recipeBox(mapList[i]['recipe_uid'], mapList[i]['name']),
                SizedBox(height: 16),
              ],
            )
        ],
      ),
    );
  }

  Widget recipeBox(String recipeUid, String name) {
    return GestureDetector(
      onTap: () async {
        // (체크) onTap => 각각의 레시피 상세로 들어갈 수 있게끔 정보 넘겨줘야 함
        await navigatorKey.currentState
            ?.pushNamed('/recipe_detail_page', arguments: {'recipe_uid': recipeUid, 'name': name});
        setState(() {}); // (체크) 일단 이렇게 썼는데 맞는 플로우인지 확인하기
      },
      child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.0)),
          height: 74,
          width: MediaQuery.of(context).size.width - 32,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                    child: Center(
                      child: Image.asset(
                        'src/meal_meat_spaghetti.png',
                        width: 30,
                        height: 30,
                      ),
                    ),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: colorBackground, borderRadius: BorderRadius.circular(10.0))),
                SizedBox(width: 16),
                Text(name, style: interBold17)
              ],
            ),
          )),
    );
  }
}
