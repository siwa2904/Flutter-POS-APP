import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:mispos/controllers/networkmanager_controller.dart';
import 'package:mispos/controllers/setting_controller.dart';
import 'package:mispos/pages/setting_page.dart';
import 'package:mispos/utils/constants.dart';
import 'package:mispos/widgets/color_loader_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  SplashScreenState createState() => new SplashScreenState();
}

enum UniLinksType { string, uri }

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  SharedPreferences? prefs;
  var _visible = true;
  int delayTime = 3;
  AnimationController? animationController;
  Animation<double>? animation;
  String device = "";
  var startAnm = false;
  final mc = GetStorage();
  Size size = Size.zero;
  AnimationController? _controller;
  StaggeredRaindropAnimation? _animation;

  bool _requireConsent = true;
  bool isFirst = true;
  NetworkManager nmt = Get.put(NetworkManager());
  SettingController sc = Get.put(SettingController());
  startTime() async {
    if (!nmt.isUpdate.value) {
      var _duration = new Duration(seconds: delayTime);
      return new Timer(_duration, navigationPage);
    }
  }

  checkNetwork() async {
    // var ipServer = (sc.mc.read(Constant.ipServer) != null)
    //     ? sc.mc.read(Constant.ipServer)
    //     : "";
    // if (ipServer == null || ipServer == "") {
    //   // Get.to(SettingPage());
    //   Get.offAllNamed("/setting");
    // } else {
    //   try {
    //     print("StartTime");
    //     final result = await InternetAddress.lookup(ipServer);
    //     if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
    //       await startTime();
    //     }
    //   } on SocketException catch (_) {
    //     _neverSatisfied();
    //   }
    // }
    await startTime();
  }

  Future<void> _neverSatisfied() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('เชื่อมต่อ Server ไม่ได้'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('กรุณาตรวจสอบเครือข่าย'),
              ],
            ),
          ),
          actions: <Widget>[
            // FlatButton(
            //   child: Text('ลองใหม่'),
            //   onPressed: () {
            //     Navigator.pop(context);
            //     startTime() async {
            //       var _duration = new Duration(seconds: 3);
            //       return new Timer(_duration, navigationPage);
            //     }
            //
            //     checkNetwork();
            //   },
            // ),
            // FlatButton(
            //   child: Text('ปิด'),
            //   onPressed: () {
            //     SystemNavigator.pop();
            //   },
            // ),
          ],
        );
      },
    );
  }

  void navigationPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isAuth = (prefs.getBool('IsAuth') ?? false);

    var ipServer = (prefs.getString(Constant.ipServer)!=null )?prefs.getString(Constant.ipServer):"";
    // Get.snackbar("ไม่สามารถเชื่อมต่อ Server ได้ ", ipServer!+"--");
    Get.snackbar("ipServer:::"+ipServer!,"");
    if (ipServer == null || ipServer == "") {
      // Get.to(SettingPage());
      Get.offAllNamed("/setting");
    }else {

      if (isAuth) {
        Get.offAllNamed("/HomePage");
        // Navigator.of(context).pushReplacementNamed(HOME_SCREEN);
      } else {
        Get.offAllNamed("/Auth");
        // Navigator.of(context).pushReplacementNamed(AUTH_SCREEN);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _animation = StaggeredRaindropAnimation(_controller!);
    _controller!.forward();

    _controller!.addListener(() {
      // setState(() {});
    });
    getPref();
    checkNetwork();
    // _checkUpdate();
  }

  @override
  void didChangeDependencies() {
    setState(() {
      size = MediaQuery.of(context).size;
    });
    super.didChangeDependencies();
  }

  getPref() async {
    prefs = await SharedPreferences.getInstance();

    isFirst = prefs!.getBool("isFirst") ?? true;
  }

  @override
  void dispose() {
    super.dispose();
    _controller!.dispose();
  }

  checkAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    startTime();
  }

  autoAuth(
      String aPIUrl, String _mobileno, String _ids, String iSVersion) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var credentials = {
      "username": '',
      "password": '',
    };
    var response = await post(Uri.parse(aPIUrl + '/api/v1/mparent/auth'),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded"
        },
        body: credentials,
        encoding: Encoding.getByName("utf-8"));

    if (response.statusCode == 200) {
      var resp = json.decode(response.body);
      // print(resp);
      prefs.setBool('IsAuth', true);
      prefs.setString('ApiVersion', iSVersion);

      prefs.setString('apiUrl', "/api/v1/mparent");
      prefs.setString('token', resp['token']);
      prefs.setString('PersonNo', resp['user']['ParentNo'].toString());
      prefs.setString('ParentName', resp['user']['ParentName']);
      prefs.setString('ParentPhoto', resp['user']['ParentPhoto']);
      prefs.setInt('AllowAddStd', 0);

      startTime();
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                stops: [0.1, 0.5],
                colors: [
                  Colors.red,
                  Colors.pink,
                ],
              ),
            ),
            child: Stack(fit: StackFit.expand, children: [
              Positioned(
                  top: _animation!.dropPosition.value * size.height,
                  left: size.width / 2 - _animation!.dropSize.value / 2,
                  child: SizedBox(
                      width: _animation!.dropSize.value,
                      height: _animation!.dropSize.value,
                      child: CustomPaint(
                        painter: DropPainter(),
                      ))),
              new Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.only(bottom: 30.0),
                      child: Text(
                        "Progressive Network Consult Co.,Ltd",
                        style: GoogleFonts.maitree(color: Colors.white),
                      )),
                ],
              ),
              Opacity(
                opacity: 1 - _animation!.textOpacity.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // new Image.asset(
                    //   'assets/images/icon.png',
                    //   width: 100,
                    //   height: 100,
                    // ),
                    SizedBox(
                      height: 60,
                    ),
                    ColorLoader(),
                    // Lottie.asset("assets/images/layer.json")
                  ],
                ),
              ),
            ])));
  }

// Future<void> initPlatformState() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
//   OneSignal.shared.setRequiresUserPrivacyConsent(true);
//   var settings = {
//     OSiOSSettings.autoPrompt: false,
//     OSiOSSettings.promptBeforeOpeningPushUrl: true
//   };
//
//   OneSignal.shared.setPermissionObserver((OSPermissionStateChanges changes) {
//     // print("PERMISSION STATE CHANGED: ${changes.jsonRepresentation()}");
//   });
//
//   OneSignal.shared.setEmailSubscriptionObserver(
//           (OSEmailSubscriptionStateChanges changes) {});
//
//   // NOTE: Replace with your own app ID from https://www.onesignal.com
//   await OneSignal.shared
//       .init("249480e8-550d-4d64-ad29-0a90bcc36d49", iOSSettings: settings);
//
//   OneSignal.shared
//       .setInFocusDisplayType(OSNotificationDisplayType.notification);
//
//   bool requiresConsent = await OneSignal.shared.requiresUserPrivacyConsent();
//   await OneSignal.shared.consentGranted(true);
//   var status = await OneSignal.shared.getPermissionSubscriptionState();
//
//   prefs.setString("OneSignalID", status.subscriptionStatus.userId);
//   // checkAuth();
// }

}

class AppAdvItem {
  final String startDate;
  final String endDate;
  final String image;
  final String link;
  final String isMantanance;

  AppAdvItem(
      this.startDate, this.endDate, this.image, this.link, this.isMantanance);
}

class ImageDialog extends StatelessWidget {
  final AppAdvItem? appAdvItem;
  ImageDialog({Key? key, @required this.appAdvItem}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.all(0.0),
        content: SingleChildScrollView(
            child: Column(children: [
              Container(child: Image.network(appAdvItem!.image, fit: BoxFit.fill)),
              Center(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // FlatButton(
                        //   child: Text('ปิด', style: TextStyle(color: Colors.white)),
                        //   onPressed: () {
                        //     if (appAdvItem!.isMantanance == '1') {
                        //       SystemChannels.platform
                        //           .invokeMethod('SystemNavigator.pop');
                        //     } else {
                        //       Navigator.pop(context);
                        //     }
                        //   },
                        // ),
                      ]))
            ])));
  }
}

class StaggeredRaindropAnimation {
  StaggeredRaindropAnimation(this.controller)
      : dropSize = Tween<double>(begin: 0, end: maximumDropSize).animate(
    CurvedAnimation(
      parent: controller,
      curve: Interval(0.0, 0.2, curve: Curves.easeIn),
    ),
  ),
        dropPosition =
        Tween<double>(begin: 0, end: maximumRelativeDropY).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(0.2, 0.5, curve: Curves.easeIn),
          ),
        ),
        holeSize = Tween<double>(begin: 0, end: maximumHoleSize).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(0.5, 1.0, curve: Curves.easeIn),
          ),
        ),
        dropVisible = Tween<bool>(begin: true, end: false).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(0.5, 0.5),
          ),
        ),
        textOpacity = Tween<double>(begin: 1, end: 0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(0.5, 0.7, curve: Curves.easeOut),
          ),
        );

  final AnimationController controller;

  final Animation<double> dropSize;
  final Animation<double> dropPosition;
  final Animation<bool> dropVisible;
  final Animation<double> holeSize;
  final Animation<double> textOpacity;

  static final double maximumDropSize = 20;
  static final double maximumRelativeDropY = 0.4;
  static final double maximumHoleSize = 10;
}

class DropPainter extends CustomPainter {
  DropPainter({this.visible = true});

  bool visible;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) {
      return;
    }

    Path path = new Path();
    path.moveTo(size.width / 2, 0);
    path.quadraticBezierTo(0, size.height * 0.8, size.width / 2, size.height);
    path.quadraticBezierTo(size.width, size.height * 0.8, size.width / 2, 0);
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
