
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mispos/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class returnAuth {
  bool? state;
  String? message;
}

class SettingController extends GetxController {
  Rx<String> ipServer = ''.obs;
  Rx<String> posID = ''.obs;
  Rx<bool> saleOffline = false.obs;
  final mc = GetStorage();
  @override
  void onInit() {
    // getSchoolAll();
    super.onInit();
    print("Init SettingController");
    // ipServer.value =
    //     (mc.read(Constant.ipServer) != null) ? mc.read(Constant.ipServer) : "";
    // posID.value =
    //     (mc.read(Constant.posNo) != null) ? mc.read(Constant.posNo) : "";
  }

  setUpSetting() async {
    mc.write(Constant.ipServer, ipServer.value);
    mc.write(Constant.posNo, posID.value);
    mc.write(Constant.POS_CODE, "TNK00${posID.value}");
    mc.write(Constant.saleOffline, saleOffline.value);

    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString(Constant.ipServer, ipServer.value);
    prefs.setString(Constant.posNo, posID.value);
    prefs.setString(Constant.POS_CODE, "TNK00${posID.value}");
    prefs.setBool(Constant.saleOffline, saleOffline.value);


  }

  getUpSetting() async {
    // ipServer.value =
    //     (mc.read(Constant.ipServer) != null) ? mc.read(Constant.ipServer) : "";
    // posID.value =
    //     (mc.read(Constant.posNo) != null) ? mc.read(Constant.posNo) : "";
  }
}
