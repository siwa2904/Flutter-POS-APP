import 'dart:convert';

import 'package:get/get.dart';
import 'package:mispos/models/bill_model.dart';
import 'package:mispos/services/pos_service.dart';
import 'package:mispos/utils/constants.dart';
import 'package:presentation_displays/displays_manager.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/receive_change_model.dart';

class RecieveChangeController extends GetxController {
  Rx<POSReceiveChangeModel> rcc = POSReceiveChangeModel().obs;

  @override
  void onInit() {
    super.onInit();
    print("OrdersControllÏΩer  onInit");
  }

  getReceiveToday() {}
}
