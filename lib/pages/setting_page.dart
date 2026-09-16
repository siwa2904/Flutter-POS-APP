import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mispos/check_update.dart';
import 'package:mispos/controllers/setting_controller.dart';

class SettingPage extends StatelessWidget {
  SettingPage({Key? key}) : super(key: key);

  SettingController settingCtrl = Get.put(SettingController());

  final _formKey = GlobalKey<FormState>();
  double _headerHeight = 150;
  int iSVersion = 4;
  bool _isError = false;
  String errorMsg = "";
  double getSmallDiameter(BuildContext context) =>
      MediaQuery.of(context).size.width * 2 / 2;
  double getBiglDiameter(BuildContext context) =>
      MediaQuery.of(context).size.width * 7 / 8;
  _setConfig(BuildContext context) async {
    // แสดง loading dialog ขณะเช็คการเชื่อมต่อ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'กำลังเช็คการเชื่อมต่อ Server...',
              style: GoogleFonts.kanit(fontSize: 18),
            ),
          ],
        ),
      ),
    );

    final isConnected = await settingCtrl.checkServerConnection();

    // ปิด loading dialog
    Navigator.of(context, rootNavigator: true).pop();

    if (isConnected) {
      // เชื่อมต่อได้ → บันทึก setting แล้วไปหน้าต่อไป
      await settingCtrl.setUpSetting();
      Get.offAllNamed("/");
    } else {
      // เชื่อมต่อไม่ได้ → แสดง dialog แจ้งเตือน ไม่ให้ไป login
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Text('เชื่อมต่อ Server ไม่ได้',
                  style: GoogleFonts.kanit(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            settingCtrl.connectionMessage.value,
            style: GoogleFonts.kanit(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('ตกลง',
                  style: GoogleFonts.kanit(fontSize: 16, color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    settingCtrl.getUpSetting();
    final height = MediaQuery.of(context).size.height;
    return Obx(() => Scaffold(
        appBar: AppBar(title: Text("ตั้งค่า", style: GoogleFonts.maitree())),
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
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                              color: Colors.white60),
                          child: Column(children: <Widget>[
                            _emailPasswordWidget(),
                            SizedBox(height: 20),
                            _submitButton(context),
                            SizedBox(height: height * .0085),
                            _update(context),
                            SizedBox(height: height * .055),
                            // ElevatedButton.icon(
                            //   onPressed: () {
                            //     CheckUpdate.check(context);
                            //   },
                            //
                            //   icon: const Icon(
                            //     Icons.system_update_alt_rounded,
                            //     color: Colors.white,
                            //     size: 34,
                            //   ),
                            //
                            //   label: Text(
                            //     "เช็คอัปเดต",
                            //     style: GoogleFonts.maitree(
                            //       fontSize: 22,
                            //       fontWeight: FontWeight.bold,
                            //       color: Colors.white,
                            //     ),
                            //   ),
                            //
                            //   style: ElevatedButton.styleFrom(
                            //     elevation: 8,
                            //     padding: const EdgeInsets.symmetric(
                            //       horizontal: 28,
                            //       vertical: 18,
                            //     ),
                            //
                            //     backgroundColor: Colors.red,
                            //     foregroundColor: Colors.white,
                            //     surfaceTintColor: Colors.red,
                            //
                            //     shadowColor: Colors.red.withOpacity(0.4),
                            //
                            //     shape: RoundedRectangleBorder(
                            //       borderRadius: BorderRadius.circular(18),
                            //     ),
                            //
                            //     textStyle: GoogleFonts.maitree(
                            //       fontSize: 20,
                            //       fontWeight: FontWeight.w600,
                            //     ),
                            //   ),
                            // ),
                          ]),
                        )
                      ]),
                ),
              ),
              // Positioned(top: 40, left: 0, child: _backButton()),
            ],
          ),
        )));
  }

  Widget _logo(context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
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
                  text: 'ตั้งค่าเครื่อง',
                  style: GoogleFonts.maitree(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )),
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
                    'IP Server::' + settingCtrl.ipServer.value,
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
                        settingCtrl.ipServer.value = value;
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
                    "รหัสเครื่อง:: " + settingCtrl.posID.value,
                    style: GoogleFonts.kanit(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
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
                      settingCtrl.posID.value = value;
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
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Checkbox(
                    value: settingCtrl.saleOffline.value,
                    activeColor: Colors.green,
                    onChanged: (newValue) {
                      settingCtrl.saleOffline.value = newValue == true;
                    },
                  ),
                  Text('ขาย Offline'),
                ],
              ),
            )
          ],
        ));
  }



  Widget _submitButton(context) {
    return ElevatedButton.icon(
      onPressed: () {
        _setConfig(context);
      },

      icon: const Icon(
        Icons.save_rounded,
        size: 28,
        color: Colors.white,
      ),

      label: Text(
        "บันทึก",
        style: GoogleFonts.maitree(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      style: ElevatedButton.styleFrom(
        elevation: 5,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,

        minimumSize: const Size(double.infinity, 60),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _update(context) {
    return ElevatedButton.icon(
      onPressed: () {
        CheckUpdate.check(context, isManual: true);
      },

      icon: const Icon(
        Icons.system_update_alt_rounded,
        size: 28,
        color: Colors.white,
      ),

      label: Text(
        "เช็คอัพเดท",
        style: GoogleFonts.maitree(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      style: ElevatedButton.styleFrom(
        elevation: 5,
        backgroundColor: const Color(0xFFFF4B4B),
        foregroundColor: Colors.white,

        minimumSize: const Size(double.infinity, 60),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
