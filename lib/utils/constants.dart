import 'dart:math';

import 'package:flutter/material.dart';

class Constant {

  // shared preferences
  static const String IS_LOGIN_PREF = "is_login";
  static const String USERNAME_PREF = "username";

  static const String OneSignalKey = "6c188515-9db5-4c73-a79c-31812e07ce3c";
  //routes
  static const String HOME_ROUTE = "/home";
  static const String LOGIN_ROUTE = "/login";
  static const String DETAIL_ROUTE = "/youtube detail";

  //strings
  static const String APP_NAME = "CM Flutter";

  //pusher
  static const String push_app_id = "1440998";
  static const String push_key = "2392e72b3f14c6e3905e";
  static const String push_secret = "bfb819311b68dbd76c6e";
  static const String push_cluster = "ap1";

  //fonts
  static const String QUICK_SAND_FONT = "Quicksand";
  static const String KANIT_FONT = "Kanit";

  //images
  static const String IMAGE_DIR = "assets/images";
  static const String HEADER_HOME_IMAGE = "$IMAGE_DIR/header_home.png";
  static const String HEADER_LOGIN_IMAGE = "$IMAGE_DIR/header_login.png";

  //color
  static const Color PRIMARY_COLOR = Color(0xFF01579B);

  //random color
  static final Random _random = Random();

  // Returns a random color.
  static Color next() {
    return Color(0xFF000000 + _random.nextInt(0x00FFFFFF));
  }

  //
  static final String IsAuth = "IsAuth";
  static final String ApiVersion = "ApiVersion";
  static final String ShopID = "ShopID";
  static final String ShopName = "ShopName";
  static final String ShopLogo = "ShopLogo";
  static final String apiUrlMain = "apiUrlMain";
  static final String apiUrl = "v1";
  static final String serverURL = "api";

  static const String ipServer="ipServer";
  static const String posNo="posNo";
  static const String saleOffline = "saleOffline";

  static final String POS_ID="2";
  static final String POS_CODE="POS_CODE";
  static final String token = "token";

  static final String UserNo = "UserNo";
  static final String Mobile = "Mobile";
  static final String Name = "Name";
  static final String ImageUrl = "ImageUrl";
  static final String AllowAddStd = "AllowAddStd";
  static final String SchoolTitleEN = "SchoolTitleEN";
  static final String SchoolTel = "SchoolTel";
  static final String SchoolEmail = "SchoolEmail";
  static final String SchoolAddress = "SchoolAddress";

  // static final String paymentAPI_dev =
  //     "https://api-dev.misschool.net/payment";
  static final String paymentAPI = "https://api-prod.misschool.net/gov/payment";
  // "https://api-dev.misschool.net/payment";
  static final String AppKey = "Appkey";

  static const String FIREBASE_APP_ID =
      "1:327060596918:android:8a0d05d88cc399b207de17";
  static const String FIREBASE_API_KEY =
      "AIzaSyCYroyGyaV2EmS5Oe8kLzVAsEK8kcSJD0c";
  static const String FIREBASE_PROJECT_ID = "app-deep-link-831d5";
  static const String FIREBASE_SENDER_ID = "327060596918";
  static const String FIREBASE_AUTH_DOMAIN = "";
}
