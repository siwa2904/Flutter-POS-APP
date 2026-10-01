
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mispos/services/sound_service.dart';
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
  Rx<bool> soundEnabled = true.obs;
  Rx<bool> isCheckingConnection = false.obs;
  Rx<String> connectionMessage = ''.obs;
  final mc = GetStorage();
  @override
  void onInit() {
    super.onInit();
    print("Init SettingController");
    soundEnabled.value = SoundService.enabled;
  }

  /// บันทึกทันทีที่สลับ ไม่ผ่าน setUpSetting()
  /// เพราะปุ่มบันทึกต้องกรอก IP/รหัสเครื่องใหม่และต้องต่อ server ได้ ซึ่งเกินจำเป็นแค่จะปิดเสียง
  void setSoundEnabled(bool value) {
    soundEnabled.value = value;
    SoundService.enabled = value;
  }

  /// เช็คว่าเชื่อมต่อ server ได้หรือไม่ ก่อนจะบันทึก
  /// return true ถ้าเชื่อมต่อได้, false ถ้าเชื่อมต่อไม่ได้
  Future<bool> checkServerConnection() async {
    if (ipServer.value.trim().isEmpty) {
      connectionMessage.value = 'กรุณากรอก IP Server';
      return false;
    }

    isCheckingConnection.value = true;
    connectionMessage.value = '';

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: 5000,
        receiveTimeout: 5000,
      ));
      final url =
          "http://${ipServer.value.trim()}/api/${Constant.apiUrl}/pingServer";
      print("Checking connection to: $url");
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        connectionMessage.value = 'เชื่อมต่อ Server สำเร็จ';
        isCheckingConnection.value = false;
        return true;
      } else {
        connectionMessage.value =
            'Server ตอบกลับผิดปกติ (status: ${response.statusCode})';
        isCheckingConnection.value = false;
        return false;
      }
    } on DioError catch (e) {
      if (e.type == DioErrorType.connectTimeout ||
          e.type == DioErrorType.receiveTimeout) {
        connectionMessage.value = 'หมดเวลาเชื่อมต่อ — ตรวจสอบ IP Server';
      } else if (e.type == DioErrorType.other) {
        connectionMessage.value =
            'ไม่สามารถเชื่อมต่อ Server ได้ — ตรวจสอบ IP และเครือข่าย';
      } else {
        connectionMessage.value = 'เกิดข้อผิดพลาด: ${e.message}';
      }
      isCheckingConnection.value = false;
      return false;
    } catch (e) {
      connectionMessage.value = 'เกิดข้อผิดพลาดที่ไม่คาดคิด: $e';
      isCheckingConnection.value = false;
      return false;
    }
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
    print("Save Setting");
    print("ipServer: ${ipServer.value}");
    print("posID: ${posID.value}");
    print("POS_CODE: TNK00${posID.value}");
    print("saleOffline: ${saleOffline.value}");
  }

  getUpSetting() async {
    // ipServer.value =
    //     (mc.read(Constant.ipServer) != null) ? mc.read(Constant.ipServer) : "";
    // posID.value =
    //     (mc.read(Constant.posNo) != null) ? mc.read(Constant.posNo) : "";
  }
}
