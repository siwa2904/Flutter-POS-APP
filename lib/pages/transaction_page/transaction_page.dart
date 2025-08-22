import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mispos/models/bill_model.dart';
import 'package:mispos/services/pos_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunmi_printer_plus/column_maker.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

import '../../controllers/home_controller.dart';
import '../../utils/constants.dart';

class TransactionPage extends StatelessWidget {
  final String? stdNo;
  final Color? primaryColor;
  final Color? backgroundColor;
  final AssetImage? backgroundImage;
  final double? delay;
  final Widget? child;
  final AnimationController? animationController;
  final String? order_id;
  final double? balance;
  TransactionPage(
      {Key? key,
      this.stdNo,
      this.primaryColor,
      this.backgroundColor,
      this.backgroundImage,
      this.delay,
      this.child,
      this.animationController,
      this.order_id,
      this.balance})
      : super(key: key);

  final transControl = Get.put(HomeController());

  ScrollController? _controller;
  Animation<double>? animation;
  bool isLoading = true;
  List<BillModel> trans = [];
  double topBarOpacity = 0.0;
  List<Widget> listViews = <Widget>[];
  List<Widget> listViews2 = <Widget>[];
  DateFormat? dateFormat;
  DateFormat? timeFormat;
  bool isPop = false;
  final formatter = new NumberFormat("#,###.00");
  var formatterDate = DateFormat('d MMM y HH:mm', 'th');
  // RefreshController _refreshController =
  //     RefreshController(initialRefresh: false);
  bool _switchValue = true;
  var scrollController = ScrollController();
  // String myCardNo ="";

  StreamController<String> myCardNo = new StreamController<String>();
  // StreamController<cardModel> cardAction = new StreamController<cardModel>();
  late SharedPreferences prefs;

  Future<bool> getData() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  Widget _headerWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "รายการใช้จ่าย",
                  style: GoogleFonts.maitree(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<List<BillModel>> _getTransaction() async {
    List<BillModel> allTransactions = [];
    allTransactions = (await POSService().getReportToday()) as List<BillModel>;
    print(allTransactions[allTransactions.length - 1]);
    return allTransactions;
  }

  int paperSize = 0;
  Future<bool?> _bindingPrinter() async {
    final bool? result = await SunmiPrinter.bindingPrinter();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    _bindingPrinter().then((bool? isBind) async {
      SunmiPrinter.paperSize().then((int size) {
        paperSize = size;
        print('paperSize: $paperSize');
      });
    });
    // transControl.getTransaction(stdNo);
    transControl.getReportList();
    return Obx(() =>  Scaffold(
        appBar: AppBar(
            title: Text(
              "รายการใช้จ่าย",
              style: GoogleFonts.maitree(),
            ),
            elevation: 0,
            backgroundColor: HexColor("#FF1654")),
        body:  Center(
            child:  Container(
          child: CustomScrollView(controller: _controller, slivers: <Widget>[
            (transControl.billAll.isNotEmpty)
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                        (_, index) => GestureDetector(
                            onTap: () async {},
                            child: Container(
                                padding: const EdgeInsets.only(
                                    top: 10, left: 20, bottom: 10),
                                margin:
                                    const EdgeInsets.only(left: 0, right: 10, top: 5),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                        width: 1.0,
                                        color: HexColor("#eeeeee"),
                                        style: BorderStyle.solid),
                                  ),
                                ),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Icon(
                                            Icons.calendar_today,
                                            color: Colors.grey.withOpacity(0.5),
                                            size: 20,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 4.0),
                                            child: Text(
                                              formatterDate.format(
                                                  DateTime.parse(transControl
                                                      .billAll[index]
                                                      .billDate!)),
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.maitree(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 20,
                                                letterSpacing: 0.0,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: <Widget>[
                                          Padding(
                                              padding:
                                                  EdgeInsets.only(right: 10),
                                              child: Icon(
                                                Icons.add_circle,
                                                color: HexColor("#e63b56"),
                                                size: 20,
                                              )
                                              // Icon(((item.type=='0')?Icons.remove_circle:Icons.add_circle)),
                                              ),
                                          Expanded(
                                            flex: 5,
                                            child: Text(
                                                transControl.billAll[index]
                                                        .billNo! +
                                                    " [ " +
                                                    (transControl.billAll[index]
                                                                .payType ==
                                                            '0'
                                                        ? 'บัตร'
                                                        :(transControl.billAll[index]
                                                        .payType=='1') ?'เงินสด':'เงินเชื่อ') +
                                                    "]",
                                                style: GoogleFonts.maitree(
                                                  color: Colors.black,
                                                  fontSize: 25,
                                                )),
                                          ),
                                          Expanded(
                                              flex: 2,
                                              child: Column(
                                                children: [
                                                  Text(
                                                      formatter
                                                              .format(transControl
                                                                  .billAll[
                                                                      index]
                                                                  .billTotal!)
                                                              .toString() +
                                                          " บ.",
                                                      textAlign: TextAlign.end,
                                                      style:
                                                          GoogleFonts.maitree(
                                                        color:
                                                            HexColor('#e63b56'),
                                                        fontSize: 32,
                                                      )),
                                                  Container()
                                                ],
                                              )),
                                          Expanded(
                                              flex: 1,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () async {
                                                    await printSlip(transControl
                                                        .billAll[index]);

                                                    // cdc.keyReceiveCash('2');
                                                  },
                                                  child: Container(
                                                      margin: EdgeInsets.all(1),
                                                      padding:
                                                          EdgeInsets.all(5),
                                                      color: Colors.blue,
                                                      child: Text(
                                                        "พิมพ์สลิป",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize: 18,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ))
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Icon(
                                            Icons.desktop_mac,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 4.0),
                                            child: Text(
                                              transControl.billAll[index]
                                                  .customer!.fName!,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.maitree(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 20,
                                                letterSpacing: 0.0,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ]))),
                        childCount: transControl.billAll.length))
                : SliverToBoxAdapter(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                        SizedBox(
                          height: 80,
                        ),
                        Text(
                          (transControl.loadingTrans.value)
                              ? "กำลังดึงข้อมูล"
                              : "ไม่มีข้อมูล",
                          style: GoogleFonts.maitree(color: Colors.grey),
                        )
                      ])),
          ]),
        ))));
  }

  Widget getMainListViewUI() {
    return FutureBuilder(
      future: getData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox();
        } else {
          return ListView.builder(
            controller: scrollController,
            itemCount: listViews.length,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              return listViews[index];
            },
          );
        }
      },
    );
  }
  final mc = GetStorage();
  printSlip(BillModel bm) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (mc.read(Constant.POS_CODE) == null) {
      mc.write(Constant.POS_CODE, "TNK00${mc.read(Constant.posNo)}");
    }
    Get.snackbar("Print",prefs.getString(Constant.ShopName)!);
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.setFontSize(SunmiFontSize.MD);
    await SunmiPrinter.printText(prefs.getString(Constant.ShopName)!);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.printText('ใบเสร็จรับเงินอย่างย่อ');
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.line();
    await SunmiPrinter.printText('Trn#' + bm.billNo.toString());
    await SunmiPrinter.printText('pos#' + mc.read(Constant.POS_CODE));
    await SunmiPrinter.printText('วันที่ ' + bm.billDate.toString());
    await SunmiPrinter.printText('ลูกค้า ' +
        bm.customer!.customerNo.toString() +
        bm.customer!.fName.toString());
    await SunmiPrinter.line();
print(bm.billItem);
    for (var element in bm.billItem!) {
      print(element);
      var prdName = "";
      int max = (element.productName.toString().length > 50)
          ? 50
          : element.productName.toString().length;
      for (int i = 0; i < max; i++) {
        if (element.productName.toString()[i] != " ") {
          prdName = prdName + element.productName.toString()[i];
        }
      }
      print(prdName + "::" + element.productName.toString().length.toString());

      // await SunmiPrinter.setFontSize(SunmiFontSize.SM);
      //
      await SunmiPrinter.printText("(" +
          element.qty.toString() +
          ")" +
          prdName +
          " [" +
          element.price.toString() +
          "]");
      await SunmiPrinter.setAlignment(SunmiPrintAlign.RIGHT);
      await SunmiPrinter.printText(element.total.toString());
      await SunmiPrinter.line(len: 48);
      // await SunmiPrinter.printRow(cols: [
      //   ColumnMaker(
      //     text: prdName,
      //     width: 50,
      //     align: SunmiPrintAlign.LEFT,
      //   ),
      //   // ColumnMaker(
      //   //     text: element.price.toString(),
      //   //     width: 6,
      //   //     align: SunmiPrintAlign.RIGHT),
      //   ColumnMaker(
      //       text: element.total.toString(),
      //       width: 6,
      //       align: SunmiPrintAlign.RIGHT),
      // ]);
    }

    // await SunmiPrinter.line();
    await SunmiPrinter.printRow(cols: [
      ColumnMaker(text: 'รวม', width: 25, align: SunmiPrintAlign.LEFT),
      ColumnMaker(
          text: bm.billTotal.toString(),
          width: 5,
          align: SunmiPrintAlign.RIGHT),
    ]);
    await SunmiPrinter.bold();
    await SunmiPrinter.printText('รับเงิน/ทอน  #  ' +
        bm.receiveCash.toString() +
        " / " +
        (bm.receiveCash! - bm.billTotal!).toString());
    // await SunmiPrinter.printRow(cols: [
    //   ColumnMaker(text: 'เงินสด/ทอน', width: 30, align: SunmiPrintAlign.LEFT),
    //   ColumnMaker(
    //       text: cdc.order.value.receiveCash.toString()+" / "+ (cdc.order.value.receiveCash!-cdc.order.value.total!).toString(),
    //       width: 20,
    //       align: SunmiPrintAlign.RIGHT),
    //
    // ]);

    // await SunmiPrinter.printRow(cols: [
    //   ColumnMaker(text: 'CHINESE TEXT', width: 15, align: SunmiPrintAlign.LEFT),
    //   ColumnMaker(text: '風俗通義', width: 15, align: SunmiPrintAlign.LEFT),
    // ]);
    // await SunmiPrinter.printRow(cols: [
    //   ColumnMaker(text: '風俗通義', width: 15, align: SunmiPrintAlign.LEFT),
    //   ColumnMaker(text: '風俗通義', width: 15, align: SunmiPrintAlign.LEFT),
    // ]);

    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.line();
    await SunmiPrinter.bold();
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.printText('ขอบคุณที่สนับสนุนกิจการของเรือนจำ');
    await SunmiPrinter.printText('รายได้จะนำกลับไปพัฒนาความเป็นอยู่ลูกหลานของท่าน');
    await SunmiPrinter.lineWrap(2);
    await SunmiPrinter.printText('------------------------------');
    await SunmiPrinter.lineWrap(2);
    await SunmiPrinter.cut();
    await SunmiPrinter.exitTransactionPrint(true);
  }
}

class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path p = new Path();
    p.lineTo(size.width, 0.0);
    p.lineTo(size.width, size.height * 0.85);
    p.arcToPoint(
      Offset(0.0, size.height * 0.85),
      radius: const Radius.elliptical(50.0, 10.0),
      rotation: 0.0,
    );
    p.lineTo(0.0, 0.0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return true;
  }
}
