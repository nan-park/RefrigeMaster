import 'package:flutter/material.dart';

//글꼴
const TextStyle inter17 = TextStyle(fontSize: 17, fontFamily: "Inter", height: 1.29); // letter height 22
const TextStyle inter13 = TextStyle(fontSize: 13, fontFamily: "Inter", height: 1.29);
const TextStyle inter14Black = TextStyle(fontSize: 14, fontFamily: "Inter", color: Colors.black, height: 1); // food_detail_page 때문에 줄맞춤 고정
const TextStyle interBold20 = TextStyle(fontSize: 20, fontFamily: "Inter", fontWeight: FontWeight.bold);
const TextStyle interBold17 = TextStyle(fontSize: 17, fontFamily: "Inter", fontWeight: FontWeight.bold);
const TextStyle inter17White = TextStyle(fontSize: 17, fontFamily: "Inter", color: Colors.white);
const TextStyle interBold20Blue =
    TextStyle(fontSize: 20, fontFamily: "Inter", fontWeight: FontWeight.bold, color: colorBlue);
const TextStyle inter14Blue = TextStyle(fontSize: 14, fontFamily: "Inter", color: colorBlue);
const TextStyle inter14Grey = TextStyle(fontSize: 14, fontFamily: "Inter", color: colorGrey, height: 1); // food_detail_page 때문에 줄맞춤
// (체크) const로 안하고 함수로 해도 되는 걸 나중에 깨달음.. 나중에 여유 있으면 바꾸자 ex) interGrey(14)

//색상
const Color colorPoint = Color.fromARGB(255, 0, 122, 255); // 키컬러. 파란색(변경 가능성)
const Color colorGrey = Color.fromARGB(77, 34, 34, 34); // 회색 30%
const Color colorBlue = Color.fromARGB(255, 0, 122, 255); // 현재 키컬러와 동일
const Color colorRed = Color.fromARGB(255, 235, 88, 40);

// 카테고리 디자인
Container category_box(String category) {
  double _width = 0;
  Color backColor = Colors.white;
  Color fontColor = Colors.white;
  switch (category) {
    case "채소":
      _width = 34;
      backColor = Color.fromARGB(255, 222, 245, 222);
      fontColor = Color.fromARGB(255, 3, 173, 0);
      break;
    case "과일":
      _width = 34;
      backColor = Color.fromARGB(255, 254, 215, 238);
      fontColor = Color.fromARGB(255, 218, 90, 182);
      break;
    case "수산물":
      _width = 46;
      backColor = Color.fromARGB(255, 201, 216, 255);
      fontColor = Color.fromARGB(255, 92, 118, 214);
      break;
    case "육류":
      _width = 34;
      backColor = Color.fromARGB(255, 254, 224, 226);
      fontColor = Color.fromARGB(255, 166, 52, 66);
      break;
    case "양곡":
      _width = 34;
      backColor = Color.fromARGB(255, 255, 234, 203);
      fontColor = Color.fromARGB(255, 160, 96, 0);
      break;
    case "견과":
      _width = 34;
      backColor = Color.fromARGB(255, 222, 207, 205);
      fontColor = Color.fromARGB(255, 121, 106, 101);
      break;
    case "유제품":
      _width = 46;
      backColor = Color.fromARGB(255, 232, 232, 232);
      fontColor = Color.fromARGB(255, 133, 133, 133);
      break;
    case "양념":
      _width = 34;
      backColor = Color.fromARGB(255, 151, 151, 151);
      fontColor = Color.fromARGB(255, 255, 255, 255);
      break;
    case "기타":
      _width = 34;
      backColor = Color.fromARGB(255, 210, 194, 255);
      fontColor = Color.fromARGB(255, 139, 98, 192);
      break;
  }
  return Container(
      width: _width,
      height: 20,
      child: Text(category,
          style: TextStyle(fontSize: 14, fontFamily: "Inter", color: fontColor), textAlign: TextAlign.center),
      decoration: BoxDecoration(color: backColor, borderRadius: BorderRadius.circular(5)));
}
