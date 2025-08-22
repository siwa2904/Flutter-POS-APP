// To parse this JSON data, do
//
//     final customerModel = customerModelFromJson(jsonString);

import 'dart:convert';

List<CustomerModel> customerModelFromJson(String str) =>
    List<CustomerModel>.from(
        json.decode(str).map((x) => CustomerModel.fromJson(x)));

String customerModelToJson(List<CustomerModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CustomerModel {
  CustomerModel(
      {this.credit,
      this.customerName,
      this.customerNo,
      this.financialAmount,
      this.financialBalance,
      this.isMember,
      this.memberCard});

  double? credit;
  String? customerName;
  String? customerNo;
  double? financialAmount;
  double? financialBalance;
  String? isMember;
  String? memberCard;

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
      credit: double.parse(json["Credit"]),
      customerName: json["CustomerName"],
      customerNo: json["CustomerNo"],
      financialAmount: double.parse(json["FinancialAmount"]),
      financialBalance: double.parse(json["FinancialBalance"]),
      isMember: json["IsMember"],
      memberCard: json["MemberCard"]);

  Map<String, dynamic> toJson() => {
        "Credit": credit,
        "CustomerName": customerName,
        "CustomerNo": customerNo,
        "FinancialAmount": financialAmount,
        "FinancialBalance": financialBalance,
        "IsMember": isMember,
        "MemberCard": memberCard,
      };
}
