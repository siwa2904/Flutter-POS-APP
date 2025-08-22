// To parse this JSON data, do
//
//     final transactionModel = transactionModelFromJson(jsonString);

import 'dart:convert';

List<TransactionModel> transactionModelFromJson(String str) => List<TransactionModel>.from(json.decode(str).map((x) => TransactionModel.fromJson(x)));

String transactionModelToJson(List<TransactionModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TransactionModel {
  TransactionModel({
    this.transNo,
    this.transDate,
    this.transTitle,
    this.transAmount,
    this.shopName,
    this.transAfterAmount,
    this.transType,
    this.topupOrder,
    this.topupPay,
this.topupStatus
  });

  String? transNo;
  DateTime? transDate;
  String? transTitle;
  String? transAmount;
  String? shopName;
  String? transAfterAmount;
  String? transType;
  String? topupOrder;
  String? topupPay;
  String? topupStatus;

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    transNo: json["TransNo"],
    transDate: DateTime.parse(json["TransDate"]),
    transTitle: json["TransTitle"],
    transAmount: json["TransAmount"],
    shopName: json["ShopName"],
    transAfterAmount: json["TransAfterAmount"],
    transType: json["TransType"],
    topupOrder: json["TopupOrder"],
    topupPay: json["TopupPay"],
    topupStatus: json["TopupStatus"],
  );

  Map<String, dynamic> toJson() => {
    "TransNo": transNo,
    "TransDate": transDate!.toIso8601String(),
    "TransTitle": transTitle,
    "TransAmount": transAmount,
    "ShopName": shopName,
    "TransAfterAmount": transAfterAmount,
    "TransType": transType,
    "TopupOrder":topupOrder,
    "TopupPay":topupPay,
    "TopupStatus":topupStatus
  };
}



class cardModel{
  String? CardNumber;
  bool? IsActive;
}
