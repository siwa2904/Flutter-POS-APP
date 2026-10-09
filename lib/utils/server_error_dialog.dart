import 'package:get/get.dart';

/// หน้าต่างแจ้งว่าติดต่อ server ไม่ได้ ใช้ร่วมกันทุกจุดที่โหลดข้อมูลจาก server
///
/// หน้าเดียวยิงหลายคำขอพร้อมกัน เช่น หน้าขายโหลดสินค้ากับหมวดหมู่ หน้าแรกโหลดรายงานสองรอบ
/// ถ้าแต่ละจุดเปิดหน้าต่างเอง พอ server ล่มจะซ้อนกันหลายชั้นจนแคชเชียร์ต้องแตะปิดทีละชั้น
class ServerErrorDialog {
  static bool _isShowing = false;

  static void show() {
    // เช็ค isDialogOpen ด้วย กันค่าค้างกรณีหน้าต่างหายไปพร้อมการเปลี่ยนหน้าโดยไม่ได้ถูกปิด
    if (_isShowing && Get.isDialogOpen == true) return;
    _isShowing = true;
    Get.defaultDialog(
      title: "ไม่สามารถติดต่อ Server ได้",
      // ขึ้นบรรทัดเอง เพราะ Flutter 3.3 ตัดคำไทยกลางคำ
      // ต้องใส่ middleText เสมอ ไม่งั้น GetX ใส่ "Dialog made in 3 lines of code" ให้
      middleText: "ตรวจสอบเครือข่าย\nหรือ IP Server ในหน้าตั้งค่าเครื่อง",
    ).whenComplete(() => _isShowing = false);
  }
}
