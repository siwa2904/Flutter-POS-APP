import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:find_dropdown/find_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mispos/controllers/orders_controller.dart';
import 'package:mispos/controllers/pos_controller.dart';
import 'package:mispos/models/bill_model.dart';
import 'package:mispos/models/customer_model.dart';
import 'package:mispos/models/product_model.dart';
import 'package:mispos/services/api_service.dart';
import 'package:mispos/utils/constants.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunmi_printer_plus/column_maker.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

import 'package:visibility_detector/visibility_detector.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';

import '../../app.dart';
import '../../services/pos_service.dart';

class PosSalePage extends StatelessWidget {
  OrdersController cdc = Get.put(OrdersController());
  POSController posCtrl = Get.put(POSController());
  DisplayManager displayManager = DisplayManager();
  List<Display?> displays = [];
  int paperSize = 0;
  ScrollController? _controller;
  var scrollController = ScrollController();
  double appbarHeight = 0;
  bool visible = true;
  int itmPerCol = 5;
  List<Widget> productWidget = [];
  List<Widget> menuPayWidget = [];
  List<ProductModel> products = [];

  bool isScanCard = false;

  // === Debounce card scan: เก็บเลขบัตรที่เข้ามาทั้งหมดในช่วง 500ms ===
  // แล้วเลือกเอาตัวที่ยาวที่สุด (ครบที่สุด) เพื่อป้องกัน:
  // 1) อ่านเบิ้ล (เรียก payCardToBill หลายครั้ง)
  // 2) เลขบัตรไม่ครบ (keyboard-wedge ส่งมาเป็นหลายก้อน)
  Timer? _cardDebounceTimer;
  List<String> _cardScanBuffer = [];
  bool _isCardProcessing = false;

  List<Widget> catWidget = [];
  List<Cat> catAll = [];
  String? selectedValueSingleDialog;
  FocusNode? focusNode1 = FocusNode();
  Future<bool?> _bindingPrinter() async {
    final bool? result = await SunmiPrinter.bindingPrinter();

    return result;
  }

  final fieldTextSearch = TextEditingController();
  final fieldTextSearch2 = TextEditingController();
  FocusNode mainFocusNode = FocusNode();

  gennerrateControl() {
    for (int i = 0; i < 20; i++) {
      _textcontroller.add(TextEditingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    // posCtrl.getProducts();
    _bindingPrinter().then((bool? isBind) async {
      SunmiPrinter.paperSize().then((int size) {
        paperSize = size;
      });
    });
    AppBar appBar = AppBar(
      title: const Text('หน้าขาย'),
    );
    listMenuPay(context);
    return VisibilityDetector(
        onVisibilityChanged: (VisibilityInfo info) {
          print("------");
          print(info.visibleFraction);
          print("++++++");
          visible = info.visibleFraction > 0;
        },
        key: const Key('visible-detector-key'),
        child: BarcodeKeyboardListener(
            bufferDuration: const Duration(milliseconds: 200),
            useKeyDownEvent: true,
            onBarcodeScanned: (barcode) {
              print("isScanCard: $isScanCard");
              print("<<<$barcode>>>");
              if (!visible || barcode == "") return;

              if (isScanCard) {
                // กำลังอยู่ในโหมดสแกนบัตร → ใช้ debounce
                _handleCardScan(barcode);
              } else {
                print(barcode);
                ProductModel findPro = findProduct(barcode);
                if (findPro.productId != null || findPro.productId != "") {
                  cdc.addItem(findPro);
                }
              }
            },
            // focusNode: mainFocusNode,
            child: Scaffold(
              appBar: appBar,
              resizeToAvoidBottomInset: false, //
              body: Wrap(
                children: [
                  SizedBox(
                      height: Get.height,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Expanded(
                                flex: 70,
                                child: Wrap(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      child: TextField(
                                          controller: fieldTextSearch,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            hintText:
                                                'ค้นหา ชื่อ รหัส หรือ barcode',
                                            contentPadding: EdgeInsets.only(
                                                top: 5,
                                                bottom: 5,
                                                left: 10,
                                                right: 10),
                                          ),
                                          onSubmitted: (value) async {
                                            var dd = await posCtrl
                                                .fillterProduct(value);
                                            if (dd.prsoductId != "") {
                                              cdc.addItem(dd);
                                              fieldTextSearch.clear();
                                              posCtrl.fillterProduct("");
                                            }

                                            /// do some stuff here
                                          }),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          flex: 10,
                                          child: Container(
                                            height: 80,
                                            child: listCate(context),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            height: 60,
                                            child: InkWell(
                                                onTap: () async {
                                                  posCtrl.getProducts();
                                                  posCtrl.getCategory();
                                                },
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  width: 120,
                                                  height: 30,
                                                  padding: EdgeInsets.all(5),
                                                  margin: EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                      color: Colors.blue,
                                                      border: Border.all(
                                                          width: 1,
                                                          color: Colors.blue),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
                                                  child: Text(
                                                    "Reload",
                                                    style: GoogleFonts.maitree(
                                                        color: Colors.white,
                                                        fontSize: 22),
                                                  ),
                                                )),
                                          ),
                                        )
                                      ],
                                    ),
                                    Container(
                                      height: Get.height,
                                      padding:
                                          const EdgeInsets.only(bottom: 200),
                                      child: Obx(() => listProduct(context)),
                                    )
                                  ],
                                ),
                              )),
                          Obx(() => Expanded(
                              flex: 30,
                              child: MediaQuery.removeViewPadding(
                                  context: context,
                                  // removeTop: true,
                                  child: Column(children: [
                                    listItems(context),
                                    Container(
                                        margin: const EdgeInsets.only(top: 10),
                                        height: 200,
                                        child: GridView.builder(
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 3,
                                                    childAspectRatio: 1
                                                    // childAspectRatio: MediaQuery.of(context).size.width /
                                                    //     (MediaQuery.of(context).size.height / 4)
                                                    ),
                                            itemCount: menuPayWidget.length,
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              return menuPayWidget[index];
                                            }))
                                  ]))))
                        ],
                      )),
                ],
              ),
            )));
  }

  listCatWidget() {
    List<Widget> list = [];
    List<Cat> cat = posCtrl.catego;
    if (cat.length > 0) {
      Widget listProd = InkWell(
          onTap: () async {
            await posCtrl.fillterProductCate("");
          },
          child: Container(
            alignment: Alignment.center,
            width: 120,
            height: 60,
            padding: EdgeInsets.all(5),
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.blueGrey,
                border: Border.all(width: 1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              "ทั้งหมด",
              style: GoogleFonts.maitree(color: Colors.white, fontSize: 22),
            ),
          ));
      list.add(listProd);
    }
    for (var i = 0; i < cat.length; i++) {
      Widget listProd = InkWell(
          onTap: () async {
            print(posCtrl.catego[i].categoryId.toString());
            await posCtrl
                .fillterProductCate(posCtrl.catego[i].categoryId.toString());
          },
          child: Container(
            alignment: Alignment.center,
            width: 120,
            height: 60,
            padding: EdgeInsets.all(5),
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.blueGrey,
                border: Border.all(width: 1),
                borderRadius: BorderRadius.circular(20)),
            child: AutoSizeText(
              posCtrl.catego[i].categoryName!,
              style: GoogleFonts.maitree(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),

            // Text(
            //   posCtrl.catego[i].categoryName!,
            //   style: GoogleFonts.maitree(color: Colors.white, fontSize: 22),
            // ),
          ));

      list.add(listProd);
    }
    catWidget = list;
    // return list;
  }

  listMenuPay(context) {
    menuPayWidget = [
      SizedBox.fromSize(
        // size: const Size(80, 56),
        child: Container(
          margin: const EdgeInsets.only(right: 5),
          decoration: const BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          child: InkWell(
            onTap: () async {
              await displayManager
                  .transferDataToPresentation(cdc.order.toJson());
              cdc.clear();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  FontAwesomeIcons.recycle,
                  color: Colors.white,
                ), // <-- Icon
                Text(
                  "เคลียร์",
                  style: GoogleFonts.maitree(color: Colors.white, fontSize: 30),
                ), // <-- Text
              ],
            ),
          ),
        ),
      ),
      // SizedBox.fromSize(
      //   // size: const Size(80, 56),
      //   child: Container(
      //     margin: const EdgeInsets.only(right: 5),
      //     decoration: const BoxDecoration(
      //       color: Colors.green,
      //       borderRadius: BorderRadius.all(Radius.circular(10.0)),
      //     ),
      //     // color: Colors.blueAccent,
      //     child: InkWell(
      //       onTap: () async {
      //         if (cdc.order.value.billItem!.length == 0) {
      //           Get.snackbar("รายการสินค้าไม่ถูกต้อง", "ไม่พบรายการสินค้า",
      //               snackPosition: SnackPosition.BOTTOM);
      //         } else {
      //           cdc.orderSuccess.value = cdc.order.value;
      //           paymentCashDialod(context);
      //         }
      //       },
      //       child: Column(
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         children: <Widget>[
      //           const Icon(
      //             FontAwesomeIcons.moneyBill,
      //             color: Colors.white,
      //           ), // <-- Icon
      //           Text(
      //             "เงินสด",
      //             style: GoogleFonts.maitree(color: Colors.white, fontSize: 30),
      //           ), // <-- Text
      //         ],
      //       ),
      //     ),
      //   ),
      // ),
      SizedBox.fromSize(
        // size: const Size(100, 56),
        child: Container(
          margin: const EdgeInsets.only(right: 5),
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          // color: Colors.blueAccent,
          child: InkWell(
            onTap: () async {
              cdc.orderSuccess.value = cdc.order.value;
              print("sssssssssssssssssssssssssssdsdsdsdd");
              print(cdc.orderSuccess.value.toJson());
              var dd = await paymentCardDialod(context);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  FontAwesomeIcons.moneyBillTransfer,
                  color: Colors.white,
                ), // <-- Icon
                Text(
                  "ชำระเงิน",
                  style: GoogleFonts.maitree(color: Colors.white, fontSize: 30),
                ), // <-- Text
              ],
            ),
          ),
        ),
      ),
      // SizedBox.fromSize(
      //   // size: const Size(80, 56),
      //   child: Container(
      //     decoration: const BoxDecoration(
      //       color: Colors.blueAccent,
      //       borderRadius: BorderRadius.all(Radius.circular(10.0)),
      //     ),
      //     child: InkWell(
      //       onTap: () {
      //         if (cdc.order.value.billItem!.length == 0) {
      //           Get.snackbar("รายการสินค้าไม่ถูกต้อง", "ไม่พบรายการสินค้า",
      //               snackPosition: SnackPosition.BOTTOM);
      //         } else {
      //           cdc.orderSuccess.value = cdc.order.value;
      //           paymentFinanceDialod(context);
      //         }
      //       },
      //       child: Column(
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         children: <Widget>[
      //           const Icon(
      //             FontAwesomeIcons.moneyBillTransfer,
      //             color: Colors.white,
      //           ), // <-- Icon
      //           Text(
      //             "เงินเชื่อ",
      //             style: GoogleFonts.maitree(color: Colors.white, fontSize: 30),
      //           ), // <-- Text
      //         ],
      //       ),
      //     ),
      //   ),
      // ),
    ];
  }

  listProductWidget() {
    int itemShow = 1;
    List<Widget> list = [];
    List<ProductModel> products = posCtrl.products;
    for (var i = 0; i < products.length; i++) {
      print(products[i].sku);
      var priceShoe = "";
      List<Widget> priceAll = [];
      List<Color> cl = [
        Colors.deepOrangeAccent,
        Colors.blueAccent,
        Colors.amber
      ];
      List<Color> ct = [Colors.white, Colors.white, Colors.black];
      if (products[i].sku!.length! > 0) {
        for (var p = 0; p < posCtrl.products[i].sku!.length; p++) {
          Widget ps = Expanded(
            flex: 1,
            child: Container(
              // height: 100,
              padding: EdgeInsets.only(left: 8, right: 8),
              margin: const EdgeInsets.only(right: 1, left: 1, bottom: 0),
              decoration: BoxDecoration(
                color: cl[p],
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
              child: InkWell(
                onTap: () async {
                  ProductModel addProd = ProductModel(
                    productId: posCtrl.products[i].productId,
                    name:
                        "${posCtrl.products[i].name.toString()} (${posCtrl.products[i].sku![p].description.toString()})",
                    qty: posCtrl.products[i].qty,
                    categoryId: posCtrl.products[i].categoryId,
                    price1: posCtrl.products[i].sku![p].price.toString(),
                    image: posCtrl.products[i].image,
                    cutStock: posCtrl.products[i].cutStock,
                    imageUrl: posCtrl.products[i].imageUrl,
                    skuSelect: posCtrl.products[i].sku![p].sku,
                  );
                  cdc.addItem(addProd);
                  fieldTextSearch.clear();
                  posCtrl.fillterProduct("");
                  if (posCtrl.products[i].sku != null) {}
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(products[i].sku![p].description!,
                        style: GoogleFonts.maitree(
                            color: ct[p], fontSize: 14)), // <-- Icon
                    Text(
                      products[i].sku![p].price.toString(),
                      style: GoogleFonts.maitree(color: ct[p], fontSize: 20),
                    ), // <-- Text
                  ],
                ),
              ),
            ),
          );
          priceAll.add(ps);
        }
      } else {
        Widget ps = Obx(() => Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.only(right: 5),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
                child: InkWell(
                  onTap: () async {
                    cdc.addItem(posCtrl.products[i]);
                    fieldTextSearch.clear();
                    posCtrl.fillterProduct("");
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // <-- Icon
                      Text(
                        products[i].price1!,
                        style: GoogleFonts.maitree(
                            color: Colors.white, fontSize: 30),
                      ), // <-- Text
                    ],
                  ),
                ),
              ),
            ));
        priceAll.add(ps);
      }
      itemShow = priceAll.length!;

      Widget listProd = Container(
          margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
          decoration: BoxDecoration(
              border: Border.all(
                  width: 1, color: Colors.grey, style: BorderStyle.solid)),
          alignment: Alignment.center,
          child: GestureDetector(
              onTap: () async {
                // cdc.addItem(posCtrl.products[i]);
                // fieldTextSearch.clear();
                // posCtrl.fillterProduct("");
                // if (posCtrl.products[i].sku != null) {}
              },
              child: Container(
                  height: 200,
                  color: Colors.white,
                  padding: const EdgeInsets.all(3),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Stack(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    width: 150,
                                    height: 60,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              posCtrl.products[i].imageUrl!),
                                          fit: BoxFit.fitWidth,
                                        )),
                                  ),
                                ),
                                Expanded(
                                    flex: 6,
                                    child: Container(
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.only(left: 8),
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              AutoSizeText(
                                                posCtrl.products[i].name!,
                                                style: GoogleFonts.maitree(
                                                    color: Colors.black,
                                                    fontSize: 20),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                              ),
                                            ])))
                              ],
                            ),
                            Positioned(
                              left: 0.0,
                              top: 0.0,
                              child: Container(
                                  width: 60.0,
                                  height: 60.0,
                                  // decoration:  BoxDecoration(color: Colors.white),
                                  child: GestureDetector(
                                    onTap: () {
                                      posCtrl.addFavorite(products[i]);
                                      posCtrl.getProducts();
                                    },
                                    child: Obx(() => Icon(
                                        size: 40,
                                        (posCtrl.products[i].favorite == 1)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.red)),
                                  )),
                            ),
                          ],
                        ),
                        Container(
                            height: 60,
                            alignment: Alignment.center,
                            child: Row(
                              children: priceAll,
                            )
                            // GridView.builder(
                            //     gridDelegate:
                            //         const SliverGridDelegateWithFixedCrossAxisCount(
                            //             crossAxisCount: 3, childAspectRatio: 1.1),
                            //     itemCount: priceAll.length,
                            //     itemBuilder: (BuildContext context, int index) {
                            //       return priceAll[index];
                            //     }),
                            )
                      ]))));

      list.add(listProd);
    }
    productWidget = list;
    // return list;
  }

  findProduct(String barcode) {
    // Get.snackbar("", barcode.toUpperCase(),
    //     snackPosition: SnackPosition.BOTTOM);
    int ind = posCtrl.productsTemp.indexWhere((element) =>
        element.barcode.toString().toUpperCase() == barcode.toUpperCase());
    if (ind > -1) {
      var prd = ProductModel();
      prd = posCtrl.productsTemp[ind];
      return prd;
    } else {
      Get.snackbar("Error", "ไม่พบสินค้า", snackPosition: SnackPosition.BOTTOM);
    }
    var prd = new ProductModel();
    prd.productId = "";
    return prd;
  }

  Widget listCate(context) {
    listCatWidget();
    return Container(
            margin: EdgeInsets.all(10),
            // padding: EdgeInsets.all(30),
            child: ListView(
                // This next line does the trick.
                scrollDirection: Axis.horizontal,
                children: catWidget))
        // shrinkWrap: true,
        ;
    // Row(
    //   children: catWidget,
    // ));
  }

  Widget listProduct(context) {
    listProductWidget();
    print(productWidget.length);
    return MediaQuery.removeViewPadding(
      context: context,
      // removeTop: true,
      child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, childAspectRatio: 1.5
              // childAspectRatio: MediaQuery.of(context).size.width /
              //     (MediaQuery.of(context).size.height / 4)
              ),
          // shrinkWrap: true,
          itemCount: productWidget.length,
          itemBuilder: (BuildContext context, int index) {
            return productWidget[index];
          }),
    );
  }

  List<TextEditingController> _textcontroller = [];
  Widget listItems(context) {
    return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          color: Colors.white,
          alignment: Alignment.topCenter,
          child: Column(children: [
            SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Container(
                    constraints: BoxConstraints(
                      maxWidth: Get.width,
                    ),
                    child: Column(children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          child: Column(children: [
                            Container(
                                padding:
                                    const EdgeInsets.only(top: 20, bottom: 20),
                                decoration: const BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            width: 1,
                                            color: Colors.grey,
                                            style: BorderStyle.solid))),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "ยอดรวม",
                                      style: GoogleFonts.maitree(fontSize: 20),
                                    ),
                                    Text(
                                      cdc.count.toString(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      cdc.order.value.billTotal.toString(),
                                      style: GoogleFonts.maitree(
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                )),
                            const SizedBox(
                              height: 20,
                            ),
                            SizedBox(
                                height: 300,
                                child: ListView.builder(
                                    controller: scrollController,
                                    padding: EdgeInsets.only(
                                      bottom:
                                          MediaQuery.of(context).padding.bottom,
                                    ),
                                    itemCount:
                                        (cdc.order.value.billItem!.length ??
                                                0) +
                                            5,
                                    scrollDirection: Axis.vertical,
                                    itemBuilder: (context, index) {
                                      if (index <
                                          (cdc.order.value.billItem!.length ??
                                              0)) {
                                        _textcontroller.add(
                                            TextEditingController(text: "1"));
                                        _textcontroller[index].text = cdc
                                            .order.value.billItem![index].qty
                                            .toString();
                                        _textcontroller[index].selectAll();
                                      }

                                      return (index <
                                              (cdc.order.value.billItem!
                                                      .length ??
                                                  0))
                                          ? DottedBorder(
                                              dashPattern: [3, 1],
                                              strokeWidth: 1,
                                              color: Colors.grey,
                                              borderPadding:
                                                  const EdgeInsets.all(5),
                                              radius: const Radius.circular(15),
                                              child: Container(
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                          flex: 1,
                                                          child: InkWell(
                                                            splashColor:
                                                                Colors.red,
                                                            onTap: () {
                                                              cdc.removeItem(
                                                                  index);
                                                            },
                                                            child: const Icon(
                                                              FontAwesomeIcons
                                                                  .xmark,
                                                              color: Colors.red,
                                                            ), // <-- Icon
                                                            // <-- Text
                                                          )),
                                                      Expanded(
                                                          flex: 6,
                                                          child: AutoSizeText(
                                                            // ignore: prefer_interpolation_to_compose_strings
                                                            cdc
                                                                    .order
                                                                    .value
                                                                    .billItem![
                                                                        index]
                                                                    .productName
                                                                    .toString() +
                                                                " ",
                                                            style: GoogleFonts
                                                                .maitree(),
                                                            maxLines: 1,
                                                          )),
                                                      Expanded(
                                                          flex: 2,
                                                          // ignore: prefer_interpolation_to_compose_strings
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                  flex: 2,
                                                                  child:
                                                                      TextField(
                                                                    readOnly:
                                                                        true,
                                                                    controller:
                                                                        _textcontroller[
                                                                            index],
                                                                    onTap: () {
                                                                      _textcontroller[
                                                                              index]
                                                                          .selectAll();

                                                                      // .selection = TextSelection.fromPosition(TextPosition(offset:cdc
                                                                      //     .order
                                                                      //     .value
                                                                      //     .billItem![
                                                                      // index]
                                                                      //     .qty.toString().length));
                                                                    }
                                                                    // TextEditingController(text:  cdc
                                                                    //     .order
                                                                    //     .value
                                                                    //     .billItem![
                                                                    // index]
                                                                    //     .qty.toString()).selectAll
                                                                    ,
                                                                    keyboardType:
                                                                        TextInputType
                                                                            .number,
                                                                    inputFormatters: <
                                                                        TextInputFormatter>[
                                                                      FilteringTextInputFormatter
                                                                          .digitsOnly
                                                                    ],
                                                                    onChanged:
                                                                        (value) {
                                                                      cdc
                                                                          .order
                                                                          .value
                                                                          .billItem![
                                                                              index]
                                                                          .qty = int.parse(value);
                                                                      cdc.updateOrder(
                                                                          index);
                                                                    },
                                                                  )),
                                                            ],
                                                          )),
                                                      Expanded(
                                                          flex: 2,
                                                          child: Text(
                                                              cdc
                                                                  .order
                                                                  .value
                                                                  .billItem![
                                                                      index]
                                                                  .price
                                                                  .toString(),
                                                              textAlign:
                                                                  TextAlign.end,
                                                              style: GoogleFonts
                                                                  .maitree(
                                                                      fontSize:
                                                                          18)))
                                                    ],
                                                  )))
                                          : const SizedBox(height: 40);
                                    })),
                          ]))
                    ])))
          ]),
        ));
  }

  Future<List<CustomerModel>> getCustData(filter) async {
    final data = posCtrl.customers.value
        .where((element) => element.customerName!.contains(filter));
    return data.toList();
  }

  paymentCashDialod(contact) {
    double rowHeight = 80;
    double btnWidth = 120;
    double fontSize = 25;
    cdc.isPayProcess.value = false;
    cdc.payCash.value = '0.00';
    cdc.order.value.receiveCash = 0;
    posCtrl.searchCustomer.value = posCtrl.customers
        .firstWhere((element) => element.customerNo == "CM000001");
    Get.defaultDialog(
        title: "ชำระเงินสด" + cdc.order.value.cardNumber!,
        cancel: InkWell(
            splashColor: Colors.red,
            onTap: () {
              Get.back();
            },
            child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.all(1),
                padding: const EdgeInsets.all(5),
                color: Colors.red,
                child: Text(
                  "ปิด",
                  style: GoogleFonts.maitree(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                )) // <-- Icon
            // <-- Text
            ),
        onCancel: () {
          print("Close");
          Get.back();
        },
        barrierDismissible: !cdc.isPaySuccess.value,
        backgroundColor: Colors.white,
        titleStyle: const TextStyle(color: Colors.black),
        middleTextStyle: const TextStyle(color: Colors.black),
        radius: 10,
        content: Obx(() => SingleChildScrollView(
            reverse: true,
            scrollDirection: Axis.vertical,
            child: Container(
                padding: const EdgeInsets.all(15),
                // height: 500,
                child: Column(
                  children: [
                    Container(
                      // height: rowHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              "ลูกค้า",
                              style: GoogleFonts.maitree(fontSize: fontSize),
                            ),
                          ),
                          Expanded(
                              flex: 7,
                              child: SizedBox(
                                  width: 200,
                                  child: FindDropdown<CustomerModel>(
                                    // items: posCtrl.customers,
                                    labelVisible: false,
                                    searchHint: "ค้นหาลูกค้า",
                                    dropdownItemBuilder:
                                        (context, item, isSelected) =>
                                            Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        item.customerName!,
                                        style: GoogleFonts.maitree(),
                                      ),
                                    ),
                                    dropdownBuilder:
                                        (context, CustomerModel? selectedItem) {
                                      return Container(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          (selectedItem != null)
                                              ? selectedItem!.customerName!
                                              : "",
                                          style: GoogleFonts.maitree(
                                              fontSize: fontSize),
                                        ),
                                      );
                                    },

                                    onFind: (text) {
                                      return getCustData(text);
                                    },
                                    onChanged: (CustomerModel? item) async {
                                      posCtrl.searchCustomer.value = item!;
                                      cdc.order.value.customer!.customerNo =
                                          item!.customerNo;
                                      cdc.order.value.customer!.fName =
                                          item!.customerName;
                                      await displayManager
                                          .transferDataToPresentation(
                                              cdc.order.toJson());
                                    },
                                    selectedItem: () {
                                      if (posCtrl.searchCustomer.value
                                              .customerName ==
                                          null) {
                                        return null;
                                      } else {
                                        var cust =
                                            posCtrl?.searchCustomer?.value;
                                        if (cust != null) {
                                          cdc.order.value.customer!.customerNo =
                                              posCtrl.searchCustomer.value!
                                                  .customerNo;
                                          cdc.order.value.customer!.fName =
                                              posCtrl.searchCustomer.value!
                                                  .customerName;
                                        }
                                        return posCtrl.searchCustomer.value;
                                      }
                                    }(),
                                    showSearchBox: true,
                                  )))
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "ยอดรวม",
                          style: GoogleFonts.maitree(fontSize: fontSize),
                        ),
                        Text(
                          (cdc.orderSuccess.value.billTotal ??
                                  cdc.order.value.billTotal)
                              .toString(),
                          style: GoogleFonts.maitree(fontSize: 25),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: (cdc.isPayProcess.value)
                                    ? Colors.green
                                    : Colors.black12,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: (cdc.isPayProcess.value)
                                  ? Text(
                                      "รับเงิน",
                                      style: GoogleFonts.maitree(
                                          fontSize: fontSize),
                                    )
                                  : InkWell(
                                      splashColor: Colors.red,
                                      onTap: () {
                                        cdc.keyReceiveCash('C');
                                      },
                                      child: Container(
                                          margin: const EdgeInsets.all(1),
                                          padding: const EdgeInsets.all(5),
                                          child: const Icon(
                                              FontAwesomeIcons.xmark,
                                              color: Colors.red)) // <-- Icon
                                      // <-- Text
                                      )),
                          Text(cdc.payCash.value,
                              style: GoogleFonts.maitree(fontSize: fontSize),
                              textAlign: TextAlign.end),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    (cdc.isPayProcess.value)
                        ? Container(
                            child: (cdc.isPaySuccess.value)
                                ? Container(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text("เงินทอน"),
                                            Text(
                                                (cdc.orderSuccess.value
                                                            .receiveCash! -
                                                        cdc.orderSuccess.value!
                                                            .billTotal!)
                                                    .toString(),
                                                style: GoogleFonts.maitree(
                                                    fontSize: 35),
                                                textAlign: TextAlign.end)
                                          ],
                                        ),
                                        Text(
                                          "ทำรายการสำเร็จ",
                                          style: GoogleFonts.maitree(
                                              color: Colors.green,
                                              fontSize: 25),
                                          textAlign: TextAlign.center,
                                        ),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: InkWell(
                                                    splashColor: Colors.red,
                                                    onTap: () async {
                                                      await printSlip();
                                                      // await onPrintTest();
                                                      await cdc.clear();
                                                      Get.back();
                                                      // cdc.keyReceiveCash('2');
                                                    },
                                                    child: Container(
                                                        height: 100,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration: BoxDecoration(
                                                            color: Colors.blue,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        30)),
                                                        margin: const EdgeInsets
                                                            .all(1),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5),
                                                        // color: Colors.blue,
                                                        child: Text(
                                                          "พิมพ์สลิป",
                                                          style: GoogleFonts
                                                              .maitree(
                                                                  fontSize: 28,
                                                                  color: Colors
                                                                      .white),
                                                          textAlign:
                                                              TextAlign.center,
                                                        )) // <-- Icon
                                                    // <-- Text
                                                    ),
                                              ),
                                              Expanded(
                                                child: InkWell(
                                                    splashColor: Colors.red,
                                                    onTap: () async {
                                                      await printSlip();
                                                      cashDraw();
                                                      cdc.clear();
                                                      Get.back();
                                                      // cdc.keyReceiveCash('2');
                                                    },
                                                    child: Container(
                                                        height: 100,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration: BoxDecoration(
                                                            color: Colors.blue,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        30)),
                                                        margin: const EdgeInsets
                                                            .all(1),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5),
                                                        // color: Colors.blue,
                                                        child: Text(
                                                          "พิมพ์สลิป/เปิดลิ้นชัก",
                                                          style: GoogleFonts
                                                              .maitree(
                                                                  fontSize: 25,
                                                                  color: Colors
                                                                      .white),
                                                          textAlign:
                                                              TextAlign.center,
                                                        )) // <-- Icon
                                                    // <-- Text
                                                    ),
                                              ),
                                              Expanded(
                                                child: InkWell(
                                                    splashColor: Colors.red,
                                                    onTap: () {
                                                      // cdc.keyReceiveCash('2');
                                                      cashDraw();
                                                      cdc.clear();
                                                      Get.back();
                                                    },
                                                    child: Container(
                                                        height: 100,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration: BoxDecoration(
                                                            color: Colors.blue,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        30)),
                                                        margin: const EdgeInsets
                                                            .all(1),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5),
                                                        // color: Colors.blue,
                                                        child: Text(
                                                          "เปิดลิ้นชัก",
                                                          style: GoogleFonts
                                                              .maitree(
                                                                  fontSize: 32,
                                                                  color: Colors
                                                                      .white),
                                                          textAlign:
                                                              TextAlign.center,
                                                        )) // <-- Icon
                                                    // <-- Text
                                                    ),
                                              ),
                                              Expanded(
                                                child: InkWell(
                                                    splashColor: Colors.red,
                                                    onTap: () {
                                                      cdc.clear();
                                                      Get.back();
                                                      // cdc.keyReceiveCash('2');
                                                    },
                                                    child: Container(
                                                        alignment:
                                                            Alignment.center,
                                                        height: 100,
                                                        decoration: BoxDecoration(
                                                            color: Colors.red,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        30)),
                                                        margin: const EdgeInsets
                                                            .all(1),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5),
                                                        // color: Colors.red,
                                                        child: Text(
                                                          "ปิด",
                                                          style: GoogleFonts
                                                              .maitree(
                                                                  fontSize: 32,
                                                                  color: Colors
                                                                      .white),
                                                          textAlign:
                                                              TextAlign.center,
                                                        )) // <-- Icon
                                                    // <-- Text
                                                    ),
                                              )
                                            ])
                                      ],
                                    ),
                                  )
                                : const CircularProgressIndicator(),
                          )
                        : Container(
                            width: 800,
                            child: Column(
                              children: [
                                SizedBox(
                                    height: rowHeight,
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              width: btnWidth,
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('1');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.blue,
                                                      child: Text(
                                                        "1",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              width: btnWidth,
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('2');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.blue,
                                                      child: Text(
                                                        "2",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('3');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.blue,
                                                      child: Text(
                                                        "3",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    // cdc.keyReceiveCash('PR');
                                                    cdc.keyReceiveCash('1000');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.black87,
                                                      child: Text(
                                                        "1,000",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('500');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.black87,
                                                      child: Text(
                                                        "500",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                      ],
                                    )),
                                SizedBox(
                                    height: rowHeight,
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('4');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.blue,
                                                      child: Text(
                                                        "4",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('5');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.blue,
                                                      child: Text(
                                                        "5",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('6');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.blue,
                                                      child: Text(
                                                        "6",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('100');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.black87,
                                                      child: Text(
                                                        "100",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('50');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.black87,
                                                      child: Text(
                                                        "50",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                      ],
                                    )),
                                SizedBox(
                                    height: rowHeight,
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('7');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.blue,
                                                      child: Text(
                                                        "7",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('8');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.blue,
                                                      child: Text(
                                                        "8",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('9');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.blue,
                                                      child: Text(
                                                        "9",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('20');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.black87,
                                                      child: Text(
                                                        "20",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('PR');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.deepOrange,
                                                      child: Text(
                                                        "จ่ายพอดี",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize: 32,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                      ],
                                    )),
                                SizedBox(
                                    height: rowHeight,
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('D');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.red,
                                                      child: Text(
                                                        "ลบ",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    cdc.keyReceiveCash('0');
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.blue,
                                                      child: Text(
                                                        "0",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () {
                                                    // cdc.keyReceiveCash('500');
                                                  },
                                                  child: Container(
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.grey,
                                                      child: Text(
                                                        "",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                        Expanded(
                                            flex: 2,
                                            child: Container(
                                              height: rowHeight,
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () async {
                                                    if (cdc.order.value
                                                            .receiveCash! >=
                                                        cdc.order.value
                                                            .billTotal!) {
                                                      cdc.isPayProcess.value =
                                                          true;
                                                      cdc.payCashToBill();
                                                    }
                                                    // _customEscPos();
                                                    // final List<int> _escPos = await _customEscPos();
                                                    // await SunmiPrinter.initPrinter();
                                                    // await SunmiPrinter.startTransactionPrint(true);
                                                    // await SunmiPrinter.printRawData(
                                                    //     Uint8List.fromList(_escPos));
                                                    // await SunmiPrinter.exitTransactionPrint(true);

                                                    // var _duration =
                                                    //     new Duration(
                                                    //         seconds: 3);
                                                    // new Timer(_duration, () {
                                                    //   cdc.isPaySuccess.value =
                                                    //       true;
                                                    // });
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              15),
                                                      color: (cdc.order.value
                                                                  .receiveCash! <
                                                              cdc.order.value
                                                                  .billTotal!)
                                                          ? Colors.grey
                                                          : Colors.green,
                                                      child: Text(
                                                        "ชำระ",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                      ],
                                    ))
                              ],
                            ))

                    // Container(
                    //   child: Row(
                    //     children: [
                    //       Text("ยอดรวม"),
                    //       Text(cdc.order.value.total.toString()),
                    //     ],
                    //   ),
                    // ),
                  ],
                )))));
  }

  paymentCardDialod(contact) {
    isScanCard = true;
    _resetCardScan(); // รีเซ็ตสถานะ card scan ก่อนเริ่มใหม่
    fieldTextSearch2.text = "";
    cdc.orderSuccess.value = BillModel();
    double rowHeight = 80;
    double btnWidth = 120;
    double fontSize = 25;
    cdc.isPayProcess.value = false;
    cdc.payCash.value = '0.00';
    cdc.order.value.receiveCash = 0;
    hidKeyboard();
    _scanCardNFC();
    Get.defaultDialog(
      title: "สแกนบัตร เพื่อชำระ",
      backgroundColor: Colors.white,
      titleStyle: GoogleFonts.maitree(color: Colors.black, fontSize: 30),
      middleTextStyle: const TextStyle(color: Colors.black),
      radius: 10,
      content: Obx(() => SingleChildScrollView(
          reverse: true,
          scrollDirection: Axis.vertical,
          child: Container(
              width: 500,
              padding: const EdgeInsets.all(15),
              // height: 500,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "ผู้ถือบัตร",
                        style: GoogleFonts.maitree(fontSize: fontSize),
                      ),
                      Text(
                        (cdc.orderSuccess.value.customerName ?? "").toString(),
                        style: GoogleFonts.maitree(fontSize: 25),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "ยอดชำระ",
                        style: GoogleFonts.maitree(fontSize: fontSize),
                      ),
                      Text(
                        (cdc.orderSuccess.value.billTotal ??
                                cdc.order.value.billTotal)
                            .toString(),
                        style: GoogleFonts.maitree(fontSize: 25),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "คงเหลือใช้ได้",
                        style: GoogleFonts.maitree(fontSize: fontSize),
                      ),
                      Text(
                        (cdc.orderSuccess.value.card != null
                                ? cdc.orderSuccess.value.card!.amount
                                : "0.00")
                            .toString(),
                        style: GoogleFonts.maitree(fontSize: 28),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),
                  Obx(() {
                    if (!cdc.isPayProcess.value) {
                      print("ssssssssssssssfffffffff");
                      print(cdc.isPayProcess.value);
                      return const SizedBox.shrink();
                    }

                    if (!cdc.isPaySuccess.value) {
                      print("sdddddddddddddddddd");
                      print(cdc.isPaySuccess.value);
                      return const Center(child: CircularProgressIndicator());
                    }

                    if ((cdc.errorCard ?? '').toString().isNotEmpty) {
                      return Text(
                        cdc.errorCard.toString(),
                        style: GoogleFonts.maitree(
                          color: Colors.red,
                          fontSize: 30,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }

                    // กรณีทำรายการสำเร็จ + ไม่มี error
                    return _buildSuccessContent();
                  })
                  // Container(
                  //   child: Row(
                  //     children: [
                  //       Text("ยอดรวม"),
                  //       Text(cdc.order.value.total.toString()),
                  //     ],
                  //   ),
                  // ),
                ],
              )))),
    ).then((value) {
      isScanCard = false;
      // Get.back();
    });
  }

  Widget _buildSuccessContent() {
    return Container(
      child: Column(
        children: [
          Text(
            cdc.isDuplicateScan.value ? "ทำรายการไปแล้ว" : "ทำรายการสำเร็จ",
            style: GoogleFonts.maitree(
              color: cdc.isDuplicateScan.value ? Colors.orange : Colors.green,
              fontSize: 25,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                label: "พิมพ์สลิป",
                onTap: () async {
                  await printSlip();
                  await cdc.clear();
                  Get.back();
                },
              ),
              _buildActionButton(
                label: "พิมพ์สลิป/เปิดลิ้นชัก",
                fontSize: 20,
                onTap: () async {
                  await printSlip();
                  cashDraw();
                  await cdc.clear();
                  Get.back();
                },
              ),
              _buildActionButton(
                label: "เปิดลิ้นชัก",
                onTap: () {
                  cashDraw();
                  cdc.clear();
                  Get.back();
                },
              ),
              _buildActionButton(
                label: "ปิด",
                background: Colors.red,
                onTap: () {
                  cdc.clear();
                  Get.back();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    Color background = Colors.blue,
    double fontSize = 22,
  }) {
    return Expanded(
      child: InkWell(
        splashColor: Colors.red,
        onTap: onTap,
        child: Container(
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(30),
          ),
          margin: const EdgeInsets.all(1),
          padding: const EdgeInsets.all(5),
          child: Text(
            label,
            style: GoogleFonts.maitree(
              fontSize: fontSize,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  hidKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  paymentFinanceDialod(contact) {
    double rowHeight = 60;
    double fontSize = 35;
    cdc.isPayProcess.value = false;
    cdc.payCash.value = '0.00';
    cdc.order.value.receiveCash = 0;
    posCtrl.searchCustomer.value = posCtrl.customers
        .firstWhere((element) => element.customerNo == "CM000001");
    Get.defaultDialog(
        title: "เงินเชื่อ",
        backgroundColor: Colors.white,
        titleStyle: const TextStyle(color: Colors.black),
        middleTextStyle: const TextStyle(color: Colors.black),
        radius: 10,
        content: Obx(() => SingleChildScrollView(
            reverse: true,
            scrollDirection: Axis.vertical,
            child: Container(
                padding: const EdgeInsets.all(15),
                // height: 500,
                child: Column(
                  children: [
                    Container(
                      // height: rowHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              "ลูกค้า",
                              style: GoogleFonts.maitree(),
                            ),
                          ),
                          Expanded(
                              flex: 7,
                              child: SizedBox(
                                  width: 200,
                                  child: FindDropdown<CustomerModel>(
                                    // items: posCtrl.customers,
                                    labelVisible: false,
                                    searchHint: "ค้นหาลูกค้า",
                                    dropdownItemBuilder:
                                        (context, item, isSelected) =>
                                            Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        item.customerName!,
                                        style: GoogleFonts.maitree(),
                                      ),
                                    ),
                                    dropdownBuilder:
                                        (context, CustomerModel? selectedItem) {
                                      return Container(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          (selectedItem != null)
                                              ? selectedItem!.customerName!
                                              : "",
                                          style: GoogleFonts.maitree(),
                                        ),
                                      );
                                    },

                                    onFind: (text) {
                                      return getCustData(text);
                                    },
                                    onChanged: (CustomerModel? item) async {
                                      posCtrl.searchCustomer.value = item!;
                                      cdc.order.value.customer!.customerNo =
                                          item!.customerNo;
                                      cdc.order.value.customer!.fName =
                                          item!.customerName;
                                      await displayManager
                                          .transferDataToPresentation(
                                              cdc.order.toJson());
                                    },
                                    selectedItem: () {
                                      if (posCtrl.searchCustomer.value
                                              .customerName ==
                                          null) {
                                        return null;
                                      } else {
                                        var cust =
                                            posCtrl?.searchCustomer?.value;
                                        if (cust != null) {
                                          cdc.order.value.customer!.customerNo =
                                              posCtrl.searchCustomer.value!
                                                  .customerNo;
                                          cdc.order.value.customer!.fName =
                                              posCtrl.searchCustomer.value!
                                                  .customerName;
                                        }
                                        return posCtrl.searchCustomer.value;
                                      }
                                    }(),
                                    showSearchBox: true,
                                  )))
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "ยอดรวม",
                          style: GoogleFonts.maitree(),
                        ),
                        Text(
                          cdc.order.value.billTotal.toString(),
                          style: GoogleFonts.maitree(fontSize: 35),
                        ),
                      ],
                    ),
                    (cdc.isPayProcess.value)
                        ? Container(
                            child: (cdc.isPaySuccess.value)
                                ? Container(
                                    child: Column(
                                      children: [
                                        Text(
                                          "ทำรายการสำเร็จ",
                                          style: GoogleFonts.maitree(
                                              color: Colors.green,
                                              fontSize: 25),
                                          textAlign: TextAlign.center,
                                        ),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: InkWell(
                                                    splashColor: Colors.red,
                                                    onTap: () async {
                                                      await printSlip();

                                                      await cdc.clear();
                                                      Get.back();
                                                      // cdc.keyReceiveCash('2');
                                                    },
                                                    child: Container(
                                                        margin: const EdgeInsets
                                                            .all(1),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5),
                                                        color: Colors.blue,
                                                        child: Text(
                                                          "พิมพ์สลิป",
                                                          style: GoogleFonts
                                                              .maitree(
                                                                  fontSize: 18,
                                                                  color: Colors
                                                                      .white),
                                                          textAlign:
                                                              TextAlign.center,
                                                        )) // <-- Icon
                                                    // <-- Text
                                                    ),
                                              ),
                                              Expanded(
                                                child: InkWell(
                                                    splashColor: Colors.red,
                                                    onTap: () async {
                                                      await printSlip();
                                                      cashDraw();
                                                      cdc.clear();
                                                      Get.back();
                                                      // cdc.keyReceiveCash('2');
                                                    },
                                                    child: Container(
                                                        margin: const EdgeInsets
                                                            .all(1),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5),
                                                        color: Colors.blue,
                                                        child: Text(
                                                          "พิมพ์สลิป/เปิดลิ้นชัก",
                                                          style: GoogleFonts
                                                              .maitree(
                                                                  fontSize: 18,
                                                                  color: Colors
                                                                      .white),
                                                          textAlign:
                                                              TextAlign.center,
                                                        )) // <-- Icon
                                                    // <-- Text
                                                    ),
                                              ),
                                              Expanded(
                                                child: InkWell(
                                                    splashColor: Colors.red,
                                                    onTap: () {
                                                      // cdc.keyReceiveCash('2');
                                                      cashDraw();
                                                      cdc.clear();
                                                      Get.back();
                                                    },
                                                    child: Container(
                                                        margin: const EdgeInsets
                                                            .all(1),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5),
                                                        color: Colors.blue,
                                                        child: Text(
                                                          "เปิดลิ้นชัก",
                                                          style: GoogleFonts
                                                              .maitree(
                                                                  fontSize: 18,
                                                                  color: Colors
                                                                      .white),
                                                          textAlign:
                                                              TextAlign.center,
                                                        )) // <-- Icon
                                                    // <-- Text
                                                    ),
                                              ),
                                              Expanded(
                                                child: InkWell(
                                                    splashColor: Colors.red,
                                                    onTap: () {
                                                      cdc.clear();
                                                      Get.back();
                                                      // cdc.keyReceiveCash('2');
                                                    },
                                                    child: Container(
                                                        margin: const EdgeInsets
                                                            .all(1),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(15),
                                                        color: Colors.red,
                                                        child: Text(
                                                          "ปิด",
                                                          style: GoogleFonts
                                                              .maitree(
                                                                  fontSize: 25,
                                                                  color: Colors
                                                                      .white),
                                                          textAlign:
                                                              TextAlign.center,
                                                        )) // <-- Icon
                                                    // <-- Text
                                                    ),
                                              )
                                            ])
                                      ],
                                    ),
                                  )
                                : const CircularProgressIndicator(),
                          )
                        : Container(
                            width: 500,
                            child: Column(
                              children: [
                                SizedBox(
                                    height: rowHeight,
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 3,
                                            child: Container(
                                              child: InkWell(
                                                  splashColor: Colors.red,
                                                  onTap: () async {
                                                    cdc.payFinanceToBill();

                                                    // _customEscPos();
                                                    // final List<int> _escPos = await _customEscPos();
                                                    // await SunmiPrinter.initPrinter();
                                                    // await SunmiPrinter.startTransactionPrint(true);
                                                    // await SunmiPrinter.printRawData(
                                                    //     Uint8List.fromList(_escPos));
                                                    // await SunmiPrinter.exitTransactionPrint(true);

                                                    // var _duration =
                                                    //     new Duration(
                                                    //         seconds: 3);
                                                    // new Timer(_duration, () {
                                                    //   cdc.isPaySuccess.value =
                                                    //       true;
                                                    // });
                                                  },
                                                  child: Container(
                                                      margin:
                                                          const EdgeInsets.all(
                                                              1),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      color: Colors.green,
                                                      child: Text(
                                                        "ชำระ",
                                                        style:
                                                            GoogleFonts.maitree(
                                                                fontSize:
                                                                    fontSize,
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )) // <-- Icon
                                                  // <-- Text
                                                  ),
                                            )),
                                      ],
                                    ))
                              ],
                            ))
                  ],
                )))));
  }

  cashDraw() async {
    await SunmiPrinter
        .drawerStatus(); //check if the cash drawer is connect or disconnect

    await SunmiPrinter.openDrawer(); //open de cash drawer

    await SunmiPrinter.drawerTimesOpen();
  }

  printSlip1() async {
    final List<int> _escPos = await _customEscPos();
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);
    await SunmiPrinter.printRawData(Uint8List.fromList(_escPos));
    await SunmiPrinter.exitTransactionPrint(true);
  }

  final mc = GetStorage();
  printSlip() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mc.read(Constant.POS_CODE) == null) {
      mc.write(Constant.POS_CODE, "00${mc.read(Constant.posNo)}");
    }

    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.setFontSize(SunmiFontSize.MD);
    await SunmiPrinter.printText("${prefs.getString(Constant.ShopName)!}");
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.printText('ใบเสร็จรับเงินอย่างย่อ');
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.line();
    await SunmiPrinter.printText(
        'Trn#' + cdc.orderSuccess.value!.billNo.toString());
    await SunmiPrinter.printText('pos#' + mc.read(Constant.POS_CODE));
    await SunmiPrinter.printText(
        'วันที่ ' + cdc.orderSuccess.value.billDate.toString());
    await SunmiPrinter.printText('ลูกค้า ' +
        cdc.orderSuccess.value.customer!.customerNo.toString() +
        cdc.orderSuccess.value.customer!.fName.toString());
    await SunmiPrinter.line();
    print(cdc.orderSuccess.value.billItem!.length);
    for (var element in cdc.orderSuccess.value.billItem!) {
      print(element.productName.toString());
      var prdName = "";
      int max = (element.productName.toString().length > 50)
          ? 50
          : element.productName.toString().length;
      for (int i = 0; i < max; i++) {
        if (element.productName.toString()[i] != " ") {
          print(element.productName.toString()[i]);
          prdName = prdName + element.productName.toString()[i];
        }
      }
      print(prdName + "::" + element.productName.toString().length.toString());
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
    }

    await SunmiPrinter.printRow(cols: [
      ColumnMaker(text: 'รวม', width: 25, align: SunmiPrintAlign.LEFT),
      ColumnMaker(
          text: cdc.orderSuccess.value.billTotal.toString(),
          width: 5,
          align: SunmiPrintAlign.RIGHT),
    ]);
    await SunmiPrinter.bold();

    // if (cdc.orderSuccess.value.cardNumber.toString() != "") {
    //   await SunmiPrinter.printText('ยอดคงเหลือใช้ได้  #  ' +
    //       cdc.orderSuccess.value.card!.amount.toString());
    // } else {
    //   bool  pp =cdc.orderSuccess.value.receiveCash!>0.0;
    //   await SunmiPrinter.printText('รับเงิน/ทอน  #  ' +
    //       cdc.orderSuccess.value.receiveCash.toString() +
    //       " / " +
    //       (pp?(cdc.orderSuccess.value.receiveCash! -
    //               cdc.orderSuccess.value.billTotal!)
    //           .toString():"0"));
    // }
    await SunmiPrinter.printText('ยอดคงเหลือใช้ได้  #  ' +
        cdc.orderSuccess.value.cardBalance.toString());
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
    await SunmiPrinter.printText(
        'รายได้จะนำกลับไปพัฒนาความเป็นอยู่ลูกหลานของท่าน');
    await SunmiPrinter.lineWrap(2);

    await SunmiPrinter.printText('------------------------------');
    await SunmiPrinter.lineWrap(2);
    await SunmiPrinter.cut();
    await SunmiPrinter.exitTransactionPrint(true);
  }

  Future<List<int>> _customEscPos() async {
    final profile = await CapabilityProfile.load();

    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // bytes += generator.text(
    //     'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ ก ข ค');
    bytes += generator.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
        styles: const PosStyles(codeTable: 'CP1252'));
    bytes += generator.text('Special 2: blåbærgrød',
        styles: const PosStyles(codeTable: 'CP1252'));

    bytes += generator.text('Bold text', styles: const PosStyles(bold: true));
    bytes +=
        generator.text('Reverse text', styles: const PosStyles(reverse: true));
    bytes += generator.text('Underlined text',
        styles: const PosStyles(underline: true), linesAfter: 1);

    bytes += generator.text('ทดสอบภาษาไทย',
        styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Align center',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Align right',
        styles: const PosStyles(align: PosAlign.right), linesAfter: 1);
    bytes += generator.qrcode('Barcode by escpos',
        size: QRSize.Size4, cor: QRCorrection.H);
    bytes += generator.feed(2);

    bytes += generator.row([
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col6',
        width: 6,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
    ]);

    bytes += generator.text('Text size 200%',
        styles: const PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));

    bytes += generator.reset();
    bytes += generator.cut();

    return bytes;
  }

  //  onPrintTest() async {
  //   EpsonPrinterModel printer = printers[0];
  //   print(printer);
  //   // await EpsonEPOS.setPrinterSetting(printer, paperWidth: 80);
  //   EpsonEPOSCommand command = EpsonEPOSCommand();
  //   List<Map<String, dynamic>> commands = [];
  //
  //   commands.add(command.addTextAlign(EpsonEPOSTextAlign.LEFT));
  //   commands.add(command.addFeedLine(4));
  //   commands.add(command.append('PRINT TESTE OK!\n'));
  //   // Uint8List encoded = await CharsetConverter.encode("windows1250", "ทดสอบ");
  //   // commands.add(command.rawData(Uint8List.fromList(await _customEscPos())));
  //   // commands.add(command.rawData(encoded));
  //   commands.add(command.addFeedLine(4));
  //   commands.add(command.addCut(EpsonEPOSCut.CUT_FEED));
  //   await EpsonEPOS.onPrint(printer, commands);
  // }

  /// จัดการเลขบัตรที่ scan เข้ามา (ทั้ง keyboard-wedge และ NFC)
  /// เก็บไว้ใน buffer → รอ 500ms → เลือกตัวที่ยาวที่สุด (ครบที่สุด)
  void _handleCardScan(String cardNo) {
    if (_isCardProcessing) {
      print("_handleCardScan: skipped (already processing)");
      return;
    }

    final trimmed = cardNo.trim();
    if (trimmed.isEmpty) return;

    // เก็บเข้า buffer
    _cardScanBuffer.add(trimmed);
    print("Card buffer: $_cardScanBuffer");

    // รีเซ็ต timer ทุกครั้ง → รอจนไม่มีค่าใหม่เข้ามาอีก 500ms
    _cardDebounceTimer?.cancel();
    _cardDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_cardScanBuffer.isEmpty || _isCardProcessing) return;

      // เลือกเลขบัตรที่ยาวที่สุด (ครบที่สุด)
      _cardScanBuffer.sort((a, b) => b.length.compareTo(a.length));
      final bestCard = _cardScanBuffer.first;
      print("Card selected (longest): $bestCard from ${_cardScanBuffer.length} scans");
      _cardScanBuffer.clear();

      // เช็คความยาวขั้นต่ำ (เลขบัตรจริงต้อง >= 8 หลัก)
      if (bestCard.length < 8) {
        print("Card number too short ($bestCard), ignoring");
        return;
      }

      _isCardProcessing = true;
      cdc.order.value.cardNumber = bestCard;
      cdc.payCardToBill().then((_) {
        _isCardProcessing = false;
      }).catchError((e) {
        print("payCardToBill error: $e");
        _isCardProcessing = false;
      });
    });
  }

  /// รีเซ็ตสถานะ card scan เมื่อเปิด dialog ชำระใหม่
  void _resetCardScan() {
    _cardDebounceTimer?.cancel();
    _cardScanBuffer.clear();
    _isCardProcessing = false;
    cdc.isPayProcess.value = false;
    cdc.isPaySuccess.value = false;
    cdc.errorCard.value = "";
    cdc.isDuplicateScan.value = false;
  }

  void _scanCardNFC() async {
    print("start NFC");
    bool isAvailable = await NfcManager.instance.isAvailable();
    print("NFC available: $isAvailable");

    if (isAvailable) {
      try {
        await displayManager.transferDataToPresentation("123");
        await NfcManager.instance.reactive();
        await NfcManager.instance.startSession(
            onDiscovered: (NfcTag tag) async {
          var nfca = tag.data["nfca"];
          if (nfca != null) {
            var identifier = nfca["identifier"];
            if (identifier != null) {
              int decimalValue = (identifier[3] << 24) |
                  (identifier[2] << 16) |
                  (identifier[1] << 8) |
                  identifier[0];

              // ใช้ debounce เหมือนกับ keyboard-wedge
              _handleCardScan(decimalValue.toString());
            }
          }
          print(nfca);
        }).catchError((onError) => {print(onError.toString())});
      } catch (e) {
        print(e.toString());
      }
    } else {
      print("NFC not available");
    }
  }
}

extension TextEditingControllerExt on TextEditingController {
  void selectAll() {
    if (text.isEmpty) return;
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }
}
