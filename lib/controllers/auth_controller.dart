import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mispos/models/user_model.dart';
import 'package:mispos/services/api_service.dart';
import 'package:mispos/services/auth_service.dart';
import 'package:mispos/utils/circular_progress_loading.dart';
import 'package:mispos/utils/constants.dart';

class returnAuth {
  bool? state;
  String? message;
}

class AuthController extends GetxController {
  var userName = '';
  var userPassword = '';

  final authFailMsg = "".obs;

  /// ติดต่อ server ไม่ได้ ให้หน้า login แสดงปุ่มไปแก้ IP Server
  final authFailIsServerProblem = false.obs;
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
    authFailIsServerProblem.value = false;

    UserModel user = UserModel();
    user.username = userName;
    user.password = userPassword;
    user.authURL = Constant.apiUrl;
    print(user);
    final result = await AuthService().login(user);

    rep.value.state = result.ok;
    rep.value.message = result.message;
    authFailMsg.value = result.message;
    authFailIsServerProblem.value = result.serverProblem;

    process.value = false;
    return rep.value;
  }
}
