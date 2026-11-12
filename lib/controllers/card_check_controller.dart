import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:presentation_displays/displays_manager.dart';

import '../services/pos_service.dart';
import '../services/sound_service.dart';

enum CardCheckStatus { waiting, loading, found, notFound, error }

/// สิ่งที่หน้าต่างเช็คบัตรแสดงอยู่ สร้างตัวใหม่ทุกครั้งที่เปลี่ยน
/// Obx จะ rebuild เสมอ แม้แตะบัตรสองใบติดกันแล้วได้ผลแบบเดียวกัน
class CardCheckView {
  const CardCheckView(
    this.status, {
    this.seq = 0,
    this.last4 = '',
    this.holder = '',
    this.amount = '',
    this.decimals = '',
    this.isZero = false,
    this.checkedAt = '',
    this.errorTitle = '',
    this.errorDetail = '',
    this.isOffline = false,
    this.clearedPrevious = false,
    this.barcodeWarning = false,
  });

  final CardCheckStatus status;
  final int seq;
  final String last4;
  final String holder;

  /// ยอดแยกเป็นสองส่วน "1,250" กับ ".00" เพราะทศนิยมแสดงตัวเล็กกว่า
  final String amount;
  final String decimals;
  final bool isZero;
  final String checkedAt;
  final String errorTitle;
  final String errorDetail;
  final bool isOffline;

  /// กำลังโหลดบัตรใบใหม่ และเพิ่งล้างผลของใบก่อนทิ้ง
  final bool clearedPrevious;

  /// ยิงบาร์โค้ดสินค้าเข้ามา ผลที่แสดงอยู่ยังถูก แค่ขึ้นแถบเตือน
  final bool barcodeWarning;

  CardCheckView withBarcodeWarning(bool on) => CardCheckView(
        status,
        seq: seq,
        last4: last4,
        holder: holder,
        amount: amount,
        decimals: decimals,
        isZero: isZero,
        checkedAt: checkedAt,
        errorTitle: errorTitle,
        errorDetail: errorDetail,
        isOffline: isOffline,
        clearedPrevious: clearedPrevious,
        barcodeWarning: on,
      );
}

/// เช็คยอดบัตรจากหน้าขาย อ่านอย่างเดียว ไม่ตัดเงินและไม่สร้างบิล
class CardCheckController extends GetxController {
  final view = const CardCheckView(CardCheckStatus.waiting).obs;

  final DisplayManager _display = DisplayManager();
  final SoundService _sound = SoundService();
  final NumberFormat _money = NumberFormat('#,##0.00');

  // แตะหลายใบติดกัน ผลของใบล่าสุดต้องชนะเสมอ
  // คำตอบของใบก่อนที่มาช้า (เน็ตช้า) จะถูกทิ้ง ไม่งั้นจอขึ้นยอดของบัตรผิดใบ
  int _seq = 0;
  bool _hasResult = false;

  void open() {
    _seq++;
    _hasResult = false;
    view.value = CardCheckView(CardCheckStatus.waiting, seq: _seq);
    _showOnCustomerDisplay({'state': 'wait'});
  }

  /// เลขบัตรเริ่มเข้ามา (ก่อนรอ debounce) ล้างชื่อและยอดของคนก่อนออกจากทั้งสองจอทันที
  /// คนถัดไปจะได้ไม่เห็นยอดของคนก่อน และแคชเชียร์รู้ว่าแตะติดแล้ว เพราะตอนเจอบัตรไม่มีเสียง
  void reading(String cardNumber) {
    _seq++;
    _setLoading(cardNumber);
  }

  Future<void> lookup(String cardNumber) async {
    final seq = ++_seq;
    final last4 = _last4(cardNumber);
    _setLoading(cardNumber);

    CardCheckView result;
    Map<String, dynamic> display;
    try {
      final data = await POSService()
          .getCardDetail(cardNumber)
          .timeout(const Duration(seconds: 10));
      print("card check result: $cardNumber");
      if (seq != _seq) return;
      if (data == null) {
        result =
            CardCheckView(CardCheckStatus.notFound, seq: seq, last4: last4);
        display = {'state': 'notFound'};
      } else {
        final value = double.tryParse('${data['Balance']}') ?? 0;
        final holder = '${data['AccountName'] ?? ''}'.trim();
        final text = _money.format(value);
        final dot = text.lastIndexOf('.');
        final amount = text.substring(0, dot);
        final decimals = text.substring(dot);
        final now = DateTime.now();
        result = CardCheckView(
          CardCheckStatus.found,
          seq: seq,
          last4: last4,
          holder: holder.isEmpty ? '-' : holder,
          amount: amount,
          decimals: decimals,
          isZero: value <= 0,
          // มีวินาที แตะใบเดิมซ้ำแล้วเห็นว่าได้ผลใหม่จริง
          checkedAt: DateFormat('HH:mm:ss').format(now),
        );
        display = {
          'state': 'found',
          'name': _firstName(holder),
          'amount': amount,
          'decimals': decimals,
          'zero': value <= 0,
          'last4': last4,
          'checkedAt': DateFormat('HH:mm').format(now),
        };
      }
    } catch (e) {
      if (seq != _seq) return;
      print("card check failed: $e");
      final msg = _describeError(e);
      result = CardCheckView(CardCheckStatus.error,
          seq: seq,
          last4: last4,
          errorTitle: msg[0],
          errorDetail: msg[1],
          isOffline: _isOffline(e));
      display = {'state': 'error'};
    }

    // แถบเตือนบาร์โค้ดที่ยิงมาระหว่างรอ ให้ค้างไว้จนกว่าจะแตะบัตรใบถัดไป
    view.value = result.withBarcodeWarning(view.value.barcodeWarning);
    _hasResult = true;
    if (result.status != CardCheckStatus.found) _sound.playFailed();
    _showOnCustomerDisplay(display);
  }

  /// เลขบัตรอ่านมาไม่ครบ ขึ้นว่าไม่พบบัตรเลย ไม่แยกสถานะ
  void shortRead(String cardNumber) {
    _seq++;
    _hasResult = true;
    view.value = CardCheckView(CardCheckStatus.notFound,
        seq: _seq, last4: _last4(cardNumber));
    _sound.playFailed();
    _showOnCustomerDisplay({'state': 'notFound'});
  }

  /// ยิงบาร์โค้ดสินค้าเข้ามาตอนหน้าต่างเปิด ผลที่แสดงอยู่ยังถูก แค่ขึ้นแถบเตือน
  /// ไม่เปลี่ยน seq ผลของบัตรที่กำลังรอยังใช้ได้ และจอลูกค้าคงไว้ตามเดิม
  void rejectProductBarcode() {
    view.value = view.value.withBarcodeWarning(true);
    _sound.playFailed();
  }

  /// ปิดหน้าต่าง: ทิ้งคำตอบที่ยังค้าง แล้วคืนจอลูกค้าเป็นตะกร้าปัจจุบัน
  void close(Map<String, dynamic> cart) {
    _seq++;
    view.value = CardCheckView(CardCheckStatus.waiting, seq: _seq);
    _display.transferDataToPresentation(cart);
  }

  void _setLoading(String cardNumber) {
    final last4 = _last4(cardNumber);
    view.value = CardCheckView(CardCheckStatus.loading,
        seq: _seq, last4: last4, clearedPrevious: _hasResult);
    _showOnCustomerDisplay({'state': 'loading', 'last4': last4});
  }

  void _showOnCustomerDisplay(Map<String, dynamic> data) {
    _display.transferDataToPresentation({'type': 'cardCheck', ...data});
  }

  String _last4(String cardNumber) => cardNumber.length > 4
      ? cardNumber.substring(cardNumber.length - 4)
      : cardNumber;

  // จอลูกค้าคนในคิวมองเห็น แสดงแค่ชื่อต้น ไม่มีคำนำหน้าและนามสกุล
  // นางสาว ต้องมาก่อน นาง ไม่งั้นตัดเหลือ "สาว..."
  static const _titles = [
    'นางสาว', 'นาง', 'นาย', 'น.ส.', 'ด.ช.', 'ด.ญ.', 'เด็กชาย', 'เด็กหญิง',
    'Mrs.', 'Mr.', 'Ms.', 'Miss'
  ];

  String _firstName(String full) {
    var name = full.trim();
    for (final t in _titles) {
      // ตัดแล้วไม่เหลือชื่อ แปลว่าไม่ใช่คำนำหน้า เก็บไว้ตามเดิม
      if (name.startsWith(t) && name.substring(t.length).trim().length >= 2) {
        name = name.substring(t.length).trim();
        break;
      }
    }
    return name.split(RegExp(r'\s+')).first;
  }

  // ไม่มี status = ไปไม่ถึง server เช่น เน็ตหลุด IP ผิด หรือหมดเวลา
  bool _isOffline(Object e) =>
      !(e is DioError && e.response != null) && e is! FormatException;

  List<String> _describeError(Object e) {
    // มี status แปลว่าถึง server แล้ว เช่น 404 = server ยังไม่มี API นี้, 401 = token หมดอายุ
    if (e is DioError && e.response != null) {
      return [
        'Server ตอบกลับผิดปกติ',
        'status: ${e.response!.statusCode} · แจ้งผู้ดูแลระบบ'
      ];
    }
    if (e is FormatException) {
      return ['Server ตอบกลับผิดรูปแบบ', 'แจ้งผู้ดูแลระบบ'];
    }
    return ['ติดต่อ server ไม่ได้', 'ตรวจสอบเครือข่าย แล้วให้ลูกค้าแตะใหม่'];
  }
}
