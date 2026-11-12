import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/tap_pulse.dart';

/// ฝั่งขวาของจอลูกค้า ระหว่างแคชเชียร์เปิดหน้าต่างเช็คบัตร
/// data มาจาก CardCheckController: state = wait / loading / found / notFound / error
/// ใช้สีเขียว ไม่ใช้ส้มแบบตอนจ่ายเงิน และบอกทุกสถานะว่าไม่มีการตัดเงิน ลูกค้าจะไม่นึกว่าโดนตัดเงินไปแล้ว
class CardCheckDisplayPanel extends StatelessWidget {
  const CardCheckDisplayPanel({Key? key, required this.data}) : super(key: key);

  final Map data;

  static const _teal = Color(0xFF00796B);
  static const _dark = Color(0xFF004D40);
  static const _red = Color(0xFFB71C1C);
  static const _text = Color(0xFF212121);
  static const _grey = Color(0xFF616161);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 80,
          width: double.infinity,
          color: _teal,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              const Icon(Icons.credit_card, size: 36, color: Colors.white),
              const SizedBox(width: 14),
              Text("เช็คยอดบัตร",
                  style: _style(34, Colors.white, weight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            alignment: Alignment.center,
            // จอลูกค้าแต่ละรุ่นขนาดไม่เท่ากัน ย่อทั้งก้อนแทนการล้นจอ
            child: FittedBox(
                fit: BoxFit.scaleDown, child: _content(data['state'])),
          ),
        ),
        Container(
          height: 72,
          width: double.infinity,
          color: const Color(0xFFE0F2F1),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined, size: 32, color: _dark),
              const SizedBox(width: 14),
              Flexible(
                child: Text("ดูยอดอย่างเดียว ไม่มีการตัดเงินจากบัตร",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _style(28, _dark, weight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _content(dynamic state) {
    final last4 = '${data['last4'] ?? ''}';

    if (state == 'found') {
      final zero = data['zero'] == true;
      final color = zero ? _red : _dark;
      final name = '${data['name'] ?? ''}';
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (name.isNotEmpty)
            Text("คุณ$name",
                style: _style(44, const Color(0xFF263238),
                    weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text("ยอดเงินคงเหลือ", style: _style(34, _grey)),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${data['amount'] ?? ''}',
                  style: _style(132, color,
                      weight: FontWeight.bold, height: 1.1)),
              Text('${data['decimals'] ?? ''}',
                  style: _style(64, color, weight: FontWeight.bold)),
              const SizedBox(width: 14),
              Text("บาท", style: _style(44, color)),
            ],
          ),
          if (zero) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 32, color: _red),
                  const SizedBox(width: 12),
                  Text("ยอดเงินคงเหลือไม่พอ",
                      style: _style(32, _red, weight: FontWeight.w600)),
                ],
              ),
            ),
            Text("กรุณาเติมเงินก่อนซื้อ", style: _style(30, _red)),
          ],
          const SizedBox(height: 6),
          Text("บัตร •••• $last4 · ตรวจสอบเมื่อ ${data['checkedAt'] ?? ''} น.",
              style: _style(28, _grey)),
        ],
      );
    }

    if (state == 'loading') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
                strokeWidth: 9,
                color: _teal,
                backgroundColor: Color(0xFFB2DFDB)),
          ),
          const SizedBox(height: 30),
          Text("กำลังตรวจสอบ… รอสักครู่",
              style: _style(48, _text, weight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text("บัตร •••• $last4", style: _style(32, _grey)),
        ],
      );
    }

    if (state == 'notFound') {
      return _problem(
        circle: const Color(0xFFFFF3E0),
        icon: Icons.search_off,
        iconColor: const Color(0xFFE65100),
        title: "ไม่พบข้อมูลบัตรใบนี้",
        detail: "กรุณาแตะบัตรอีกครั้ง หรือสอบถามพนักงาน",
      );
    }

    if (state == 'error') {
      return _problem(
        circle: const Color(0xFFECEFF1),
        icon: Icons.error_outline,
        iconColor: const Color(0xFF455A64),
        title: "ตอนนี้ตรวจสอบยอดไม่ได้",
        detail: "ระบบขัดข้องชั่วคราว ไม่ใช่ปัญหาที่บัตร",
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TapPulse(
          size: 220,
          color: _teal,
          strokeWidth: 4,
          child: Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
                color: Color(0xFFE0F2F1), shape: BoxShape.circle),
            child: const Icon(Icons.contactless_outlined, size: 84, color: _teal),
          ),
        ),
        const SizedBox(height: 26),
        Text("แตะบัตรที่เครื่องอ่านบัตร",
            style: _style(52, _text, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text("เพื่อดูยอดเงินคงเหลือ", style: _style(34, _grey)),
      ],
    );
  }

  Widget _problem({
    required Color circle,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String detail,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
          child: Icon(icon, size: 72, color: iconColor),
        ),
        const SizedBox(height: 26),
        Text(title,
            style: _style(52, const Color(0xFF263238), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(detail, style: _style(34, _grey)),
      ],
    );
  }

  TextStyle _style(double size, Color color,
      {FontWeight? weight, double? height}) {
    return GoogleFonts.maitree(
        fontSize: size, color: color, fontWeight: weight, height: height);
  }
}
