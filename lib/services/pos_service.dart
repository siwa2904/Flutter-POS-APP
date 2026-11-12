import 'dart:convert';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mispos/models/bill_model.dart';
import 'package:mispos/models/customer_model.dart';
import 'package:mispos/models/product_model.dart';
import 'package:mispos/models/receive_change_model.dart';
import 'package:mispos/models/report_sale_model.dart';
import 'package:mispos/utils/constants.dart';
import 'package:mispos/utils/server_error_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart' as DIO;

class POSService {
  // final mc = GetStorage();
  final _dio = DIO.Dio()
    ..interceptors.add(DIO.InterceptorsWrapper(
        onRequest: (options, handler) async {
          final mc = GetStorage();
          SharedPreferences prefs = await SharedPreferences.getInstance();
          options.baseUrl = "http://${prefs.getString(Constant.ipServer)!}/api/${Constant.apiUrl}";
          options.headers = {
            "Authorization": "Bearer " + prefs.getString(Constant.token)!,
          };
          print(options.uri);
          print(prefs.getString(Constant.token));
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          // Do something with response data
          return handler.next(response); // continue
        },
        onError: (DIO.DioError e, handler) => {handler.next(e)}));
  Future<List<ProductModel>> getProductForSale() async {
    try {
      final DIO.Response response =
          await _dio.get("/stock/products/sku?forSale=1");
      if (response.statusCode == 200) {
        return productModelFromJson(jsonEncode(response.data["data"]));
      }
      print(response);
    } catch (error) {
      print(error);
      ServerErrorDialog.show();
    }
    throw Exception("Network faild");
  }

  Future<List<Cat>> getProductCate() async {
    try {
      final DIO.Response response = await _dio.get("/stock/categories");
      if (response.statusCode == 200) {
        print(response.data);
        return catFromJson(jsonEncode(response.data["data"]));
      }
    } catch (error) {
      ServerErrorDialog.show();
    }
    throw Exception("Network faild");
  }

  Future<ProductModel> getProductById(String id) async {
    final DIO.Response response = await _dio.get("/stock/products/$id");
    if (response.statusCode == 200) {
      return ProductModel.fromJson(response.data["data"]);
    }
    throw Exception("Network faild");
  }

  Future<List<CustomerModel>> geCustomer() async {
    final DIO.Response response = await _dio.get("/pos/customers/all");
    print(response);
    if (response.statusCode == 200) {
      print(response.data);
      return customerModelFromJson(jsonEncode(response.data["data"]));
    }
    throw Exception("Network faild");
  }

  Future<List<CustomerModel>> filterCustomer(String fillter) async {
    final DIO.Response response =
        await _dio.get("/pos/customers/all?q=$fillter");
    print(response);
    if (response.statusCode == 200) {
      print(response.data);
      return customerModelFromJson(jsonEncode(response.data["data"]));
    }
    throw Exception("Network faild");
  }

  Future<BillModel> saveBills(BillModel bill) async {
    try {
      print(billModelToJson(bill));
      DIO.Response response =
          await _dio.post('/bill/saveCash', data: billModelToJson(bill));
      print(response.statusCode);
      if (response.statusCode == 200) {
        var resp = response.data['data'];

        return billModelFromJson(jsonEncode(resp));
      } else {
        FlutterLogs.logInfo("OrderCash", "ServerOff", billModelToJson(bill));
        Get.snackbar("Error", "ไม่สามารถทำรายการขายได้");
      }
    } catch (error) {
      FlutterLogs.logInfo("OrderCash", "ServerOff", billModelToJson(bill));
      Get.snackbar("Error", "ไม่สามารถทำรายการขายได้");
    }
    throw Exception("Network faild");
  }

  Future<dynamic> saveBillsCard(BillModel bill) async {
    try {
      print(bill);
      DIO.Response response = await _dio.post('/bill/saveCard', data: billModelToJson(bill));
      print("========");
      print(response);
      print("*******");
      if (response.statusCode == 200) {
        // var resp = response.data['data'];remo
        return response.data;
      } else {
        FlutterLogs.logInfo("OrderCard", "ServerOff", billModelToJson(bill));
        Get.snackbar("Error", "ไม่สามารถทำรายการขายได้");

        return response.data;
        // throw Exception("Network faild");
      }
    } catch (error) {
      print(error);
      FlutterLogs.logInfo("OrderCard", "ServerOff", billModelToJson(bill));
      Get.snackbar("Error", "ไม่สามารถทำรายการขายได้");
      return "error";
      throw Exception("Network faild");
    }
    throw Exception("Network faild");
  }

  /// เช็คยอดบัตร อ่านอย่างเดียว ไม่สร้างบิล
  /// ไม่พบบัตร server ตอบ {} จะได้ null ส่วนเน็ตหรือ server มีปัญหาจะ throw ให้ผู้เรียกจัดการ
  Future<Map<String, dynamic>?> getCardDetail(String cardNumber) async {
    final DIO.Response response = await _dio
        .get("/shop/carddetail", queryParameters: {"cardNumber": cardNumber});
    final data = response.data;
    if (data is Map && data["AccountNo"] != null) {
      return Map<String, dynamic>.from(data);
    }
    if (data is Map) return null;
    throw const FormatException("carddetail: response is not JSON object");
  }

  Future<BillModel> saveBillsFinance(BillModel bill) async {
    try {
      print(billModelToJson(bill));
      // try {
      DIO.Response response =
          await _dio.post('/bill/saveFinance', data: billModelToJson(bill));
      print(response.statusCode);
      if (response.statusCode == 200) {
        var resp = response.data['data'];
        print(resp);

        return billModelFromJson(jsonEncode(resp));
      }
    } catch (error) {
      FlutterLogs.logInfo("OrderFinance", "ServerOff", billModelToJson(bill));
      Get.snackbar("Error", "ไม่สามารถทำรายการขายได้");
    }
    throw Exception("Network faild");
  }

  Future<ReportSaleModel> getReportToday() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var now = DateTime.now();
      var formatter = DateFormat('yyyy-MM-dd');
      print(formatter);
      var param = {"pos": Constant.POS_ID, "startDate": formatter};
      final DIO.Response response = await _dio.get(
          "/account/report/sale?pos_id=${prefs.getString(Constant.posNo)}");
      print(response.statusCode);
      if (response.statusCode == 200) {
        return reportSaleModelFromJson(jsonEncode(response.data));
      }
    } catch (error) {
      print(error);
      ServerErrorDialog.show();
    }
    throw Exception("Network faild");
    // http://192.168.1.105:9001/api/v1/account/report/sale_report_daily
  }

  Future<List<BillModel>> getReportItemToday() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // var param={
    //   "pos":Constant.POS_ID,
    //   "startDate":"2023-01-19"
    // };
    final DIO.Response response = await _dio
        .get("/bill/salebypos?pos_id=${prefs.getString(Constant.posNo)}");

    if (response.statusCode == 200) {
      return billModelListFromJson(jsonEncode(response.data));
    }
    throw Exception("Network faild");
    // http://192.168.1.105:9001/api/v1/account/report/sale_report_daily
  }

  Future<List<POSReceiveChangeModel>> getReceiveChangeToday() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var param = {"pos": Constant.POS_ID, "startDate": "2023-01-19"};
    final DIO.Response response = await _dio.get(
        "/pos/receiveChange/all?pos_id=${prefs.getString(Constant.posNo)}");

    if (response.statusCode == 200) {
      return posReceiveChangeModelFromJson(jsonEncode(response.data));
    }
    throw Exception("Network faild");
  }

  Future<POSReceiveChangeModel> saveReceiveChange(
      POSReceiveChangeModel data) async {
    DIO.Response response =
        await _dio.post('/pos/receiveChange', data: posRecToJson(data));
    print(response.statusCode);
    if (response.statusCode == 200) {
      var resp = response.data['data'];
      print(resp);

      return posReceiveChangeFromJson(jsonEncode(resp));
    }
    // }catch(e){

    throw Exception("Network faild");
  }
}
