import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mispos/models/main_menu_model.dart';
import 'package:mispos/services/api_service.dart';
import 'package:mispos/services/pos_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bill_model.dart';
import '../models/report_sale_model.dart';

class HomeController extends GetxController {
  Rx<ReportSaleModel> repReport = ReportSaleModel().obs;
  RxList<BillModel> billAll =  (List<BillModel>.of([])).obs;
  RxBool loadingTrans = false.obs;

  Rx<PackageInfo> packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  ).obs;

  @override
  void onInit() {
    getReport();
    _initPackageInfo();
  }
  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();

    packageInfo.value = info;
    print("GetVersion");
print(packageInfo.value);
  }
  getReport() async {
    ReportSaleModel data = await POSService().getReportToday();
    repReport.value = data;
print(repReport.value);
  }

  getReportList() async {
    loadingTrans.value = true;
    billAll.value = await POSService().getReportItemToday();
    loadingTrans.value = false;
  }
}
