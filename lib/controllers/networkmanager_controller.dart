import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class NetworkManager extends GetxController {
  int connectionType = 0;
  final Connectivity _connectivity = Connectivity();
  RxBool isUpdate = false.obs;
  @override
  void onInit() {
    // GetConnectionType();
    if (GetPlatform.isAndroid) {
      // checkForUpdate();
    }
  }

  Future<void> GetConnectionType() async {
    var connectivityResult;
    try {
      connectivityResult = await (_connectivity.checkConnectivity());
    } on PlatformException catch (e) {}
    return _updateState(connectivityResult);
  }

  pingpongServer(){

  }

  _updateState(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        connectionType = 1;
        update();
        break;
      case ConnectivityResult.mobile:
        connectionType = 2;
        update();
        break;
      case ConnectivityResult.none:
        connectionType = 0;
        update();
        break;
      default:
        Get.snackbar('Network error', 'Failed to get Network');
    }
  }

  checkForUpdate() async {
    // AppUpdateInfo? _updateInfo;
    // InAppUpdate.checkForUpdate().then((info) {
    //   print("=========INFO==========");
    //   print(info);
    //
    //   info.updateAvailability == UpdateAvailability.updateAvailable
    //       ? () {
    //           isUpdate.value = true;
    //           InAppUpdate.startFlexibleUpdate().then((_) {
    //             Get.snackbar("Update Success!", "");
    //           }).catchError((e) {
    //             Get.snackbar("Update Error!", e.toString());
    //           });
    //           // InAppUpdate.performImmediateUpdate()
    //           //     .catchError((e) => Get.snackbar("Error", e.toString()));
    //         }
    //       : null;
    // }).catchError((e) {
    //   Get.snackbar("Error", e.toString());
    // });
  }
}
