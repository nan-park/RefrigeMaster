import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:refrige_master/backside/firebase_auth_remote_data_source.dart';

import 'social_login.dart';

class LoginViewModel {
  final _firebaseAuthDataSource = FirebaseAuthRemoteDataSource();
  final SocialLogin _socialLogin;
  bool isLogined = false; // 일단 로그인 안 됐다고 가정
  kakao.User? user;

  LoginViewModel(this._socialLogin);

  Future writeUserDoc(String? nickname, String? email) async {
    final snapshot =
        await FirebaseFirestore.instance.collection("Users").doc(FirebaseAuth.instance.currentUser!.uid).get();
        print("dd");
        print(snapshot.data());
    if (snapshot.data()==null) {
      // 유저 정보가 없다면
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({"email": email, "nickname": nickname, "notice_accept": false});
      print("create user info");
    }
  }

  Future login() async {
    isLogined = await _socialLogin.login();
    if (isLogined) {
      user = await kakao.UserApi.instance.me();
      final token = await _firebaseAuthDataSource.createCustomToken({
        'uid': user!.id.toString(),
        'displayName': user!.kakaoAccount!.profile!.nickname,
        'photoURL': user!.kakaoAccount!.profile!.profileImageUrl!,
        'email': user!.kakaoAccount!.email!,
      });
      await FirebaseAuth.instance.signInWithCustomToken(token);
      await writeUserDoc(user!.kakaoAccount!.profile!.nickname, user!.kakaoAccount!.email!);
    }
  }

  Future logout() async {
    await _socialLogin.logout();
    await FirebaseAuth.instance.signOut();
    isLogined = false;
    user = null;
  }
}
