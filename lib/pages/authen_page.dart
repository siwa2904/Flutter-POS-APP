import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mispos/controllers/auth_controller.dart';
import 'package:mispos/utils/circular_progress_loading.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:sunmi_scanner/sunmi_scanner.dart';

class AuthenPage extends StatelessWidget {
  AuthenPage({Key? key}) : super(key: key);

  final authControl = Get.put(AuthController());

  final _formKey = GlobalKey<FormState>();
  double _headerHeight = 150;
  int iSVersion = 4;
  bool _isError = false;
  String errorMsg = "";
  double getSmallDiameter(BuildContext context) =>
      MediaQuery.of(context).size.width * 2 / 2;
  double getBiglDiameter(BuildContext context) =>
      MediaQuery.of(context).size.width * 7 / 8;
  _auth(BuildContext context) async {
    authControl.authFailMsg.value = "";

    var authState = await authControl.authen();
    if (authState.state!) {
      Get.offAllNamed("/HomePage");
    }
  }
rfidReader() async{
  // Check availability
  bool isAvailable = await NfcManager.instance.isAvailable();

// Start Session
  NfcManager.instance.startSession(
    onDiscovered: (NfcTag tag) async {
      // Do something with an NfcTag instance.
    },
  );

// Stop Session
//   NfcManager.instance.stopSession();
}
  void _tagRead() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      print(tag.data);
      NfcManager.instance.stopSession();
    });
  }
  @override
  Widget build(BuildContext context) {
    rfidReader();

    final height = MediaQuery.of(context).size.height;
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
      height: height,
      child: Stack(
        children: <Widget>[
          Positioned(
            right: 0,
            top: -getSmallDiameter(context) / 2,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: getSmallDiameter(context),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [Colors.red, Colors.redAccent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter)),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            // decoration: BoxDecoration(color: Colors.white60),
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 60),
                    _logo(context),
                    // _title(),
                    SizedBox(height: 50),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      width: 500,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          color: Colors.white60),
                      child: Column(children: <Widget>[
                        _emailPasswordWidget(),
                        Obx(() => authControl.authFailMsg.value.isEmpty
                            ? const SizedBox.shrink()
                            : _loginError()),
                        SizedBox(height: 20),
                        _submitButton(context),
                        // _divider(),
                        // _createAccountLabel(),
                        SizedBox(height: height * .055),
                      ]),
                    )
                  ]),
            ),
          ),
          // Positioned(top: 40, left: 0, child: _backButton()),
        ],
      ),
    ));
  }

  Widget _logo(context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      // Container(
      //   margin: EdgeInsets.symmetric(vertical: 1),
      //   // height: MediaQuery.of(context).size.height * .13,
      //   width: MediaQuery.of(context).size.width * .25,
      // ),
      // new Image.asset(
      //   'assets/images/icon.png',
      //   width: 80,
      //   height: 80,
      // ),
      SizedBox(
        height: 60,
      ),
      Container(
          margin: EdgeInsets.only(left: 10, top: 20),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                RichText(
                    text: TextSpan(
                  text: 'เข้าสู่ระบบ',
                  style: GoogleFonts.maitree(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )),
                RichText(
                    text: TextSpan(
                  text: 'MIS POS',
                  style: GoogleFonts.maitree(
                    fontSize: 30,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ))
              ])),
    ]);
  }

  Widget _emailPasswordWidget() {
    return Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ชื่อผู้ใช้',
                    style: GoogleFonts.kanit(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Stack(children: <Widget>[
                    TextFormField(
                      // controller: TextEditingController()..text = _schoolNo,
                      keyboardType: TextInputType.text,

                      decoration: InputDecoration(
                        border: InputBorder.none,
                        fillColor: Color(0xfff3f3f4),
                        filled: true,
                        errorStyle: GoogleFonts.kanit(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.red),
                      ),
                      onChanged: (value) {
                        authControl.userName = value;
                      },
                      // onEditingComplete: authControl.checkSchool(),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'ห้ามเว้นว่าง';
                        }
                        return null;
                      },
                    ),
                  ])
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "รหัสผ่าน",
                    style: GoogleFonts.kanit(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    obscureText: true,
                    obscuringCharacter: "*",
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      fillColor: Color(0xfff3f3f4),
                      filled: true,
                      errorStyle: GoogleFonts.kanit(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.red),
                    ),
                    onChanged: (value) {
                      authControl.userPassword = value;
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'ห้ามเว้นว่าง';
                      }
                      return ((iSVersion != '')) ? null : '';
                    },
                  )
                ],
              ),
            )
          ],
        ));
  }

  /// บอกว่า login ไม่ผ่านเพราะอะไร ถ้าติดต่อ server ไม่ได้ให้ไปแก้ IP Server ได้จากตรงนี้
  /// เดิมหน้า login ไม่มีทางไปหน้าตั้งค่า IP เปลี่ยนเมื่อไหร่แคชเชียร์ติดอยู่หน้านี้
  Widget _loginError() {
    const errorColor = Color(0xFFB71C1C);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: errorColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(authControl.authFailMsg.value,
                    style: GoogleFonts.kanit(fontSize: 17, color: errorColor)),
              ),
            ],
          ),
          if (authControl.authFailIsServerProblem.value)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Get.toNamed("/setting"),
                icon: const Icon(Icons.settings_outlined),
                label: Text("ตั้งค่า IP Server",
                    style: GoogleFonts.kanit(fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _submitButton(context) {
    return ElevatedButton.icon(
      onPressed: () {
        // กดซ้ำระหว่างรอผลจะยิง login ซ้อนกัน
        if (authControl.process.value) return;
        authControl.authFailMsg.value = "";
        if (_formKey.currentState!.validate()) {
          // authControl.authen();
          _auth(context);
          // authen();
        }
      },
      icon: Obx(() => (authControl.process.value)
          ? const CircularProgressIndicator(
              color: Colors.white,
            )
          : const Icon(Icons.add_moderator_outlined)),
      label: Obx(() => (authControl.process.value)
          ? const Text("")
          : const Text("เข้าสู่ระบบ")),
      style: ElevatedButton.styleFrom(
          // fixedSize: Size(200,60),
          padding: EdgeInsets.all(5),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.red,
          textStyle:
              GoogleFonts.maitree(fontSize: 18, fontWeight: FontWeight.w500)),
    );
  }
}
