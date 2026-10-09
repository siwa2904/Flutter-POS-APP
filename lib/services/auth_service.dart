import 'package:dio/dio.dart' as DioService;
import 'package:mispos/models/user_model.dart';
import 'package:mispos/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ผล login พร้อมข้อความที่แสดงให้แคชเชียร์อ่านได้เลย
class AuthResult {
  AuthResult.success()
      : ok = true,
        message = '',
        serverProblem = false;

  AuthResult.fail(this.message, {this.serverProblem = false}) : ok = false;

  final bool ok;
  final String message;

  /// ปัญหาอยู่ที่การติดต่อ server ไม่ใช่รหัสผ่าน หน้า login จะพาไปแก้ IP Server ได้
  final bool serverProblem;
}

class AuthService {
  Future<AuthResult> login(
    UserModel user,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final ipServer = prefs.getString(Constant.ipServer) ?? '';
    if (ipServer.isEmpty) {
      return AuthResult.fail('ยังไม่ได้ตั้งค่า IP Server', serverProblem: true);
    }
    final authURL = "http://$ipServer/api/${Constant.apiUrl}";
    print("AuthURL: $authURL");

    // ไม่ตั้ง timeout ไว้ ตอน server ล่มจะหมุนค้างหลายนาทีกว่าจะรู้ผล
    final dio = DioService.Dio(DioService.BaseOptions(
      connectTimeout: 10000,
      receiveTimeout: 15000,
    ));

    final DioService.Response response;
    try {
      response = await dio.post('$authURL/Auth', data: {
        "username": user.username,
        "password": user.password,
      });
    } on DioService.DioError catch (e) {
      print("AuthService.login: $e");
      return describeLoginError(e, ipServer);
    }

    final resp = response.data;
    if (resp is! Map || (resp['Token'] ?? '').toString().isEmpty) {
      print("AuthService.login: unexpected response => $resp");
      return AuthResult.fail('Server ตอบกลับข้อมูลไม่ครบ ติดต่อผู้ดูแลระบบ');
    }

    await prefs.setString(Constant.ApiVersion, '');
    await prefs.setString(Constant.token, resp['Token'].toString());
    await prefs.setString(Constant.AllowAddStd, '');
    await _save(prefs, Constant.UserNo, resp['UserNo']);
    await _save(prefs, Constant.Name, resp['Name']);
    await _save(prefs, Constant.ImageUrl, resp['ImageUrl']);
    await _save(prefs, Constant.ShopID, resp['ShopID']);
    await _save(prefs, Constant.ShopName, resp['ShopName']);
    await _save(prefs, Constant.ShopLogo, resp['ShopLogo']);
    // ตั้งเป็นอย่างสุดท้าย ถ้าตั้งก่อนแล้วบันทึกช่องอื่นพัง
    // หน้าจอจะบอกว่า login ไม่ผ่าน แต่เปิดแอปใหม่กลับข้ามหน้า login ไปทั้งที่ข้อมูลร้านไม่ครบ
    await prefs.setBool(Constant.IsAuth, true);
    return AuthResult.success();
  }

  /// แปลง error จากการ login เป็นข้อความที่บอกว่าต้องแก้ตรงไหน
  /// แยกรหัสผิดออกจากติดต่อ server ไม่ได้ เพราะคนละวิธีแก้
  static AuthResult describeLoginError(
      DioService.DioError e, String ipServer) {
    switch (e.type) {
      case DioService.DioErrorType.response:
        final status = e.response?.statusCode;
        // server ตอบ 401 เมื่อไม่พบชื่อผู้ใช้ และ 400 เมื่อมีชื่อผู้ใช้แต่รหัสผ่านไม่ตรง
        if (status == 400 || status == 401) {
          final data = e.response?.data;
          final serverMsg = data is Map ? data['error']?.toString() : null;
          return AuthResult.fail(
              serverMsg ?? 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
        }
        if (status == 422) {
          return AuthResult.fail('กรุณากรอกชื่อผู้ใช้และรหัสผ่าน');
        }
        // status อื่นมักเป็น IP ชี้ไปผิดเครื่องหรือ server มีปัญหา
        return AuthResult.fail(
            'Server ตอบกลับผิดปกติ (status: $status)\nตรวจสอบ IP Server ($ipServer)',
            serverProblem: true);
      case DioService.DioErrorType.connectTimeout:
      case DioService.DioErrorType.sendTimeout:
      case DioService.DioErrorType.receiveTimeout:
        return AuthResult.fail(
            'หมดเวลาเชื่อมต่อ Server ($ipServer)\nตรวจสอบเครือข่าย หรือ IP Server',
            serverProblem: true);
      default:
        return AuthResult.fail(
            'ติดต่อ Server ไม่ได้ ($ipServer)\nตรวจสอบเครือข่าย หรือ IP Server',
            serverProblem: true);
    }
  }

  /// ช่องที่ server ไม่ส่งมาให้ลบค่าเก่าทิ้ง ไม่งั้นจะค้างข้อมูลของคนที่ login ก่อนหน้า
  static Future<void> _save(
      SharedPreferences prefs, String key, dynamic value) async {
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value.toString());
    }
  }

  Future<bool> isLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constant.IS_LOGIN_PREF) ?? false;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(Constant.IS_LOGIN_PREF);
  }
}
