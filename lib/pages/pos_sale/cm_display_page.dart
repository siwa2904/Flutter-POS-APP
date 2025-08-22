import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mispos/controllers/cmd_controller.dart';
import 'package:presentation_displays/secondary_display.dart';
import 'package:google_fonts/google_fonts.dart';

class CmDisplayPage extends StatelessWidget {
  // const CustomerDisplayPage({Key? key}) : super(key: key);
  List<int> nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  CmdController cdc = Get.find<CmdController>();
  var scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SecondaryDisplay(
            callback: (arguments) {
              print("SetDisplay CM");
              print(arguments);
              print("================= 2326671896 ");
              print(arguments["cardBalance"]);
              print("################");
              if (arguments != null) {
                cdc.setDataDisplay(arguments);
              }
              print("*********");
            },
            child: Obx(() => Container(
                height: Get.height,
                child: Column(children: [
                  Container(
                      height: Get.height,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                flex: 40,
                                child: Stack(
                                  children: [
                                    Positioned(
                                        top:
                                            100, //display after the height of top widtet
                                        bottom:
                                            100, //display untill the height of bottom widget
                                        left: 0,
                                        right: 0,

                                        //mention top, bottom, left, right, for full size widget
                                        child: SingleChildScrollView(
                                          //content widget tree
                                          child: Column(
                                            children: cdc
                                                .orderDis.value.billItem!
                                                .map((item) {
                                              return Container(
                                                width: double
                                                    .infinity, //width 100%;
                                                // height: 80,
                                                padding: EdgeInsets.only(
                                                    left: 20,
                                                    right: 20,
                                                    top: 15),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                        flex: 7,
                                                        child: Text(
                                                            item.productName
                                                                .toString(),
                                                            style: GoogleFonts
                                                                .maitree())),
                                                    Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                            "(" +
                                                                item.qty
                                                                    .toString() +
                                                                ")",
                                                            style: GoogleFonts
                                                                .maitree(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold))),
                                                    Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          item.price.toString(),
                                                          style: GoogleFonts
                                                              .maitree(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                          textAlign:
                                                              TextAlign.end,
                                                        ))
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        )),

                                    //set top/bottom widget after content,
                                    //other wise it wil go below content
                                    Positioned(
                                        //position at top
                                        top: 0,
                                        left: 0,
                                        right:
                                            0, //set left right to 0 for 100% width
                                        child: Container(
                                            height: 100,
                                            padding: EdgeInsets.only(
                                                top: 20, left: 20),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "รายการ",
                                                  style: GoogleFonts.maitree(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ))),

                                    Positioned(
                                        //position at bottom
                                        bottom: 0,
                                        left: 0,
                                        right:
                                            0, //set left right to 0 for 100% width
                                        child: Container(
                                          //your bototm widget tree
                                          height: 100,
                                          padding: EdgeInsets.only(
                                              top: 20, left: 20, right: 20),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "ยอดรวม",
                                                style: GoogleFonts.maitree(
                                                    color: Colors.deepOrange,
                                                    fontSize: 32,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                cdc.orderDis.value.billTotal
                                                    .toString(),
                                                style: GoogleFonts.maitree(
                                                    fontSize: 32,
                                                    color: Colors.deepOrange,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            ],
                                          ),
                                        )),
                                  ],
                                )),
                            Expanded(
                                flex: 60,
                                child: Container(
                                  alignment: Alignment.topCenter,
                                  color: Colors.white,
                                  child: Column(
                                    children: [
                                      Container(
                                        color: Colors.deepOrange,
                                        padding: EdgeInsets.all(15),
                                        child: Row(
                                          children: [
                                            Text("ลูกค้า  ",
                                                style: GoogleFonts.maitree(
                                                    fontSize: 32,
                                                    color: Colors.white)),
                                            Text(
                                                "${cdc.orderDis.value.customer?.fName ?? ''} ${cdc.orderDis.value.customer?.lName ?? ''}",
                                                style: GoogleFonts.maitree(
                                                    fontSize: 32,
                                                    color: Colors.white))
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 150,
                                        padding: EdgeInsets.all(15),
                                        color: Colors.deepOrange,
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                  child: Column(children: [
                                                Text(
                                                  "ยอดรวม",
                                                  style: GoogleFonts.maitree(
                                                      fontSize: 32,
                                                      color: Colors.white),
                                                ),
                                                Text(
                                                  cdc.orderDis.value!.billTotal
                                                      .toString(),
                                                  style: GoogleFonts.maitree(
                                                      fontSize: 32,
                                                      color: Colors.white),
                                                )
                                              ])),
                                              (cdc.orderDis.value.payType !=
                                                      "card")
                                                  ? Expanded(
                                                      child: Container(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  right: 20),
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Column(
                                                            children: [
                                                              Text(
                                                                "เงินทอน",
                                                                style: GoogleFonts.maitree(
                                                                    fontSize:
                                                                        32,
                                                                    color: Colors
                                                                        .white),
                                                                textAlign:
                                                                    TextAlign
                                                                        .end,
                                                              ),
                                                              Text(
                                                                  cdc.change
                                                                      .toString(),
                                                                  style: GoogleFonts.maitree(
                                                                      fontSize:
                                                                          32,
                                                                      color: Colors
                                                                          .white),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .end)
                                                            ],
                                                          )),
                                                    )
                                                  : Expanded(
                                                      child: Container(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  right: 20),
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Column(
                                                            children: [
                                                              Text(
                                                                "คงเหลือ",
                                                                style: GoogleFonts.maitree(
                                                                    fontSize:
                                                                        32,
                                                                    color: Colors
                                                                        .white),
                                                                textAlign:
                                                                    TextAlign
                                                                        .end,
                                                              ),
                                                              Text(
                                                                  cdc.orderDis.value.customer?.balance ?? '',
                                                                  style: GoogleFonts.maitree(
                                                                      fontSize:
                                                                          32,
                                                                      color: Colors
                                                                          .white),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .end)
                                                            ],
                                                          )),
                                                    )
                                            ]),
                                      ),

                                      Container(
                                        alignment: Alignment.center,
                                        // child:
                                        // Image(image: NetworkImage(Constant.serverURL+"/images/adv.webp"))
                                      )
                                      // Text("Customer Display ADV")
                                    ],
                                  ),
                                )),
                          ]))
                ])))));
  }
}
