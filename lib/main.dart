import 'package:flutter/material.dart';
import 'package:refrige_master/food_edit_page.dart';
import 'package:refrige_master/member_invite_page.dart';
import 'package:refrige_master/member_list_page.dart';

import 'login_page.dart';
import 'home_page.dart';
import 'ref_add_page.dart';
import 'food_search_page.dart';
import 'food_detail_page.dart';
import 'food_add_page.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart' as kakao; // user 구분
import 'package:firebase_core/firebase_core.dart';
import 'backside/firebase_options.dart';
import 'package:flutter/foundation.dart' as foundation; // iOS, Android 구분

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  bool isiOS = (foundation.defaultTargetPlatform == foundation.TargetPlatform.iOS); //iOS or Android 구분할 때 필요
  WidgetsFlutterBinding.ensureInitialized();

  kakao.KakaoSdk.init(
      nativeAppKey: '73b4b6029de3c5a4f6d56d4a6f07dc73'); // firebase initialize 이전에 실행 // (체크)(iOS는 따로 추가할 것 있음.)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print(FirebaseAuth.instance.currentUser);

  runApp(
    MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Navigator',
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/login_page' : '/home_page',
      routes: {
        '/login_page': (context) => LoginPage(),
        '/home_page': (context) => HomePage(),
        '/ref_add_page': (context) => RefAddPage(),
        '/food_search_page': (context) => FoodSearchPage(),
        '/food_detail_page': (context) => FoodDetailPage(),
        '/food_add_page': (context) => FoodAddPage(),
        '/member_invite_page': (context) => MemberInvitePage(),
        '/member_list_page': (context) => MemberListPage(),
        '/food_edit_page': (context) => FoodEditPage(),
      },
    ),
  );
}
