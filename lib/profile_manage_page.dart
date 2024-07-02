import 'package:flutter/material.dart';
import 'package:refrige_master/backside/app_design_comp.dart';

class ProfileManagePage extends StatefulWidget {
  ProfileManagePage({Key? key}) : super(key: key);

  @override
  State<ProfileManagePage> createState() => _ProfileManagePageState();
}

class _ProfileManagePageState extends State<ProfileManagePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                                          Navigator.of(context).pop();
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
                                      child: Text("프로필 관리", style: interBold17))), // (체크) fontweight Semi bold
                            ],
                          )),
                    ],
                  ),
                  color: Color.fromARGB(245, 255, 255, 255),
                  height: 50, // (체크) 원래 44인데 좀 늘림. 나중에 실제 앱에서 확인해보기
                ),
                // 구분선
                Container(height: 0.5, width: MediaQuery.of(context).size.width, color: colorGrey1),
                // 상단바 이외 영역 --------
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 32),
                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                                color: colorBackground, borderRadius: BorderRadius.all(Radius.circular(100))),
                          ),
                        ),
                        SizedBox(height: 48),
                        Text("프로필 정보", style: interBold17),
                        SizedBox(height: 24),
                        Text("닉네임", style: TextStyle(fontSize: 14, fontFamily: "Inter", color: colorGrey3, height: 1)),
                        SizedBox(height: 7),
                        Row(
                          children: [
                            Text("박난", style: inter14Black),
                            Expanded(child: Container()),
                            SizedBox(
                              width: 44,
                              height: 28,
                              child: TextButton(
                                onPressed: () {}, // (체크) onPressed => 닉네임 수정
                                child: Text("변경", style: inter13Blue),
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
                          ],
                        ),
                        SizedBox(height: 7),
                        // 구분선
                        Container(height: 0.5, width: MediaQuery.of(context).size.width - 32, color: colorGrey1),
                        SizedBox(height: 16),
                        Text("카카오계정", style: TextStyle(fontSize: 14, fontFamily: "Inter", color: colorGrey3, height: 1)),
                        SizedBox(height: 12),
                        Text("parknan00@naver.com", style: inter14Black),
                        SizedBox(height: 12),
                        // 구분선
                        Container(height: 0.5, width: MediaQuery.of(context).size.width - 32, color: colorGrey1),
                      ],
                    ),
                  ),
                )
              ],
            ))));
  }
}
