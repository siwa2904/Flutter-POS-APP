import 'package:flutter/material.dart';

class MainMenuModel {

  bool? isUse;
  String? type;
  String? icon_type;
  IconData? icon;
  // Widget? icon;
  String? image;
  String? title;
  String? subtitle;
  Color? color;
  Function? child;

  MainMenuModel({
    this.isUse,
    this.type,
    this.icon_type,
    this.icon,
    this.image,
    this.title,
    this.subtitle,
    this.color,
    this.child
  });
}
