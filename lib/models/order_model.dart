// To parse this JSON data, do
//
//     final customerDisplayModel = customerDisplayModelFromJson(jsonString);

import 'dart:convert';

OrderModel customerDisplayModelFromJson(String str) =>
    OrderModel.fromJson(json.decode(str));

String customerDisplayModelToJson(OrderModel data) =>
    json.encode(data.toJson());

class OrderModel {
  OrderModel(
      {this.billId,
      this.customerId,
      this.total,
      this.discount,
      this.customerName,
      this.payType,
      this.cardNumber,
      this.receive,
      this.receiveCash,
      this.change,
      this.items,
      this.timestamp});

  String? billId;
  String? customerId;
  double? total;
  double? discount;
  String? customerName;
  String? payType;
  String? cardNumber;
  int? receive;
  int? change;
  double? receiveCash;
  List<Item>? items;
  String? timestamp;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        billId: json["billID"],
        customerId: json["customerID"],
        total: json["total"],
        discount: json["discount"],
        customerName: json["customerName"],
        payType: json["payType"],
        cardNumber: json["cardNumber"],
        receive: json["receive"],
        receiveCash: json["receiveCash"],
        change: json["change"],
        items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "billID": billId,
        "customerID": customerId,
        "total": total,
        "discount": discount,
        "customerName": customerName,
        "payType": payType,
        "cardNumber": cardNumber,
        "receive": receive,
        "receiveCash": receiveCash,
        "change": change,
        "items": (items != null)
            ? List<dynamic>.from(items!.map((x) => x.toJson()))
            : [],
      };
}

class Item {
  Item({
    this.productId,
    this.productName,
    this.price,
    this.quantity,
    this.total,
  });

  String? productId;
  String? productName;
  double? price;
  int? quantity;
  double? total;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        productId: json["productID"],
        productName: json["productName"],
        price: json["price"],
        quantity: json["quantity"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "productID": productId,
        "productName": productName,
        "price": price,
        "quantity": quantity,
        "total": total,
      };
}
