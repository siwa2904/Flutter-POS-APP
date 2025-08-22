import 'dart:convert';

import 'package:dio/dio.dart' as DioService;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mispos/models/user_model.dart';
import 'package:mispos/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // final mc = GetStorage();
  Future<bool> login(
    UserModel user,
  ) async {
    final username = user.username;
    final password = user.password;
    String iSVersion = "";

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final authURL =
        "https://" + prefs.getString(Constant.ipServer)! + "/" + Constant.apiUrl;
    var credentials = {
      "username": username,
      "password": password,
    };
    print('${authURL!}/Auth');
    Get.snackbar("AuthUrl",'${authURL!}/Auth');

    String token = prefs.getString(Constant.token) ?? '';
    var dio = DioService.Dio();

    try {
      DioService.Response response =
          await dio.post('$authURL/Auth', data: credentials);
      print(response.statusCode);
      Get.snackbar("Response", response.statusCode.toString());
      if (response.statusCode == 200) {
        print("===OK===");

        var resp = response.data;
        prefs.setBool(Constant.IsAuth, true);
        prefs.setString(Constant.ApiVersion, iSVersion);
        prefs.setString(Constant.token, resp['Token']);
        prefs.setString(Constant.UserNo, resp['UserNo'].toString());
        prefs.setString(Constant.Name, resp['Name']);
        prefs.setString(Constant.ImageUrl, resp['ImageUrl']);
        prefs.setString(Constant.AllowAddStd, '');
        prefs.setString(Constant.ShopID, resp['ShopID']);
        prefs.setString(Constant.ShopName, resp['ShopName']);
        prefs.setString(Constant.ShopLogo, resp['ShopLogo']);
        return true;
      }else{

      }
    } catch (e) {
      print(e);
      Get.snackbar("AuthError", e.toString());
      return false;
    }
    return false;
  }

  Future<bool> isLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constant.IS_LOGIN_PREF) ?? false;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(Constant.IS_LOGIN_PREF);
  }
}
