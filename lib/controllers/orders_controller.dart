import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mispos/models/bill_model.dart';
import 'package:mispos/services/pos_service.dart';
import 'package:mispos/utils/constants.dart';
import 'package:mispos/utils/sql_helper.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintf/sprintf.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/sound_service.dart';

class OrdersController extends GetxController {
  Rx<BillModel> order = BillModel().obs;
  Rx<BillModel> orderSuccess = BillModel().obs;
  Rx<BillModel> orderDis = BillModel().obs;
  Rx<CardInfo> cardInfo = CardInfo().obs;
  DisplayManager displayManager = DisplayManager();
  RxInt count = 0.obs;
  RxBool isPayProcess = false.obs;
  RxBool isPaySuccess = false.obs;
  RxString payCash = "0.00".obs;
  Rx<String> change = '0.0'.obs;
  Rx<String> errorCard = "".obs;
  RxBool isDuplicateScan = false.obs;
  final SoundService _sound = SoundService();
  @override
  void onInit() {
    super.onInit();
    _sound.preload();
    clear();
    order.value.billTotal = 0;
    order.value.receiveCash = 0;
    order.value.billItem = [];
    order.value.customer = Customer();
    order.value.customer!.customerNo = "CM000001";
    order.value.customer!.fName = "เงินสด";
    payCash.value = "0.00";

    orderDis.value.billTotal = 0;
    orderDis.value.receiveCash = 0;
    print("OrdersController  onInit");
  }

  increate() {
    count.value++;
  }

  addItem(ProductModel prod) async {
    if (prod.productId != "") {
      int ind = order.value.billItem!.indexWhere((element) =>
          element.productId == prod.productId && prod.skuSelect == element.sku);

      if (ind > -1) {
        order.value.billItem![ind].qty = order.value.billItem![ind].qty! + 1;
        order.value.billItem![ind].total = (order.value.billItem![ind].qty! *
                order.value.billItem![ind].price!)
            .toString();
      } else {
        BillItem itm = BillItem();

        itm.sku = prod.skuSelect;
        itm.productId = prod.productId;
        itm.productName = prod.name;
        itm.price = double.parse(prod.price1!);
        if (prod!.qty != null) {
          itm.qty = prod!.qty!;
        } else {
          itm.qty = 1;
        }

        itm.total = (double.parse(prod.price1!) * itm.qty!).toString();
        order.value.billItem = [itm, ...?order.value.billItem];
        prod!.qty = 1;
      }
      order.value.timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      // update();
      increate();
      update();
      updateOrderCal();
      // setDataDisplay(order.value);
      await displayManager.transferDataToPresentation(order.value.toJson());
    }
  }

  removeItem(int index) async {
    print(index);
    order.value.billItem!.removeAt(index);
    update();
    updateOrderCal();
    count.value--;
    await displayManager.transferDataToPresentation(order.value.toJson());
  }

  updateOrderCal() {
    double total = 0;
    if (order.value.billItem != null) {
      for (var element in order.value.billItem!) {
        total += double.parse(element.total!);
      }
    }
    order.value.billTotal = total;
    update();
  }

  setDataDisplay(dynamic cdm1) async {
    print("DDDD::");
    if (cdm1 == "CLEAR") {
      resetDisplay();
    } else {
      print(cdm1["BillTotal"]);
      var cdm = billModelFromJson(jsonEncode(cdm1));
      orderDis.value = cdm;
      count.value--;
      if (cdm.receiveCash! > 0) {
        var chg = (cdm.receiveCash! - cdm.billTotal!);
        change.value = chg.toString();
      }
      update();
    }
    // (cdc.orderDis.value!.receiveCash!.toString()!= '0.0')?(cdc.orderDis.value!.receiveCash!-(cdc.orderDis.value.billTotal!)).toString():'0.0'
  }

  resetDisplay() {
    print("ssssddd");
    orderDis = BillModel().obs;
    orderDis.value.customer = Customer();
    orderDis.value.customer!.customerNo = "CM000001";
    orderDis.value.customer!.fName = "เงินสด";
    orderDis.value.billTotal = 0;
    orderDis.value.billItem = [];
    orderDis.value.receiveCash = 0;
    count.value = 0;
    change.value = '0';
    update();
  }

  clear({bool isclearDisplay = true}) async {
    print("======Clear=====");
    order = BillModel().obs;
    order.value.billTotal = 0;
    order.value.billItem = [];
    order.value.customer = Customer();
    order.value.customer!.customerNo = "CM000001";
    order.value.customer!.fName = "เงินสด";
    order.value.receiveCash = 0;
    order.value.customer!.balance = "0";
    order.value.payType = "0";

    count.value = 0;

    update();
    if (isclearDisplay) {
      await displayManager.transferDataToPresentation("CLEAR");
    }
  }

  keyReceiveCash(String key) {
    if (key == "C") {
      payCash.value = "0.00";
    } else if (key == "D") {
      payCash.value = payCash.value.substring(0, payCash.value.length - 1);
    } else if (key == "PR") {
      payCash.value = order.value.billTotal.toString();
    } else if (key == "1000" ||
        key == "500" ||
        key == "100" ||
        key == "50" ||
        key == "20") {
      payCash.value = key;
    } else {
      if (payCash.value == "0.00") {
        payCash.value = key;
      } else {
        payCash.value = payCash.value + key;
      }
    }
    order.value.receiveCash = double.parse(payCash.value);
    update();
  }

  checkNetwork() async {
    bool network = await ApiService().getPingPong();
  }

  payCashToBill() async {
    isPaySuccess.value = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool network = await ApiService().getPingPong();
    print("network::" + network.toString());
    // final mc = GetStorage();
    FlutterLogs.logToFile(
        logFileName: "eventlogbill",
        overwrite: false,
        logMessage: billModelToJson(order.value) + "\n");
    FlutterLogs.logInfo(
        "eventlogbill", "ServerOff", billModelToJson(order.value));
    if (network) {
      isPayProcess.value = true;
      order.value.pos = prefs.getString(Constant.posNo);
      order.value.billSubTotal = order.value.billTotal;
      order.value.payType = "1";
      order.value.status = "2";
      BillModel rep = await POSService().saveBills(order.value);
      print("=======");
      print(rep);
      print("=======");
      if (rep.billNo != '' && rep.billNo != null) {
        print(rep);
        isPaySuccess.value = true;
        order.value = rep;
        orderSuccess.value = rep;

        await displayManager.transferDataToPresentation(order.value.toJson());
        clear(isclearDisplay: false);
      }
    } else {
      isPayProcess.value = true;
      print("saleOffline::" + prefs.getString(Constant.saleOffline).toString());
      print(prefs.getString(Constant.saleOffline));
      isPaySuccess.value = prefs.getBool(Constant.saleOffline)!;
      order.value.payType = "1";
      DateTime now = new DateTime.now();
      order.value.billDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
      orderSuccess.value = order.value;

      int lasAmt = await BillDatabaseHelper.db.getCount("billTable");
      print(lasAmt);
      print("TM${sprintf("%07i", [(lasAmt + 1)])}");

      order.value.tmRef = "TM${sprintf("%07i", [(lasAmt + 1)])}";
      FlutterLogs.logToFile(
          logFileName: "billoffline",
          overwrite: false,
          logMessage: billModelToJson(order.value) + "\n");
      BillDatabaseHelper.db.insertBill(order.value).then((result) {
        print(result);
      });
      FlutterLogs.logInfo(
          "OrderFinance", "ServerOff", billModelToJson(order.value));
      if (prefs.getBool(Constant.saleOffline) == true) {
        await displayManager.transferDataToPresentation(order.value.toJson());
        clear(isclearDisplay: false);
        Get.snackbar(
            "บันทึกรายการขาย Offline", "เนื่องจากไม่สามารถติดต่อ server ได้");
      } else {
        Get.snackbar("เกิดข้อผิดพลาด",
            "ไม่สามารถติดต่อ server ได้" + isPayProcess.value.toString());
      }
    }
  }

  payCardToBill() async {
    // กันแตะบัตรซ้ำหลังชำระสำเร็จแล้ว → dialog แสดง "ทำรายการสำเร็จ" อยู่แล้ว
    if (isPaySuccess.value && errorCard.value.isEmpty) {
      print("payCardToBill: already completed, ignoring re-scan");
      isDuplicateScan.value = true;
      _sound.playDuplicate();
      return;
    }
    isDuplicateScan.value = false;

    bool network = await ApiService().getPingPong();

    final mc = GetStorage();
    if (network) {
      isPayProcess.value = true;
      order.value.pos = mc.read(Constant.posNo);
      order.value.billSubTotal = order.value.billTotal;
      order.value.payType = "0";
      order.value.status = "2";
      print("====order to json===");
      print(order.value.toJson());
      dynamic rep = await POSService().saveBillsCard(order.value);

      bool isError = false;
      if (rep == "error") {
        isError = true;
      } else if (rep is Map && rep["status"] == "error") {
        isError = true;
      }

      if (isError) {
        // ------------------
        isPaySuccess.value = true;

        String errorMsg = "ไม่พบบัตร";
        if (rep is Map && rep["error"] != null) {
          errorMsg = rep["error"];
        }

        errorCard.value = errorMsg; // ใช้ข้อความจาก Server
        update();
        orderSuccess.refresh();

        // เพิ่ม Log เพื่อ debug
        print("Card Error: $errorMsg");
        _sound.playFailed();
      } else {
        if (rep["bill"] != null &&
            rep["bill"] is! List &&
            rep["bill"]["billNo"] != "") {
          isPaySuccess.value = true;
          _sound.playSuccess();
          // order.value = rep;

          if (rep["bill"] != null) {
            errorCard.value = "";

            BillModel resp = billModelFromJson(jsonEncode(rep["bill"]));
            orderSuccess.value = resp;
          }
          orderSuccess.value.customerName = rep["data"]?['AccName'];
          CardInfo card = CardInfo();
          card.cardNumber = order.value.cardNumber;
          card.accName = rep["data"]['AccName'];
          card.amount = rep["data"]['Amount'].toString();
          orderSuccess.value.customer?.customerNo = rep["bill"]["CustomerNo"];
          orderSuccess.value.customer?.fName = rep["bill"]["CustomerName"];

          orderSuccess.value.card = card;
          orderSuccess.value.customer?.balance = card.amount;
          print("==>BillItem");
          orderSuccess.value.payType = "card";
          print(orderSuccess.value.billItem![0]);
          print(orderSuccess.value.billItem![0].productName);
          orderSuccess.value.cardBalance = card.amount;
          order.value.payType = "card";
          order.value.customer?.customerNo = rep["bill"]["CustomerNo"];
          order.value.customer?.fName = rep["bill"]["CustomerName"];
          order.value.customer?.balance = card.amount;
          print(orderSuccess.value.cardBalance);
          print("Send to Display==================>");
          await displayManager.transferDataToPresentation(order.value.toJson());
          clear(isclearDisplay: false);
        } else {
          // server ตอบกลับมาโดยไม่ใช่ error แต่ไม่มี billNo ที่ใช้ได้
          // เคสนี้ UI ค้างอยู่ที่หน้ารอโดยไม่แสดงอะไร แคชเชียร์จึงไม่รู้ว่าเกิดอะไรขึ้น
          // จึงส่งเสียงแจ้งว่าไม่สำเร็จไว้ก่อน ส่วนการซ่อม dialog ที่ค้างเป็นคนละงาน
          print("payCardToBill: unexpected response shape_____ => $rep");
          _sound.playFailed();
        }
      }
    } else {
      isPayProcess.value = true;
      // จงใจไม่เล่นเสียงในเส้นทาง offline ไม่ใช่ลืม
      // บิลถูกบันทึกลงเครื่องรอ sync เท่านั้น เงินยังไม่ถูกตัดจากบัตรจริง
      // ถ้าเล่นเสียง "ชำระเงินสำเร็จ" ตรงนี้จะทำให้เข้าใจผิดว่าตัดเงินแล้ว
      print("saleOffline::" + mc.read(Constant.saleOffline).toString());
      print(mc.read(Constant.saleOffline));
      isPaySuccess.value = mc.read(Constant.saleOffline);
      order.value.payType = "1";
      DateTime now = new DateTime.now();
      order.value.billDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
      orderSuccess.value = order.value;

      int lasAmt = await BillDatabaseHelper.db.getCount("billTable");
      print(lasAmt);
      print("TM${sprintf("%07i", [(lasAmt + 1)])}");

      order.value.tmRef = "TM${sprintf("%07i", [(lasAmt + 1)])}";
      FlutterLogs.logToFile(
          logFileName: "billoffline",
          overwrite: false,
          logMessage: billModelToJson(order.value) + "\n");
      BillDatabaseHelper.db.insertBill(order.value).then((result) {
        print(result);
      });
      FlutterLogs.logInfo(
          "OrderFinance", "ServerOff", billModelToJson(order.value));
      if (mc.read(Constant.saleOffline) == true) {
        await displayManager.transferDataToPresentation(order.value.toJson());
        clear(isclearDisplay: false);
        Get.snackbar(
            "บันทึกรายการขาย Offline", "เนื่องจากไม่สามารถติดต่อ server ได้");
      } else {
        Get.snackbar("เกิดข้อผิดพลาด",
            "ไม่สามารถติดต่อ server ได้" + isPayProcess.value.toString());
      }
    }
  }

  payFinanceToBill() async {
    bool network = await ApiService().getPingPong();
    final mc = GetStorage();

    FlutterLogs.logToFile(
        logFileName: "eventlogbill",
        overwrite: false,
        logMessage: billModelToJson(order.value) + "\n");
    if (network) {
      isPayProcess.value = true;
      print(billModelToJson(order.value));
      // order.value.receiveCash
      order.value.pos = mc.read(Constant.posNo);
      order.value.billSubTotal = order.value.billTotal;
      order.value.payType = "2";
      order.value.status = "1";
      BillModel rep = await POSService().saveBillsFinance(order.value);
      isPaySuccess.value = true;
      order.value = rep;
      await displayManager.transferDataToPresentation(order.value.toJson());
    } else {
      isPayProcess.value = true;

      order.value.payType = "2";
      DateTime now = new DateTime.now();
      order.value.billDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
      FlutterLogs.logToFile(
          logFileName: "billoffline",
          overwrite: false,
          logMessage: billModelToJson(order.value) + "\n");
      // FlutterLogs.exportFileLogForName(logFileName: "billOffline");
      FlutterLogs.logInfo(
          "OrderFinance", "ServerOff", billModelToJson(order.value));
      if (mc.read(Constant.saleOffline) == true) {
        isPaySuccess.value = true;
        await displayManager.transferDataToPresentation(order.value.toJson());
      } else {
        isPaySuccess.value = false;
      }
      Get.snackbar("เกิดข้อผิดพลาด", "ไม่สามารถติดต่อ server ได้");
    }
  }

  updateOrder(int index) async {
    print(order.value.billItem![index]);
    order.value.billItem![index].total = (order.value.billItem![index].price! *
            order.value.billItem![index].qty!)
        .toString();
    updateOrderCal();
    await displayManager.transferDataToPresentation(order.value.toJson());
  }
}
