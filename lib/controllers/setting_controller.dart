import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mispos/services/sound_service.dart';
import 'package:mispos/utils/constants.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

  /// สถานะของ server ที่บันทึกไว้ตอนนี้ ใช้แสดงในหน้าตั้งค่า
  /// null = ยังไม่ได้ตั้งค่า หรือยังไม่ได้เช็ค
  RxnBool serverReachable = RxnBool();
  Rx<bool> isRefreshingStatus = false.obs;

  Rx<String> appVersion = ''.obs;
  Rx<String> appBuildNumber = ''.obs;

  final mc = GetStorage();
  @override
  void onInit() {
    super.onInit();
    print("Init SettingController");
    loadSetting();
    _loadAppVersion();
  }

  /// โหลดค่าที่บันทึกไว้มาแสดง หน้าตั้งค่าจะได้เห็นค่าปัจจุบัน ไม่ใช่ช่องว่าง
  void loadSetting() {
    ipServer.value = mc.read(Constant.ipServer) ?? '';
    posID.value = mc.read(Constant.posNo) ?? '';
    saleOffline.value = mc.read(Constant.saleOffline) ?? false;
    soundEnabled.value = SoundService.enabled;
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    appVersion.value = info.version;
    appBuildNumber.value = info.buildNumber;
  }

  /// รหัสเครื่องที่พิมพ์ลงบิล
  String posCodeFor(String id) => "TNK00$id";

  /// เช็คว่าเชื่อมต่อ server ที่ [ip] ได้หรือไม่ ข้อความผลลัพธ์อยู่ใน [connectionMessage]
  /// return true ถ้าเชื่อมต่อได้, false ถ้าเชื่อมต่อไม่ได้
  Future<bool> checkServerConnection(String ip) async {
    if (ip.trim().isEmpty) {
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
      final url = "http://${ip.trim()}/api/${Constant.apiUrl}/pingServer";
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

  /// เช็ค server ที่บันทึกไว้ตอนนี้ เพื่อแสดงสถานะในแถว IP Server
  Future<void> refreshServerStatus() async {
    if (ipServer.value.isEmpty) {
      serverReachable.value = null;
      return;
    }
    isRefreshingStatus.value = true;
    serverReachable.value = await checkServerConnection(ipServer.value);
    isRefreshingStatus.value = false;
  }

  /// บันทึก IP Server และรหัสเครื่อง ผู้เรียกต้องเช็คการเชื่อมต่อผ่านก่อน
  Future<void> saveServerSetting(String ip, String id) async {
    ipServer.value = ip;
    posID.value = id;
    await setUpSetting();
  }

  setUpSetting() async {
    mc.write(Constant.ipServer, ipServer.value);
    mc.write(Constant.posNo, posID.value);
    mc.write(Constant.POS_CODE, posCodeFor(posID.value));
    mc.write(Constant.saleOffline, saleOffline.value);

    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString(Constant.ipServer, ipServer.value);
    prefs.setString(Constant.posNo, posID.value);
    prefs.setString(Constant.POS_CODE, posCodeFor(posID.value));
    prefs.setBool(Constant.saleOffline, saleOffline.value);
    print("Save Setting");
    print("ipServer: ${ipServer.value}");
    print("posID: ${posID.value}");
    print("POS_CODE: ${posCodeFor(posID.value)}");
    print("saleOffline: ${saleOffline.value}");
  }

  /// บันทึกทันทีที่สลับ เหมือนสวิตช์เสียง ไม่ต้องกรอก IP ใหม่หรือรอเช็ค server
  Future<void> setSaleOffline(bool value) async {
    saleOffline.value = value;
    mc.write(Constant.saleOffline, value);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(Constant.saleOffline, value);
  }

  /// บันทึกทันทีที่สลับ ไม่ผ่าน setUpSetting()
  /// เพราะปุ่มบันทึกต้องกรอก IP/รหัสเครื่องใหม่และต้องต่อ server ได้ ซึ่งเกินจำเป็นแค่จะปิดเสียง
  void setSoundEnabled(bool value) {
    soundEnabled.value = value;
    SoundService.enabled = value;
  }

  /// เล่นเสียงสำเร็จให้ฟังที่หน้าตั้งค่า
  /// preload ก่อนเพราะถ้ายังไม่เคยเข้าหน้าขาย player จะยังไม่ได้โหลดไฟล์
  Future<void> testSound() async {
    final sound = SoundService();
    await sound.preload();
    sound.playSuccess();
  }
}
