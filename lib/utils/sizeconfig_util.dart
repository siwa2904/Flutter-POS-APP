import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SizeConfig{
  static double? _mediaQueryData;
  static double? screenWidth;
  static double? screenHeigth;
  static double? blockSizeHorizontal;
  static double? blockSizeVertical;

  void init(BuildContext context){
    // _mediaQueryData = Get.width;
    screenWidth = Get.width;
    screenHeigth =Get.height;
    blockSizeHorizontal = (screenWidth! / 100);
    blockSizeVertical = screenHeigth!/100;
}
}