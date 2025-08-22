import 'dart:convert';

import 'package:flutter_logs/flutter_logs.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mispos/models/bill_model.dart';
import 'package:mispos/services/pos_service.dart';
import 'package:mispos/utils/constants.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../utils/sql_helper.dart';
import 'package:intl/intl.dart';

class BillOfflineController extends GetxController {
  RxList<dynamic> billOf = [].obs;
  RxList billsOffline = [].obs;

  @override
  onInit() async {
    fetchBills();
    super.onInit();
  }

  fetchBills() async {
    var formatterDate = DateFormat('yyyy-MM-dd', 'th');
    DateTime now = DateTime.now();
    billsOffline.value = [];
    List<dynamic> itms = [];
    List<dynamic> itmsOK = [];
    await BillDatabaseHelper.db
        .getBillsMapList(formatterDate.format(now))
        .then((productList) => {itms = productList});
    print("From Sqlite");
    for (var element in itms) {
      Map<String, dynamic> dataToAdd = Map<String, dynamic>.from(element);
// Update it in memory now

      dataToAdd["Customer"] = jsonDecode(element["Customer"]);
      dataToAdd["BillItem"] = jsonDecode(element["BillItem"]);
      itmsOK.add(dataToAdd);
    }
    billsOffline.value=itmsOK;
    update();
    print(billsOffline);
    print("************");
  }

  // printLog() {
  //   billOf.value=[];
  //
  //   FlutterLogs.printFileLogForName(
  //       logFileName: "billoffline", decryptBeforeExporting: true);
  //   FlutterLogs.channel.setMethodCallHandler((call) async {
  //     if (call.method == "logsPrinted") {
  //       final bill = jsonDecode(call.arguments);
  //       billOf.add(bill);
  //       try {
  //
  //
  //       }catch(err){
  //         print(err.toString());
  //       }
  //
  //
  //     }
  //   });
  //
  // }
  stringToJSON(String data) {}
  sendBillToServer(item) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool network = await ApiService().getPingPong();
    print("network::" + network.toString());
    // final mc = GetStorage();
    if (network) {
      BillModel bm = BillModel();

      bm.billNo = item["BillNo"];
      bm.billDate = item['BillDate'];
      bm.customer = Customer();
      bm.customer!.customerNo = item["Customer"]["CustomerNo"];
      bm.customer!.fName = item["Customer"]['FName'];
      bm.customer!.lName = item["Customer"]["LName"];
      bm.payType = item['PayType'];
      bm.billTotal = double.parse(item['BillTotal']);
      bm.receiveCash = double.parse(item['ReceiveCash']);
      bm.tmRef=item['TMRef'];
      bm.pos =prefs.getString(Constant.posNo);
      bm.billItem=List<BillItem>.from(
          item["BillItem"]?.map((x) => BillItem.fromJson(x)));

      // bm.billItem=item["BillItem"];
      // print(list);
      // bm.billItem = bis;
      BillModel rep = await POSService().saveBills(bm);

      if (rep.billNo != "") {
       await  BillDatabaseHelper.db.updateTransfer(item['id'], 1,rep.billNo.toString()).then((result) {
          print(result);
        });
        fetchBills();
        update();
        // isPaySuccess.value = true;
        // order.value = rep;
        //
        // await displayManager.transferDataToPresentation(order.value.toJson());
      }
    } else {
      Get.snackbar("ไม่สามารถเชื่อมต่อ Server ได้", "");
    }
  }

  String removeJsonAndArray(String text) {
    if (text.startsWith('[') || text.startsWith('{')) {
      text = text.substring(1, text.length - 1);
      if (text.startsWith('[') || text.startsWith('{')) {
        text = removeJsonAndArray(text);
      }
    }
    return text;
  }
}
