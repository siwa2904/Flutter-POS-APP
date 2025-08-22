import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mispos/controllers/cmd_controller.dart';
import 'package:mispos/models/bill_model.dart';
import 'package:mispos/models/order_model.dart';
import 'package:presentation_displays/secondary_display.dart';

import 'package:google_fonts/google_fonts.dart';


class PayCashPage extends StatelessWidget {
  // const CustomerDisplayPage({Key? key}) : super(key: key);

  CmdController cdc = Get.find<CmdController>();
  var scrollController = ScrollController();

  PayCashPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SecondaryDisplay(
            callback: (arguments) {
              print("SetDisplay");
              print(arguments);
              print("=================");

              print("################");
              if(arguments!=null){
                print("################");
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
                                flex: 60,
                                child: Container(
                                  alignment: Alignment.topCenter,
                                  color: Colors.redAccent,
                                  child: Column(
                                    children: [
                                      Container(
                                        height:100,
                                        padding: EdgeInsets.all(15),
                                        color: Colors.blueGrey,
                                        child:
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Text("รับเงิน/เงินทอน",style: GoogleFonts.maitree(fontSize: 25),)),
                                          Expanded(child:
                                          Text(cdc.orderDis.value!.receiveCash.toString()+" / "+ cdc.change.toString(),style: GoogleFonts.maitree(fontSize: 32)))
                                        ],
                                      ),),
                                      Text("Customer Display ADV")
                                    ],
                                  ),
                                )),
                            Expanded(
                                flex: 40,
                                child: PreferredSize(
                                    preferredSize:
                                        Size.fromHeight(kToolbarHeight),
                                    child: Container(
                                        alignment: Alignment.topCenter,
                                        child: SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            child: Container(
                                                constraints: BoxConstraints(
                                                  // maxHeight: (cdc
                                                  //             .customerDisplay
                                                  //             .value
                                                  //             .items
                                                  //             ?.length ??
                                                  //         0) *
                                                  //     115,
                                                  maxWidth: Get.width,
                                                ),
                                                child: Column(children: [
                                                  Container(
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      child: Column(children: [
                                                        Container(
                                                            // height: 80,
                                                            padding:
                                                                EdgeInsets.only(
                                                                    top: 20,
                                                                    bottom: 20),
                                                            decoration: BoxDecoration(
                                                                border: Border(
                                                                    bottom: BorderSide(
                                                                        width:
                                                                            1,
                                                                        color: Colors
                                                                            .grey,
                                                                        style: BorderStyle
                                                                            .solid))),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  "ยอดรวม",
                                                                  style: GoogleFonts
                                                                      .maitree(
                                                                          fontSize:
                                                                              20),
                                                                ),
                                                                Text(
                                                                  cdc
                                                                      .orderDis
                                                                      .value
                                                                      .billTotal
                                                                      .toString(),
                                                                  style: GoogleFonts.maitree(
                                                                      fontSize:
                                                                          25,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                )
                                                              ],
                                                            )),
                                                        SizedBox(
                                                          height: 20,
                                                        ),
                                                        Container(
                                                            height: Get.height -
                                                                120,
                                                            child: ListView
                                                                .builder(
                                                                    controller:
                                                                        scrollController,
                                                                    padding:
                                                                        EdgeInsets
                                                                            .only(
                                                                      bottom: MediaQuery.of(
                                                                              context)
                                                                          .padding
                                                                          .bottom,
                                                                    ),
                                                                    itemCount: (cdc
                                                                            .orderDis
                                                                            .value
                                                                            .billItem
                                                                            ?.length ??
                                                                        0),
                                                                    scrollDirection:
                                                                        Axis
                                                                            .vertical,
                                                                    itemBuilder:
                                                                        (context,
                                                                            index) {
                                                                      return Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Expanded(
                                                                              flex: 70,
                                                                              child: AutoSizeText(
                                                                                cdc.orderDis.value.billItem![index].productName.toString() + " ",
                                                                                style: GoogleFonts.maitree(),
                                                                                maxLines: 1,
                                                                              )),
                                                                          Expanded(
                                                                              flex: 10,
                                                                              child: Text("X " + cdc.orderDis.value.billItem![index].qty.toString())),
                                                                          Expanded(
                                                                              flex: 20,
                                                                              child: Text(cdc.orderDis.value.billItem![index].price.toString(), textAlign: TextAlign.end, style: GoogleFonts.maitree(fontSize: 18)))
                                                                        ],
                                                                      );
                                                                    })),
                                                      ]))
                                                ]))))))
                          ]))
                ])))));
  }
}
