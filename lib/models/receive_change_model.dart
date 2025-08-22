// To parse this JSON data, do
//
//     final transactionModel = transactionModelFromJson(jsonString);

import 'dart:convert';

POSReceiveChangeModel posReceiveChangeFromJson(String str) => POSReceiveChangeModel.fromJson(json.decode(str));
List<POSReceiveChangeModel> posReceiveChangeModelFromJson(String str) => List<POSReceiveChangeModel>.from(json.decode(str).map((x) => POSReceiveChangeModel.fromJson(x)));

String posReceiveChangeModelToJson(List<POSReceiveChangeModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
String posRecToJson(POSReceiveChangeModel data) => json.encode(data.toJson());
class POSReceiveChangeModel {
  POSReceiveChangeModel({
    this.id,
    this.posID,
    this.receiveChange,
    this.userNo,
    this.createdAt,
    this.updatedAt
  });

  int? id;
  int? posID;
  double? receiveChange;
  String? userNo;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory POSReceiveChangeModel.fromJson(Map<String, dynamic> json) => POSReceiveChangeModel(
    id: json["id"],
    posID: json["POSID"],
    receiveChange: double.parse(json["ReceiveChange"]),
    userNo: json["UserNo"],
    createdAt: DateTime.parse(json["Created_at"]),
    updatedAt: DateTime.parse(json["Updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "POSID": posID,
    "ReceiveChange": receiveChange,
    "UserNo": userNo,
    "Created_at": createdAt!.toIso8601String(),
    "Updated_at": updatedAt!.toIso8601String(),
  };
}
