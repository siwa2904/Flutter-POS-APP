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
    orderDis = BillModel().obs;
    orderDis.value.customer = Customer();
    orderDis.value.customer!.customerNo = "CM000001";
    orderDis.value.customer!.fName = "เงินสด";
    orderDis.value.customer!.balance="0.0";
    orderDis.value.billTotal = 0;
    orderDis.value.billItem = [];
    orderDis.value.receiveCash=0;
    change.value='0';
    update();
  }

}
