// To parse this JSON data, do
//
//     final billModel = billModelFromJson(jsonString);

import 'dart:convert';

import 'package:mispos/models/transaction_model.dart';

BillModel billModelFromJson(String str) => BillModel.fromJson(json.decode(str));
List<BillModel> billModelListFromJson(String str) =>
    List<BillModel>.from(json.decode(str).map((x) => BillModel.fromJson(x)));
String billModelToJson(BillModel data) => json.encode(data.toJson());

class BillModel {
  BillModel(
      {this.billNo,
      this.billDate,
      this.branchNo,
      this.cardBalance,
      this.customer,
      this.customerNo,
      this.customerName,
      this.payType,
      this.employeeNo,
      this.isPayment,
      this.billSubTotal,
      this.billDiscount,
      this.billTotalBv,
      this.billVatAmount,
      this.billVat,
      this.billTotal,
      this.payAmount,
      this.pos,
      this.receiveCash,
      this.receiveCard,
      this.status,
      this.billItem,
      this.timestamp,
      this.billTrans,
      this.tmRef,
      this.cardNumber,
      this.card});

  String? billNo;
  String? billDate;
  String? branchNo;
  String? cardBalance;
  Customer? customer;
  String? customerNo;
  String? customerName;
  String? payType;
  String? employeeNo;
  String? isPayment;
  double? billSubTotal;
  double? billDiscount;
  double? billTotalBv;
  double? billVatAmount;
  double? billVat;
  double? billTotal;
  double? payAmount;
  String? pos;
  double? receiveCash;
  double? receiveCard;
  String? status;
  List<BillItem>? billItem;
  String? timestamp;
  bool? billTrans;
  String? tmRef;
  String? cardNumber;
  CardInfo? card;

  Map<String, dynamic> toMap() {
    return {
      'BillNo': billNo,
      'BillDate': billDate,
      'BranchNo': branchNo,
      'CardBalance': cardBalance,
      'Customer': jsonEncode(customer),
      "CustomerNo": customerNo,
      "CustomerName": customerName,
      'PayType': payType,
      'EmployeeNo': employeeNo,
      'IsPayment': isPayment,
      'BillSubTotal': billSubTotal,
      'BillDiscount': billDiscount,
      'BillTotalBv': billTotalBv,
      'BillVatAmount': billVatAmount,
      'BillVat': billVat,
      'BillTotal': billTotal,
      'PayAmount': payAmount,
      'POS': pos,
      'ReceiveCash': receiveCash,
      'ReceiveCard': receiveCard,
      'Status': status,
      'BillItem': jsonEncode(billItem),
      'Timestamp': timestamp,
      'BillTrans': billTrans,
      'TMRef': tmRef,
      'CardNumber': cardNumber
    };
  }
  // BillModel.fromMap(Map<String, dynamic> map)
  //     : billNo = map['id'],
  //       billDate = map['name'],
  //       description = map['description'],
  //       image = map['image'],
  //       price = double.parse(map['price']);

  factory BillModel.fromJson(Map<String, dynamic> json) => BillModel(
      billNo: json["BillNo"] ?? "",
      billDate: json["BillDate"] ?? "",
      branchNo: json["BranchNo"] ?? "",
      cardBalance: json["CardBalance"] ?? "0",
      customer: (json["Customer"] != null)
          ? Customer.fromJson(json["Customer"])
          : null,
      payType: json["PayType"] ?? "",
      employeeNo: json["EmployeeNo"] ?? "",
      isPayment: json["IsPayment"] ?? "",
      billSubTotal: json["BillSubTotal"]?.toDouble(),
      billDiscount: json["BillDiscount"]?.toDouble(),
      billTotalBv: json["BillTotalBV"]?.toDouble(),
      billVatAmount: json["BillVatAmount"]?.toDouble(),
      billVat: json["BillVat"]?.toDouble(),
      billTotal: json["BillTotal"].toDouble(),
      payAmount: json["PayAmount"]?.toDouble(),
      pos: json["POS"] ?? "",
      receiveCash: json["ReceiveCash"]?.toDouble(),
      receiveCard: json["ReceiveCard"]?.toDouble(),
      status: json["Status"] ?? "",
      tmRef: json["TMRef"],
      cardNumber: json["CardNumber"] ?? "",
      billItem: List<BillItem>.from(
          json["BillItem"]?.map((x) => BillItem.fromJson(x))),
      card: json["Card"]);
  Map<String, dynamic> toJson() => {
        "BillNo": billNo,
        "BillDate": billDate,
        "BranchNo": branchNo,
        "Customer": (customer != null) ? customer!.toJson() : null,
        "PayType": payType,
        "EmployeeNo": employeeNo,
        "IsPayment": isPayment,
        "BillSubTotal": billSubTotal,
        "BillDiscount": billDiscount,
        "BillTotalBV": billTotalBv,
        "BillVatAmount": billVatAmount,
        "BillVat": billVat,
        "BillTotal": billTotal,
        "PayAmount": payAmount,
        "POS": pos,
        "ReceiveCash": receiveCash,
        "ReceiveCard": receiveCard,
        "Status": status,
        "TMRef": tmRef,
        "BillItem": List<dynamic>.from(billItem!.map((x) => x.toJson())),
        "CardNumber": cardNumber
      };
}

class BillItem {
  BillItem({
    this.billNo,
    this.productId,
    this.sku,
    this.productName,
    this.cost,
    this.qty,
    this.price,
    this.discount,
    this.total,
    this.lotId,
  });

  String? billNo;
  String? productId;
  String? sku;
  String? productName;
  String? cost;
  int? qty;
  double? price;
  double? discount;
  String? total;
  String? lotId;

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        billNo: json["BillNo"],
        productId: json["ProductID"],
        sku: json["SKU"],
        productName: json["ProductName"],
        cost: json["Cost"],
        qty: json["Qty"],
        price: json["Price"]?.toDouble(),
        discount: json["Discount"]?.toDouble(),
        total: json["Total"] ?? "0",
        lotId: json["LotID"],
      );

  Map<String, dynamic> toJson() => {
        "BillNo": billNo,
        "ProductID": productId,
        "SKU": sku,
        "ProductName": productName,
        "Cost": cost,
        "Qty": qty,
        "Price": price,
        "Discount": discount,
        "Total": total,
        "LotID": lotId,
      };
}

class Customer {
  Customer({this.customerNo, this.fName, this.lName, this.balance});

  String? customerNo;
  String? fName;
  String? lName;
  String? balance;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        customerNo: json["CustomerNo"],
        fName: json["FName"],
        lName: json["LName"],
        balance: json["Balance"],
      );

  Map<String, dynamic> toJson() => {
        "CustomerNo": customerNo,
        "FName": fName,
        "LName": lName,
        "Balance": balance
      };
}

class CardInfo {
  CardInfo(
      {this.cardNumber,
      this.accName,
      this.balance,
      this.payAmount,
      this.amount});
  String? cardNumber;
  String? accName;
  String? balance;
  String? payAmount;
  String? amount;
}
