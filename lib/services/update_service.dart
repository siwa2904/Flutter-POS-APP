import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:mispos/utils/constants.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ข้อมูลจาก update.json บน server
///
/// ```json
/// {"version": "1.1.7", "build": 6910001, "min_build": 6909001,
///  "apk_url": "http://.../app-release.apk", "sha256": "...", "message": "..."}
/// ```
/// `version` ต้องเป็นชื่อเวอร์ชันล้วน เพราะแอป 1.1.6 ลงไปยังเทียบ field นี้แบบข้อความตรงกัน
/// ถ้าไม่มี `build` จะอ่านเลขหลัง `+` ใน `version` แทน (รูปแบบ "1.1.6+6909001" แบบเดิม)
class UpdateInfo {
  UpdateInfo({
    required this.version,
    required this.build,
    required this.minBuild,
    required this.force,
    required this.apkUrl,
    required this.sha256,
    required this.message,
  });

  final String version;
  final int? build;
  final int? minBuild;
  final bool force;
  final String apkUrl;
  final String? sha256;
  final String message;

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    final rawVersion = (json['version'] ?? '').toString().trim();
    final plus = rawVersion.indexOf('+');
    final sha = json['sha256']?.toString().trim().toLowerCase();
    return UpdateInfo(
      version: plus >= 0 ? rawVersion.substring(0, plus) : rawVersion,
      build: _toInt(json['build']) ??
          (plus >= 0 ? int.tryParse(rawVersion.substring(plus + 1)) : null),
      minBuild: _toInt(json['min_build']),
      force: json['force'] == true,
      apkUrl: (json['apk_url'] ?? '').toString().trim(),
      sha256: (sha == null || sha.isEmpty) ? null : sha,
      message: (json['message'] ?? '').toString(),
    );
  }

  /// ตัดสินด้วยเลข build เพราะเป็นเลขเดียวกับที่ Android ใช้ตัดสินว่าติดตั้งทับได้ไหม
  /// ไม่มีเลข build ค่อยเทียบชื่อเวอร์ชันทีละส่วน
  bool isNewerThan(String currentVersion, int currentBuild) {
    if (build != null) return build! > currentBuild;
    return compareVersionNames(version, currentVersion) > 0;
  }

  /// เครื่องนี้ต้องอัปเดตก่อนใช้งานต่อหรือไม่
  /// มี `min_build` ให้ตัดสินจากมันอย่างเดียว ส่วน `force` มีไว้ให้แอป 1.1.6 ลงไปที่ไม่รู้จัก `min_build`
  /// ถ้าเอา `force` มาคิดด้วย ใส่ไว้บังคับเครื่องเก่าเมื่อไหร่ เครื่องที่ใหม่กว่า `min_build` จะโดนบังคับไปด้วย
  bool isRequiredFor(int currentBuild) =>
      minBuild != null ? currentBuild < minBuild! : force;

  String get label => build == null ? version : '$version · build $build';

  static int? _toInt(dynamic value) =>
      value == null ? null : int.tryParse(value.toString().trim());
}

/// เทียบ "1.1.10" กับ "1.1.9" เป็นตัวเลขทีละส่วน ไม่ใช่เทียบแบบข้อความ
int compareVersionNames(String a, String b) {
  final pa = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final pb = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  for (var i = 0; i < pa.length || i < pb.length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

enum UpdateCheckStatus { available, upToDate, failed }

class UpdateCheckResult {
  UpdateCheckResult(this.status,
      {this.info,
      this.currentVersion = '',
      this.currentBuild = 0,
      this.error = ''});

  final UpdateCheckStatus status;
  final UpdateInfo? info;
  final String currentVersion;
  final int currentBuild;
  final String error;

  String get currentLabel => '$currentVersion · build $currentBuild';
}

/// ข้อผิดพลาดที่มีข้อความภาษาไทยพร้อมแสดงให้แคชเชียร์อ่าน
class UpdateException implements Exception {
  UpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UpdateService {
  static const _apkFileName = 'update.apk';

  /// ไม่มีข้อมูลเข้ามานานเท่านี้ถือว่าดาวน์โหลดค้าง
  /// ไม่จำกัดเวลารวม เพราะ APK ขนาดหลายสิบ MB บน Wi-Fi ช้าอาจใช้เวลานานจริง
  static const stallTimeout = Duration(seconds: 30);

  static Future<UpdateCheckResult> check() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

    UpdateCheckResult failed(String error) => UpdateCheckResult(
        UpdateCheckStatus.failed,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
        error: error);

    final prefs = await SharedPreferences.getInstance();
    final ipServer = prefs.getString(Constant.ipServer);
    if (ipServer == null || ipServer.isEmpty) {
      return failed('ยังไม่ได้ตั้งค่า IP Server');
    }

    final String body;
    try {
      // plain: ได้ String เสมอ ไม่ว่า server จะส่ง Content-Type มาเป็นอะไร
      final response = await Dio(BaseOptions(
        connectTimeout: 5000,
        receiveTimeout: 5000,
        responseType: ResponseType.plain,
      )).get<String>("http://$ipServer/api/update.json");
      body = response.data ?? '';
    } on DioError catch (e) {
      print("UpdateService.check: $e");
      return failed(describeCheckError(e));
    }

    final UpdateInfo info;
    try {
      info = UpdateInfo.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } catch (e) {
      print("UpdateService.check: bad update.json => $e");
      return failed('ไฟล์ update.json บน Server รูปแบบไม่ถูกต้อง');
    }
    if (info.version.isEmpty || info.apkUrl.isEmpty) {
      return failed('ไฟล์ update.json บน Server ข้อมูลไม่ครบ');
    }

    if (!info.isNewerThan(currentVersion, currentBuild)) {
      await deleteDownloadedApk();
      return UpdateCheckResult(UpdateCheckStatus.upToDate,
          info: info, currentVersion: currentVersion, currentBuild: currentBuild);
    }
    return UpdateCheckResult(UpdateCheckStatus.available,
        info: info, currentVersion: currentVersion, currentBuild: currentBuild);
  }

  /// แยกให้ออกว่าต่อ server ไม่ได้ หรือต่อได้แต่ server ตอบ error
  /// สองกรณีนี้แก้คนละที่ ถ้ารวมเป็นข้อความเดียว คนดูแลจะไปไล่เช็คเครือข่ายทั้งที่แค่ยังไม่ได้อัปโหลดไฟล์
  static String describeCheckError(DioError e) {
    if (e.type == DioErrorType.response) {
      final status = e.response?.statusCode;
      if (status == 404) {
        return 'ไม่พบไฟล์ update.json บน Server (/api/update.json)';
      }
      return 'Server ตอบกลับผิดปกติ (status: $status)';
    }
    return 'ติดต่อ Server เพื่อเช็คอัปเดตไม่ได้';
  }

  /// ขอสิทธิ์ "ติดตั้งแอปที่ไม่รู้จัก" ก่อนเริ่มดาวน์โหลด จะได้ไม่โหลดไฟล์มาแล้วติดตั้งไม่ได้
  /// Android 8 ขึ้นไปจะพาไปหน้าตั้งค่าให้เปิดสวิตช์ แล้วกลับมาที่แอป
  static Future<bool> ensureInstallPermission() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.requestInstallPackages.isGranted) return true;
    final status = await Permission.requestInstallPackages.request();
    return status.isGranted;
  }

  static Future<File> _apkFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_apkFileName');
  }

  static Future<void> deleteDownloadedApk() async {
    try {
      final file = await _apkFile();
      if (await file.exists()) await file.delete();
    } catch (e) {
      print("UpdateService.deleteDownloadedApk: $e");
    }
  }

  /// ดาวน์โหลด APK แล้วตรวจไฟล์ก่อนคืนให้ติดตั้ง
  /// ยกเลิกด้วย [cancelToken] ได้ ถ้าไม่มีข้อมูลเข้ามาเกิน [stallTimeout] จะยกเลิกเอง
  static Future<File> download(
    UpdateInfo info, {
    required CancelToken cancelToken,
    void Function(int received, int total)? onProgress,
  }) async {
    final file = await _apkFile();
    await deleteDownloadedApk();

    var lastDataAt = DateTime.now();
    var stalled = false;
    var total = -1;
    final watchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      if (DateTime.now().difference(lastDataAt) > stallTimeout) {
        stalled = true;
        cancelToken.cancel('stalled');
      }
    });

    try {
      await Dio(BaseOptions(connectTimeout: 10000)).download(
        info.apkUrl,
        file.path,
        cancelToken: cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, t) {
          lastDataAt = DateTime.now();
          total = t;
          onProgress?.call(received, t);
        },
      );
    } on DioError catch (e) {
      if (CancelToken.isCancel(e)) {
        throw UpdateException(stalled
            ? 'ดาวน์โหลดค้าง ไม่มีข้อมูลเข้ามาเกิน ${stallTimeout.inSeconds} วินาที'
            : 'ยกเลิกการดาวน์โหลดแล้ว');
      }
      if (e.type == DioErrorType.response) {
        throw UpdateException(
            'Server ตอบกลับผิดปกติ (status: ${e.response?.statusCode}) ตรวจสอบ apk_url');
      }
      throw UpdateException('ดาวน์โหลดไม่สำเร็จ ตรวจสอบเครือข่ายแล้วลองใหม่');
    } finally {
      watchdog.cancel();
    }

    await _verify(file, info, expectedLength: total);
    return file;
  }

  static Future<void> _verify(File file, UpdateInfo info,
      {required int expectedLength}) async {
    final length = await file.length();
    if (expectedLength > 0 && length != expectedLength) {
      await deleteDownloadedApk();
      throw UpdateException(
          'ไฟล์ดาวน์โหลดมาไม่ครบ ($length จาก $expectedLength ไบต์) ลองใหม่อีกครั้ง');
    }

    // APK เป็นไฟล์ zip ขึ้นต้นด้วย "PK" ถ้าไม่ใช่ แปลว่าได้หน้า error หรือไฟล์อื่นมาแทน
    final head = await file.openRead(0, 2).first;
    if (head.length < 2 || head[0] != 0x50 || head[1] != 0x4B) {
      await deleteDownloadedApk();
      throw UpdateException('ไฟล์ที่ได้ไม่ใช่ APK ตรวจสอบ apk_url ใน update.json');
    }

    if (info.sha256 != null) {
      final digest = await sha256.bind(file.openRead()).first;
      if (digest.toString() != info.sha256) {
        await deleteDownloadedApk();
        throw UpdateException(
            'ไฟล์ไม่ตรงกับ sha256 ใน update.json อาจเสียระหว่างโหลดหรืออัปโหลดผิดตัว');
      }
    }
  }

  /// เปิดตัวติดตั้งของ Android การอัปเดตจริงเกิดหลังผู้ใช้กด "ติดตั้ง"
  static Future<void> install(File file) async {
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw UpdateException('เปิดตัวติดตั้งไม่ได้: ${result.message}');
    }
  }
}
