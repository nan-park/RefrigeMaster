import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:refrige_master/main.dart';
import 'backside/app_design_comp.dart';

import 'backside/login_view_model.dart';
import 'backside/kakao_login.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 변수들
  final viewModel = LoginViewModel(KakaoLogin());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    // 로그인 안 된 상태
                    // 로그인 버튼
                    return Column(
                      children: [
                        const Spacer(flex: 2),
                        Image.asset(
                          'src/logo.png',
                          width: 166,
                          height: 40,
                        ),
                        const Spacer(),
                        Text("손쉽게 냉장고 정리와",
                            style: TextStyle(fontSize: 14, fontFamily: "Inter", color: Color.fromARGB(125, 0, 0, 0))),
                        Text("일주일 식단을 관리하세요",
                            style: TextStyle(fontSize: 14, fontFamily: "Inter", color: Color.fromARGB(125, 0, 0, 0))),
                        Spacer(),
                        const SizedBox(
                          height: 440,
                          child: Image(image: AssetImage('src/LoginPageImage.png')),
                        ),
                        const Spacer(flex: 3),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 32,
                          height: 52,
                          child: TextButton(
                            onPressed: () async {
                              bool isLogined = await viewModel.login();
                              if (isLogined) {
                                navigatorKey.currentState?.pushNamedAndRemoveUntil('/home_page', (route) => false);
                              }
                            },
                            child: Text("카카오톡으로 시작하기",
                                style: TextStyle(
                                    fontSize: 17, fontFamily: "Inter", color: Color.fromARGB(255, 50, 32, 31))),
                            style: TextButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 248, 206, 70),
                              splashFactory: NoSplash.splashFactory,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    );
                  } else {
                    return Container();
                  }
                }),
          ),
        ),
      ),
    );
  }
}
