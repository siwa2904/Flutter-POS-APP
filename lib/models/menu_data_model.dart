
import 'dart:convert';

List<MenuDataModel> menuDataModelFromJson(String str) => List<MenuDataModel>.from(json.decode(str).map((x) => MenuDataModel.fromJson(x)));

String menuDataModelToJson(List<MenuDataModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class MenuDataModel {
  MenuDataModel({
    this.name,
    this.isUse,
    this.type,
    this.title,
    this.iconType,
    this.icon,
    this.color,
    this.navigate,
    this.topupWay
  });

  String? name;
  bool? isUse;
  String? type;
  String? title;
  String? iconType;
  String? icon;
  String? color;
  String? navigate;
  String? topupWay;

  factory MenuDataModel.fromJson(Map<String, dynamic> json) => MenuDataModel(
    name: json["name"],
    isUse: json["isUse"],
    type: json["type"],
    title: json["title"],
    iconType: json["icon_type"],
    icon: json["icon"].toString(),
    color: json["color"],
    navigate: json["navigate"],
    topupWay: json["topupWay"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "isUse": isUse,
    "type": type,
    "title": title,
    "icon_type":iconType,
    "icon": icon,
    "color": color,
    "navigate": navigate,
    "topupWay":topupWay
  };
}
