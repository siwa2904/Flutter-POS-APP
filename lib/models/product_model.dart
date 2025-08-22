// To parse this JSON data, do
//
//     final productModel = productModelFromJson(jsonString);

import 'dart:convert';

List<ProductModel> productModelFromJson(String str) => List<ProductModel>.from(
    json.decode(str).map((x) => ProductModel.fromJson(x)));

String productModelToJson(List<ProductModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ProductModel {
  ProductModel(
      {this.productId,
      this.name,
      this.barcode,
      this.qty,
      this.categoryId,
      this.price1,
      this.image,
      this.isUse,
      this.cutStock,
      this.imageUrl,
      this.skuSelect,
      this.sku,
      this.favorite});

  String? productId;
  String? name;
  String? barcode;
  int? qty;
  int? categoryId;
  String? price1;
  String? image;
  String? isUse;
  bool? cutStock;
  String? imageUrl;
  String? skuSelect;
  List<SKUModel>? sku;
  int? favorite;

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
      productId: json["ProductID"],
      name: json["Name"],
      barcode: json["Barcode"],
      categoryId: json["CategoryID"],
      price1: json["Price1"],
      image: json["Image"],
      isUse: json["IsUse"],
      cutStock: json["CutStock"] == '1',
      imageUrl: json["ImageUrl"],
      sku: List<SKUModel>.from(json["SKU"]?.map((x) => SKUModel.fromJson(x))),
      favorite: 0
      // cat: Cat.fromJson(json["cat"]),
      );

  Map<String, dynamic> toJson() => {
        "ProductID": productId,
        "SKU": sku,
        "Name": name,
        "Barcode": barcode,
        "CategoryID": categoryId,
        "Price1": price1,
        "Image": image,
        "IsUse": isUse,
        "CutStock": cutStock,
        "ImageUrl": imageUrl,
        "SkuSelect": skuSelect,
        'SKU': jsonEncode(sku),
    "Favorite":favorite
      };
}

class SKUModel {
  SKUModel({this.sku, this.productId, this.description, this.price});
  String? sku;
  String? productId;
  String? description;
  int? price;

  factory SKUModel.fromJson(Map<String, dynamic> json) => SKUModel(
        sku: json["SKU"],
        productId: json["ProductID"],
        description: json["Description"],
        price: json["Price"],
      );
}

List<Cat> catFromJson(String str) =>
    List<Cat>.from(json.decode(str).map((x) => Cat.fromJson(x)));

String catToJson(List<Cat> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Cat {
  Cat({
    this.categoryId,
    this.categoryName,
    this.isUse,
    this.createdAt,
    this.updatedAt,
  });

  int? categoryId;
  String? categoryName;
  String? isUse;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory Cat.fromJson(Map<String, dynamic> json) => Cat(
        categoryId: json["CategoryID"],
        categoryName: json["CategoryName"],
        isUse: json["IsUse"],
        createdAt: DateTime.parse(json["Created_at"]),
        updatedAt: DateTime.parse(json["Updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "CategoryID": categoryId,
        "CategoryName": categoryName,
        "IsUse": isUse,
        "Created_at": createdAt!.toIso8601String(),
        "Updated_at": updatedAt!.toIso8601String(),
      };
}


class FavoritModel {
   String produncID;
   DateTime? create;

  FavoritModel({
    required this.produncID,
     this.create
  });

  Map toJson() {
    return {
      'produncID': produncID,
      'create': create
    };
  }

  factory FavoritModel.fromJson(Map<String, dynamic> json) {
    return FavoritModel(
      produncID: json['produncID'] as String,
      create: json['create']
    );
  }

  factory FavoritModel.fromJsonFile(Map<String, dynamic> json) {
    return FavoritModel(
      produncID: json['produncID'] as String,
      create: json['create']
    );
  }

}
