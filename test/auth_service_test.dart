import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mispos/services/auth_service.dart';

void main() {
  const ip = '192.168.50.250:8080';
  final options = RequestOptions(path: '/api/v1/Auth');

  DioError responseError(int status, [dynamic data]) => DioError(
        requestOptions: options,
        type: DioErrorType.response,
        response:
            Response(requestOptions: options, statusCode: status, data: data),
      );

  test('รหัสผิด ใช้ข้อความจาก server ไม่ต้องไปแก้ IP', () {
    final r = AuthService.describeLoginError(
        responseError(401, {'error': 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง'}), ip);
    expect(r.ok, isFalse);
    expect(r.message, 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
    expect(r.serverProblem, isFalse);
  });

  test('มีชื่อผู้ใช้แต่รหัสผ่านผิด server ตอบ 400 ก็ต้องบอกว่ารหัสผิด', () {
    final r = AuthService.describeLoginError(
        responseError(400, {
          'error': 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง',
          'data': {'UserNo': 1},
        }),
        ip);
    expect(r.message, 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
    expect(r.serverProblem, isFalse);
  });

  test('รหัสผิดแต่ server ไม่ส่งข้อความมา ใช้ข้อความของแอป', () {
    final r = AuthService.describeLoginError(responseError(401), ip);
    expect(r.message, 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
  });

  test('ไม่ได้กรอก', () {
    final r = AuthService.describeLoginError(responseError(422), ip);
    expect(r.message, 'กรุณากรอกชื่อผู้ใช้และรหัสผ่าน');
    expect(r.serverProblem, isFalse);
  });

  test('server ตอบ status อื่น บอกเลข status และให้ไปเช็ค IP', () {
    final r = AuthService.describeLoginError(responseError(404), ip);
    expect(r.message, contains('status: 404'));
    expect(r.message, contains(ip));
    expect(r.serverProblem, isTrue);
  });

  test('หมดเวลา กับต่อไม่ติด บอกว่าติดต่อ server ไม่ได้ พร้อม IP', () {
    final timeout = AuthService.describeLoginError(
        DioError(requestOptions: options, type: DioErrorType.connectTimeout),
        ip);
    expect(timeout.message, startsWith('หมดเวลาเชื่อมต่อ Server ($ip)'));
    expect(timeout.serverProblem, isTrue);

    final refused = AuthService.describeLoginError(
        DioError(requestOptions: options, type: DioErrorType.other), ip);
    expect(refused.message, startsWith('ติดต่อ Server ไม่ได้ ($ip)'));
    expect(refused.serverProblem, isTrue);
  });
}
