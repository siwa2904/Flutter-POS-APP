import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mispos/services/update_service.dart';

void main() {
  group('UpdateInfo.fromJson', () {
    test('อ่านเลข build จาก field build', () {
      final info = UpdateInfo.fromJson({
        'version': '1.1.7',
        'build': 6910001,
        'apk_url': 'http://x/app.apk',
      });
      expect(info.version, '1.1.7');
      expect(info.build, 6910001);
    });

    test('รูปแบบเดิม "1.1.6+6909001" แยกชื่อกับเลข build ให้', () {
      final info = UpdateInfo.fromJson({
        'version': '1.1.6+6909001',
        'apk_url': 'http://x/app.apk',
      });
      expect(info.version, '1.1.6');
      expect(info.build, 6909001);
    });

    test('build เป็นข้อความก็อ่านได้', () {
      final info = UpdateInfo.fromJson({'version': '1.1.7', 'build': '6910001'});
      expect(info.build, 6910001);
    });

    test('sha256 ว่างถือว่าไม่มี', () {
      expect(UpdateInfo.fromJson({'version': '1', 'sha256': ''}).sha256, isNull);
      expect(UpdateInfo.fromJson({'version': '1', 'sha256': ' ABC '}).sha256,
          'abc');
    });
  });

  group('isNewerThan', () {
    test('server เวอร์ชันเดียวกันในรูปแบบเดิม ไม่ถือว่ามีอัปเดต', () {
      // เคสที่เคยทำให้ขึ้นหน้าต่างอัปเดตทุกครั้งที่เปิดแอป
      final info = UpdateInfo.fromJson({'version': '1.1.6+6909001'});
      expect(info.isNewerThan('1.1.6', 6909001), isFalse);
    });

    test('build ใหม่กว่าถือว่ามีอัปเดต แม้ชื่อเวอร์ชันเท่าเดิม', () {
      final info = UpdateInfo.fromJson({'version': '1.1.6', 'build': 6909002});
      expect(info.isNewerThan('1.1.6', 6909001), isTrue);
    });

    test('เครื่องใหม่กว่า server ไม่ชวนให้ดาวน์เกรด', () {
      final info = UpdateInfo.fromJson({'version': '1.1.6', 'build': 6909001});
      expect(info.isNewerThan('1.1.7', 6910001), isFalse);
    });

    test('ไม่มีเลข build ใช้ชื่อเวอร์ชันเทียบแบบตัวเลข', () {
      expect(UpdateInfo.fromJson({'version': '1.1.10'}).isNewerThan('1.1.9', 0),
          isTrue);
      expect(UpdateInfo.fromJson({'version': '1.1.6'}).isNewerThan('1.1.6', 0),
          isFalse);
    });
  });

  group('isRequiredFor', () {
    test('ต่ำกว่า min_build ต้องอัปเดต', () {
      final info = UpdateInfo.fromJson({'version': '1.1.7', 'min_build': 6909002});
      expect(info.isRequiredFor(6909001), isTrue);
      expect(info.isRequiredFor(6909002), isFalse);
    });

    test('มี min_build แล้วไม่สน force ที่ใส่ไว้ให้แอปรุ่นเก่า', () {
      final info = UpdateInfo.fromJson(
          {'version': '1.1.7', 'min_build': 6909001, 'force': true});
      expect(info.isRequiredFor(6909001), isFalse);
    });

    test('ไม่มี min_build ใช้ force แบบเดิม', () {
      expect(UpdateInfo.fromJson({'version': '1', 'force': true}).isRequiredFor(1),
          isTrue);
      expect(UpdateInfo.fromJson({'version': '1'}).isRequiredFor(1), isFalse);
    });
  });

  group('describeCheckError', () {
    DioError responseError(int status) {
      final options = RequestOptions(path: '/api/update.json');
      return DioError(
        requestOptions: options,
        type: DioErrorType.response,
        response: Response(requestOptions: options, statusCode: status),
      );
    }

    test('404 บอกว่าไม่มีไฟล์ ไม่ใช่ต่อ server ไม่ได้', () {
      expect(UpdateService.describeCheckError(responseError(404)),
          'ไม่พบไฟล์ update.json บน Server (/api/update.json)');
    });

    test('error อื่นจาก server บอกเลข status', () {
      expect(UpdateService.describeCheckError(responseError(500)),
          'Server ตอบกลับผิดปกติ (status: 500)');
    });

    test('ต่อไม่ติดหรือหมดเวลา ยังบอกว่าติดต่อ server ไม่ได้', () {
      final options = RequestOptions(path: '/api/update.json');
      expect(
          UpdateService.describeCheckError(DioError(
              requestOptions: options, type: DioErrorType.connectTimeout)),
          'ติดต่อ Server เพื่อเช็คอัปเดตไม่ได้');
      expect(
          UpdateService.describeCheckError(
              DioError(requestOptions: options, type: DioErrorType.other)),
          'ติดต่อ Server เพื่อเช็คอัปเดตไม่ได้');
    });
  });

  test('compareVersionNames เทียบทีละส่วนเป็นตัวเลข', () {
    expect(compareVersionNames('1.1.10', '1.1.9'), greaterThan(0));
    expect(compareVersionNames('1.2', '1.2.0'), 0);
    expect(compareVersionNames('1.1.5', '1.1.6'), lessThan(0));
  });
}
