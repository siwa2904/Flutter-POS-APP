import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mispos/models/bill_model.dart';
import 'package:mispos/services/pos_service.dart';
import 'package:mispos/utils/constants.dart';
import 'package:presentation_displays/displays_manager.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';

class CmdController extends GetxController {

  Rx<BillModel> orderDis = BillModel().obs;
  DisplayManager displayManager = DisplayManager();

  RxString payCash = "0.00".obs;
  Rx<String> change = '0.0'.obs;
  Rx<String> cardBalance ='0.00'.obs;

  /// หน้าต่างเช็คบัตรที่เครื่องแคชเชียร์ null = จอปกติ
  /// เก็บเป็น Map ตัวใหม่ทุกครั้ง แตะบัตรสองใบติดกันแล้วผลแบบเดียวกัน จอยังอัปเดต
  Rxn<Map> cardCheck = Rxn<Map>();
  @override
  void onInit() {
    super.onInit();
    orderDis.value.billTotal = 0;
    orderDis.value.receiveCash = 0;
    orderDis.value.billItem = [];
    orderDis.value.customer = Customer();
    orderDis.value.customer!.customerNo = "CM000001";
    orderDis.value.customer!.fName = "เงินสด";
    payCash.value = "0.00";
    cardBalance.value='0.00';
    orderDis.value.billTotal = 0;
    orderDis.value.receiveCash = 0;
  }



  setDataDisplay(dynamic cdm1) async {
    print("DDDD::");
    print(cdm1);
    if (cdm1 is Map && cdm1["type"] == "cardCheck") {
      cardCheck.value = Map.from(cdm1);
      return;
    }
    // ได้บิลหรือ CLEAR มา แปลว่าหน้าต่างเช็คบัตรปิดแล้ว กลับไปจอปกติ
    cardCheck.value = null;
    if (cdm1 == "CLEAR") {
      resetDisplay();
    } else {

      var cdm = billModelFromJson(jsonEncode(cdm1));
      orderDis.value = cdm;

      if (cdm.receiveCash! > 0) {
        var chg = (cdm.receiveCash! - cdm.billTotal!);
        change.value = chg.toString();
      }
      print( orderDis.value.customer?.balance);

      update();
    }

  }

  resetDisplay() {
    print("ssssddd");
    // ต้องเปลี่ยนที่ .value ถ้าสร้าง Rx ใหม่ Obx ในจอลูกค้ายังผูกกับตัวเก่าและไม่อัปเดต
    final empty = BillModel();
    empty.customer = Customer();
    empty.customer!.customerNo = "CM000001";
    empty.customer!.fName = "เงินสด";
    empty.customer!.balance = "0.0";
    empty.billTotal = 0;
    empty.billItem = [];
    empty.receiveCash = 0;
    orderDis.value = empty;
    change.value='0';
    update();
  }

}
