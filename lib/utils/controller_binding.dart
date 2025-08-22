import 'package:get/get.dart';
import 'package:mispos/controllers/cmd_controller.dart';
import 'package:mispos/controllers/networkmanager_controller.dart';
import 'package:mispos/controllers/pos_controller.dart';

import '../controllers/orders_controller.dart';
import '../controllers/setting_controller.dart';

class ControllerBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut<NetworkManager>(() => NetworkManager());
    Get.lazyPut<OrdersController>(() => OrdersController());
    Get.lazyPut<POSController>(() => POSController());
    Get.lazyPut<CmdController>(()=>CmdController());
    Get.lazyPut<SettingController>(() => SettingController());
    // Get.lazyPut<HomeController>(() => HomeController());
    // Get.lazyPut<TopupController>(() => TopupController());
  }
}
