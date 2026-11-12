import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/card_check_controller.dart';
import '../../widgets/tap_pulse.dart';

/// หน้าต่างเช็คยอดบัตร เปิดจากปุ่ม "เช็คบัตร" ในหน้าขาย
/// แตะบัตรใบถัดไปได้เลยโดยไม่ต้องปิด หน้าต่างปิดเมื่อกดปุ่มปิดเท่านั้น
/// ทุกสถานะใช้กรอบขนาดเดียวกัน ปุ่มปิดจึงอยู่ที่เดิมเสมอ
class CardCheckDialog extends StatelessWidget {
  const CardCheckDialog({Key? key}) : super(key: key);

  static const _teal = Color(0xFF00796B);
  static const _text = Color(0xFF212121);
  static const _note = Color(0xFF424242);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CardCheckController>();
    return Dialog(
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // จอเล็กกว่ากรอบนี้ให้ย่อทั้งก้อน ปุ่มปิดจะได้ไม่หลุดจอ
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 600,
          height: 560,
          child: Column(
            children: [
              _header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  children: [
                    SizedBox(
                        height: 300,
                        child: Obx(() => _stage(ctrl.view.value))),
                    const SizedBox(height: 12),
                    SizedBox(
                        height: 64,
                        child: Obx(() => _message(ctrl.view.value))),
                    const SizedBox(height: 12),
                    _closeButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 56,
      color: _teal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Icon(Icons.credit_card, size: 24, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text("โหมดเช็คบัตร · ไม่ตัดเงิน · สแกนสินค้าจะไม่เข้าตะกร้า",
                  style: GoogleFonts.maitree(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stage(CardCheckView v) {
    switch (v.status) {
      case CardCheckStatus.loading:
        return _box(
          bg: const Color(0xFFECEFF1),
          border: const Color(0xFFCFD8DC),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                    strokeWidth: 6,
                    color: _teal,
                    backgroundColor: Color(0xFFB2DFDB)),
              ),
              const SizedBox(height: 20),
              Text("กำลังตรวจสอบบัตร",
                  style: GoogleFonts.maitree(
                      fontSize: 26, fontWeight: FontWeight.w600, color: _text)),
              const SizedBox(height: 6),
              Text("•••• ${v.last4}",
                  style: GoogleFonts.maitree(
                      fontSize: 22,
                      letterSpacing: 2,
                      color: const Color(0xFF455A64))),
            ],
          ),
        );
      case CardCheckStatus.found:
        return _card(v);
      case CardCheckStatus.notFound:
        return _problem(
          bg: const Color(0xFFFFF3E0),
          border: const Color(0xFFFFCC80),
          icon: Icons.search_off,
          iconColor: const Color(0xFFE65100),
          title: "ไม่พบบัตรนี้ในระบบ",
          titleColor: const Color(0xFFBF360C),
          detail: "เลขบัตร •••• ${v.last4}",
          detailColor: const Color(0xFF5D4037),
        );
      case CardCheckStatus.error:
        // ไม่ใช้สีแดง เก็บสีแดงไว้ให้ยอด 0 อย่างเดียว
        return _problem(
          bg: const Color(0xFFECEFF1),
          border: const Color(0xFFB0BEC5),
          icon: v.isOffline ? Icons.wifi_off : Icons.error_outline,
          iconColor: const Color(0xFF455A64),
          title: v.errorTitle,
          titleColor: const Color(0xFF263238),
          detail: "ยังไม่รู้ยอดเงินในบัตร",
          detailColor: const Color(0xFF455A64),
        );
      case CardCheckStatus.waiting:
        break;
    }
    return _box(
      bg: const Color(0xFFF1F8F7),
      border: const Color(0xFF80CBC4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TapPulse(
            size: 176,
            color: _teal,
            child: Container(
              width: 124,
              height: 124,
              decoration: const BoxDecoration(
                  color: Color(0xFFE0F2F1), shape: BoxShape.circle),
              child: const Icon(Icons.contactless_outlined,
                  size: 64, color: _teal),
            ),
          ),
          const SizedBox(height: 8),
          Text("แตะบัตรที่เครื่องอ่านบัตร",
              style: GoogleFonts.maitree(
                  fontSize: 28, fontWeight: FontWeight.w600, color: _text)),
        ],
      ),
    );
  }

  Widget _card(CardCheckView v) {
    // ยอด 0 เป็นบัตรสีแดงทั้งใบ และมีป้ายข้อความด้วย คนตาบอดสีแยกเขียวกับแดงไม่ออก
    final zero = v.isZero;
    final base = zero ? const Color(0xFFB71C1C) : const Color(0xFF00695C);
    final flash = zero ? const Color(0xFFE53935) : const Color(0xFF26A69A);
    final soft = zero ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1);

    // กะพริบทุกครั้งที่ได้ผลใหม่ แตะใบที่สองแล้วยอดเท่าเดิม แคชเชียร์ยังรู้ว่าแตะติด
    return TweenAnimationBuilder<Color?>(
      key: ValueKey(v.seq),
      tween: ColorTween(begin: flash, end: base),
      duration: const Duration(milliseconds: 600),
      builder: (context, color, child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x38000000), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 34,
                decoration: BoxDecoration(
                    color: const Color(0xFFE6C36A),
                    borderRadius: BorderRadius.circular(6)),
              ),
              Text("•••• ${v.last4}",
                  style: GoogleFonts.maitree(
                      fontSize: 20, letterSpacing: 2, color: soft)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (zero)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.block,
                          size: 20, color: Color(0xFFB71C1C)),
                      const SizedBox(width: 8),
                      Text("ยอดเงินคงเหลือไม่พอ",
                          style: GoogleFonts.maitree(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB71C1C))),
                    ],
                  ),
                )
              else
                Text("ยอดคงเหลือ",
                    style: GoogleFonts.maitree(fontSize: 20, color: soft)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(v.amount,
                        style: GoogleFonts.maitree(
                            fontSize: 84,
                            height: 1.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text(v.decimals,
                        style: GoogleFonts.maitree(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(width: 12),
                    Text("บาท",
                        style: GoogleFonts.maitree(fontSize: 26, color: soft)),
                  ],
                ),
              ),
            ],
          ),
          Text(v.holder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.maitree(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _problem({
    required Color bg,
    required Color border,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required String detail,
    required Color detailColor,
  }) {
    return _box(
      bg: bg,
      border: border,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, size: 52, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.maitree(
                  fontSize: 26, fontWeight: FontWeight.w600, color: titleColor)),
          const SizedBox(height: 4),
          Text(detail,
              textAlign: TextAlign.center,
              style: GoogleFonts.maitree(fontSize: 20, color: detailColor)),
        ],
      ),
    );
  }

  Widget _box({required Color bg, required Color border, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 2),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  /// แถวข้อความใต้กรอบ สูงคงที่ ยิงบาร์โค้ดสินค้าแล้วกลายเป็นแถบเตือนสีเหลือง
  Widget _message(CardCheckView v) {
    if (v.barcodeWarning) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB300), width: 2),
        ),
        child: Row(
          children: [
            const FaIcon(FontAwesomeIcons.barcode,
                size: 26, color: Color(0xFF5D4037)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("นี่คือบาร์โค้ดสินค้า ยังไม่ได้เพิ่มลงตะกร้า",
                      style: _line(const Color(0xFF3E2723), bold: true)),
                  Text("กดปิดก่อน แล้วค่อยสแกนสินค้า",
                      style: _line(const Color(0xFF5D4037))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    String first = '';
    String second = '';
    switch (v.status) {
      case CardCheckStatus.waiting:
        first = "ดูยอดอย่างเดียว ไม่ตัดเงิน ไม่สร้างบิล";
        break;
      case CardCheckStatus.loading:
        if (v.clearedPrevious) first = "ผลของบัตรใบก่อนถูกล้างแล้ว";
        break;
      case CardCheckStatus.found:
        first = "ตรวจสอบเมื่อ ${v.checkedAt} น.";
        second = "แตะบัตรใบอื่นเพื่อเช็คต่อได้เลย";
        break;
      case CardCheckStatus.notFound:
        first = "ให้ลูกค้าแตะใหม่ หรือแจ้งเจ้าหน้าที่ดูแลบัตร";
        break;
      case CardCheckStatus.error:
        first = v.errorDetail;
        break;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (first.isNotEmpty)
          Text(first,
              textAlign: TextAlign.center,
              style: _line(_note, bold: true)),
        if (second.isNotEmpty)
          Text(second, textAlign: TextAlign.center, style: _line(_note)),
      ],
    );
  }

  TextStyle _line(Color color, {bool bold = false}) {
    return GoogleFonts.maitree(
        fontSize: 18,
        height: 1.4,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        color: color);
  }

  Widget _closeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF455A64),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        // ไม่ใช้ Get.back() เพราะถ้ามี snackbar ค้างอยู่ มันจะไปปิด snackbar แทนหน้าต่างนี้
        onPressed: () => Navigator.of(context).pop(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.close, size: 22, color: Colors.white),
            const SizedBox(width: 10),
            Text("ปิด",
                style: GoogleFonts.maitree(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
