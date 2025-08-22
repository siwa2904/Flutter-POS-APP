import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mispos/models/user_model.dart';
import 'package:mispos/services/api_service.dart';
import 'package:mispos/services/auth_service.dart';
import 'package:mispos/utils/circular_progress_loading.dart';
import 'package:mispos/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class returnAuth {
  bool? state;
  String? message;
}

class AuthController extends GetxController {
  var userName = '';
  var userPassword = '';

  final authFailMsg = "".obs;
  final rep = returnAuth().obs;
  final process = false.obs;
  final appVersion = "".obs;
  RxBool loadingSchool = false.obs;

  @override
  void onInit() {
    // getSchoolAll();
    super.onInit();
  }

  Future<returnAuth> authen() async {
    process.value = true;
    authFailMsg.value = "";

    SharedPreferences prefs = await SharedPreferences.getInstance();

    UserModel user = UserModel();
    user.username = userName;
    user.password = userPassword;
    user.authURL = Constant.apiUrl;
    print(user);
    bool auth = await AuthService().login(user);

    rep.value.state = auth;
    rep.value.message = (!auth) ? "ชื่อผู้ใช้ หรือ รหัสผ่านไม่ถูกต้อง" : "";
    authFailMsg.value = (!auth) ? "ชื่อผู้ใช้ หรือ รหัสผ่านไม่ถูกต้อง" : "";

    process.value = false;
    return rep.value;
  }
}
