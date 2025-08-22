import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:mispos/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class ApiService {
  // final mc = GetStorage();
  final _dio = Dio()
    ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          options.baseUrl = "https://" +
              prefs.getString(Constant.ipServer)! +
              "/" +
              Constant.apiUrl;
          ;
          options.headers = {
            "Authorization": "bearer " + prefs.getString(Constant.token)!,
            "App-key": prefs.getString(Constant.AppKey)
          };
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          // Do something with response data
          return handler.next(response); // continue
        },
        onError: (DioError e, handler) => {handler.next(e)}));
  Future<dynamic> getAdv() async {
    var response = await Dio().get('https://misschool.net/AppAdvNew.json');
    if (response.statusCode == 200) {
      return response.data;
    }
    throw Exception("Network faild");
  }

  Future<bool> getPingPong() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {

      var response = await Dio().get("https://" +
          prefs.getString(Constant.ipServer)! +
          "/" +
          Constant.apiUrl +
          "/pingServer");
      print(response.statusCode);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (error) {
      return false;
    }
    throw Exception("Network faild");
  }
}
