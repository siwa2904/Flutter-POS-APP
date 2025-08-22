import 'package:get/get.dart';
// import 'package:posflutter/pages/authen_page.dart';
// import 'package:posflutter/pages/home_page/home_page.dart';
// import 'package:posflutter/pages/pos/pos_page.dart';
// import 'package:posflutter/pages/pos_sale/cm_display_page.dart';
// import 'package:posflutter/pages/setting_page.dart';
import 'package:mispos/screens/splash_screen.dart';

import '../main.dart';
import '../pages/authen_page.dart';
import '../pages/home_page/home_page.dart';
import '../pages/pos_sale/cm_display_page.dart';
import '../pages/setting_page.dart';
// import '../pages/pos_sale/pos_sale_page.dart';

class Routes {
  static final routes = [
    GetPage(name: '/', page: () => SplashScreen()),
    // // GetPage(name: '/IntrolPage', page: ()=>IntrolPage()),
    GetPage(name: '/Auth', page: () => AuthenPage()),
    // GetPage(name: '/testpage', page: () => MyApp()),
    // GetPage(name: '/presentation', page: () => SecondaryScreen()),
    // // GetPage(name: '/MainPage', page: ()=>MainPage()),
    GetPage(name: '/HomePage', page: ()=>HomePage()),
    // // GetPage(name:"/customer_display",page: ()=>CustomerDisplayPage()),
    GetPage(name:"/cm_display",page: ()=>CmDisplayPage()),
    // GetPage(name: '/pos/sale', page: ()=>PosSalePage()),
    GetPage(name: '/setting', page: ()=>SettingPage()),
    // GetPage(name: '/TopupPage', page: ()=>TopupPage()),
    // GetPage(name: '/TimeTable', page: ()=>TimetablePage())
    // GetPage(name: '/IntrolPage', page: ()=>);
  ];
}
