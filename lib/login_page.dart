import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:refrige_master/main.dart';

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
                    return ElevatedButton(
                        onPressed: () async {
                          bool isLogined = await viewModel.login();
                          if (isLogined) {
                            navigatorKey.currentState?.pushNamedAndRemoveUntil('/home_page', (route) => false);
                          }
                        },
                        child: Text("Login"));
                  } else {
                    return Center(child: Text("Loading..."));
                  }
                }),
          ),
        ),
      ),
    );
  }
}
