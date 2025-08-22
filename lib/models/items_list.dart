// To parse this JSON data, do
//
//     final productModel = productModelFromJson(jsonString);

import 'dart:convert';

class ItemsListModel {
  ItemsListModel({
    this.productId,
    this.name,
    this.quantity,
    this.price,
    this.imageUrl,
    this.total,
  });

  String? productId;
  String? name;
  int? quantity;
  String? price;
  String? imageUrl;
  String? total;
 // cat: Cat.fromJson(json["cat"]),


}

