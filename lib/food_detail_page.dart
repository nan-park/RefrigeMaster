import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;

import 'package:refrige_master/backside/app_design_comp.dart';
import 'main.dart';

Future<Map> getIngredientDoc(String ref_docid, String ing_docid) async {
  Map<String, Map<String, dynamic>?> map = {};
  final snapshot =
      await FirebaseFirestore.instance.collection("Refrigerators/" + ref_docid + "/Ingredients").doc(ing_docid).get();

  String docid = snapshot.id;
  map[docid] = snapshot.data();
  print("식재료 상세: " + map.toString());
  return map;
}

Widget itemBox(String title, String contents) {
  return Row(
    children: [
      Container(
          height: 42,
          width: 80,
          child: Padding(padding: EdgeInsets.fromLTRB(12, 12, 0, 12), child: Text(title, style: inter14Black))),
      Container(
          height: 42,
          child: Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Text(contents, style: inter14Grey)))
    ],
  );
}

class FoodDetailPage extends StatefulWidget {
  FoodDetailPage({Key? key}) : super(key: key);

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
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
                                  height: 24, child: Text("식재료 상세", style: interBold17))), // (체크) fontweight Semi bold
                          Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // 삭제 버튼 //(체크) onPressed
                                  SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: IconButton(
                                          padding: EdgeInsets.all(0),
                                          onPressed: () {},
                                          icon: Icon(Icons.delete_outline),
                                          color: Color.fromARGB(128, 34, 34, 34))),
                                  SizedBox(width: 12),
                                  // 편집 버튼 //(체크) onPressed
                                  SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: IconButton(
                                          padding: EdgeInsets.all(0),
                                          onPressed: () {},
                                          icon: Icon(Icons.create),
                                          color: Color.fromARGB(128, 34, 34, 34)))
                                ],
                              ))
                        ],
                      )),
                ],
              ),
              color: Color.fromARGB(245, 255, 255, 255),
              height: 55,
            ),
            //  식재료 내용
            FutureBuilder(
                future: getIngredientDoc(args['ref_docid'], args['ing_docid']),
                builder: (context, AsyncSnapshot snapshot) {
                  DateTime expire_date = snapshot.data.values.elementAt(0)['expire_date'].toDate();
                  int dDay = expire_date.difference(DateTime.now()).inDays.toInt();
                  String dDayString = ""; // 디데이 String
                  String amountString = ""; // 개수 String
                  double amount = snapshot.data.values.elementAt(0)['amount'].toDouble();
                  if (dDay > 0) {
                    dDayString = "D - " + dDay.toString();
                  } else if (dDay == 0) {
                    dDayString = "D - Day";
                  } else if (dDay < 0) {
                    int dDay_minus = dDay * (-1);
                    dDayString = "D + " + dDay_minus.toString();
                  }
                  if (amount < 0) {
                    // 많음/보통/적음/매우적음
                    switch ((amount * (-1)).toInt()) {
                      case 1:
                        amountString = "매우 적음";
                        break;
                      case 2:
                        amountString = "적음";
                        break;
                      case 3:
                        amountString = "보통";
                        break;
                      case 4:
                        amountString = "많음";
                        break;
                    }
                  } else if (amount % 1 == 0) {
                    // 개수 string(정수면 .0 빼기)
                    int num = amount.toInt();
                    amountString = num.toString() + "개";
                  } else {
                    amountString = amount.toString() + "개";
                  }
                  return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // 식재료 사진
                              Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: Color.fromARGB(255, 242, 242, 246))),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 카테고리 박스
                                  category_box(snapshot.data.values.elementAt(0)['category']),
                                  SizedBox(height: 6),
                                  // 식재료 이름 (체크) info 있으면 옆에 아이콘 있도록
                                  Text(snapshot.data.values.elementAt(0)['name'],
                                      style: TextStyle(fontSize: 18, fontFamily: "Inter")),
                                  SizedBox(height: 8),
                                  // 디데이(D-Day)
                                  Text(dDayString,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: "Inter",
                                          fontWeight: FontWeight.bold,
                                          color: dDay < 4 ? colorRed : colorBlue)), //(체크) semi bold
                                ],
                              )
                            ],
                          ),
                          SizedBox(height: 37),
                          // 식재료 정보 리스트
                          Column(children: [
                            itemBox("보관장소", snapshot.data.values.elementAt(0)['location']),
                            itemBox(
                                "등록일",
                                intl.DateFormat('yyyy.MM.dd')
                                    .format(snapshot.data.values.elementAt(0)['register_date'].toDate())),
                            itemBox(
                                "유통기한",
                                intl.DateFormat('yyyy.MM.dd')
                                    .format(snapshot.data.values.elementAt(0)['expire_date'].toDate())),
                            itemBox("개수", amountString),
                          ]),
                          SizedBox(height: 24),
                          // 장보러가기 버튼 (체크) onPressed
                          SizedBox(
                            height: 50,
                            width: MediaQuery.of(context).size.width - 46,
                            child: TextButton(
                                onPressed: () {},
                                child: Text("장 보러 가기", style: inter17White),
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(colorPoint),
                                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                          ),
                          // 메모 (체크) 추가 해야함
                        ],
                      ));
                })
          ],
        ))));
  }
}
