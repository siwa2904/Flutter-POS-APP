import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:posflutter/controllers/networkmanager_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mispos/utils/controller_binding.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'routes/routes.dart';
// import 'utils/controller_binding.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();


}

class _AppState extends State<App> {
  DisplayManager displayManager = DisplayManager();
  List<Display?> displays = [];

  /// เปิดหน้าจอลูกค้าบนจอที่สองของเครื่อง
  ///
  /// เลือกจอที่เลขน้อยที่สุดที่ไม่ใช่จอหลัก ไม่ใช่จอสุดท้าย เพราะตอนต่อ AnyDesk อยู่
  /// AnyDesk สร้างจอเสมือนไว้ส่งภาพ ถ้าแอปเปิดตอนนั้นจะเห็นจอนี้ด้วย และได้เลขสูงกว่าจอลูกค้าจริง
  /// ที่ลงทะเบียนตั้งแต่เปิดเครื่อง เดิมเลือกจอสุดท้าย จอลูกค้าเลยไปขึ้นในจอของ AnyDesk แทน
  handleMonitor() async {
    final values = await displayManager.getDisplays() ?? [];
    displays.clear();
    displays.addAll(values);
    print(values.map((d) => "${d.displayId}:${d.name}").toList());

    final secondary = values
        .where((d) => d.displayId != DEFAULT_DISPLAY)
        .toList()
      ..sort((a, b) => a.displayId.compareTo(b.displayId));
    if (secondary.isEmpty) return;

    final displayId = secondary.first.displayId;
    print("displayId");
    print(displayId);
    await displayManager.showSecondaryDisplay(
        displayId: displayId, routerName: "cm_display");
    // await displayManager.transferDataToPresentation("gggg");
  }
  // storgeHandle() async{
  //   await GetStorage.init();
  // }

  @override
  Widget build(BuildContext context) {
    handleMonitor();
    // storgeHandle();
    return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],

        supportedLocales: [
          const Locale('th', 'TH'),
          const Locale('en', 'US'),
        ],
        initialBinding: ControllerBinding(),
        initialRoute: '/',
        getPages: Routes.routes);
  }
}
