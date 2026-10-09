import 'dart:async';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:mispos/check_update.dart';
import 'package:mispos/controllers/billoffline_controller.dart';
import 'package:mispos/pages/billoffline_page/billoffline_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/home_controller.dart';
import '../pos_sale/pos_sale_page.dart';
import '../transaction_page/transaction_page.dart';

class HomePage extends StatelessWidget {
  final AnimationController? animationController;
  final Uri? uri;

  HomePage({Key? key, this.animationController, this.uri}) : super(key: key);

  HomeController hmctrl = Get.put(HomeController());
  BillOfflineController bof = Get.put(BillOfflineController());
  Animation<double>? topBarAnimation;
  String schoolName = '';
  String schoolLogo = '';
  List<Widget> listViews = <Widget>[];
  var scrollController = ScrollController();
  double topBarOpacity = 1.0;
  String device = "";
  String _userName = '';
  List<Color> get availableColors => const <Color>[
        Colors.purpleAccent,
        Colors.yellow,
        Colors.lightBlue,
        Colors.orange,
        Colors.pink,
        Colors.redAccent,
      ];
  final Color barBackgroundColor = const Color(0xff72d8bf);
  final Duration animDuration = const Duration(milliseconds: 250);

  int touchedIndex = -1;

  bool isPlaying = false;
  var f = NumberFormat("###.0#", "en_US");

  Future<List<Widget>> addAllListData() async {
    // await _fetchData();
    listViews.clear();

    return listViews;
  }

  @override
  Widget build(BuildContext context) {
    // bof.printLog();
    Future.delayed(Duration.zero, () {
      CheckUpdate.check();
    });
    hmctrl.getReport();

    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Obx(
                  () => Text("MIS POS v." + hmctrl.packageInfo.value.version)),
              backgroundColor: Colors.redAccent,
            ),
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.white,
            body: Container(
              margin: EdgeInsets.all(15),
              child: Row(children: [
                Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        SizedBox(
                          width: Get.width,
                          height: 120,
                          child: InkWell(
                              splashColor: Colors.red,
                              onTap: () async {
                                await Get.to(PosSalePage());
                                hmctrl.getReport();
                              },
                              child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 1, color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.blueGrey),
                                  margin: EdgeInsets.all(1),
                                  padding: EdgeInsets.all(5),
                                  // color: Colors.blue,
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(
                                          FontAwesomeIcons.moneyBill,
                                          color: Colors.white,
                                          size: 50,
                                        ), // <-- Icon
                                        Text(
                                          "งานขาย",
                                          style: GoogleFonts.maitree(
                                            color: Colors.white,
                                            fontSize: 32,
                                          ),
                                        )
                                      ])) // <-- Icon
                              // <-- Text
                              ),
                        ),
                        // SizedBox(
                        //   width: Get.width,
                        //   height: 200,
                        //   child: InkWell(
                        //       splashColor: Colors.red,
                        //       onTap: ()async {
                        //         await Get.to(ChangeMoneyPage());
                        //         hmctrl.getReport();
                        //       },
                        //       child: Container(
                        //           decoration: BoxDecoration(
                        //               border: Border.all(
                        //                   width: 1, color: Colors.grey),
                        //               borderRadius: BorderRadius.circular(10),
                        //               color: Colors.blueGrey),
                        //           margin: EdgeInsets.all(1),
                        //           padding: EdgeInsets.all(5),
                        //           // color: Colors.blue,
                        //           child: Column(
                        //               mainAxisAlignment:
                        //               MainAxisAlignment.center,
                        //               children: <Widget>[
                        //                 Icon(
                        //                   FontAwesomeIcons.moneyBill,
                        //                   color: Colors.white,
                        //                   size: 50,
                        //                 ), // <-- Icon
                        //                 Text(
                        //                   "บันทึกเงินทอน",
                        //                   style: GoogleFonts.maitree(
                        //                     color: Colors.white,
                        //                     fontSize: 32,
                        //                   ),
                        //                 )
                        //               ])) // <-- Icon
                        //     // <-- Text
                        //   ),
                        // ),
                        SizedBox(
                          width: Get.width,
                          height: 120,
                          child: InkWell(
                              splashColor: Colors.red,
                              onTap: () {
                                Get.to(TransactionPage());
                              },
                              child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 1, color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.orange),
                                  margin: EdgeInsets.all(1),
                                  padding: EdgeInsets.all(5),
                                  // color: Colors.blue,
                                  child: Text(
                                    "รายการขาย",
                                    style: GoogleFonts.maitree(
                                        fontSize: 32, color: Colors.white),
                                    textAlign: TextAlign.center,
                                  )) // <-- Icon
                              // <-- Text
                              ),
                        ),
                        SizedBox(
                          width: Get.width,
                          height: 120,
                          child: InkWell(
                              splashColor: Colors.red,
                              onTap: () {
                                closeSale();
                              },
                              child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 1, color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.red),
                                  margin: EdgeInsets.all(1),
                                  padding: EdgeInsets.all(5),
                                  // color: Colors.blue,
                                  child: Text(
                                    "จบการขาย",
                                    style: GoogleFonts.maitree(
                                        fontSize: 32, color: Colors.white),
                                    textAlign: TextAlign.center,
                                  )) // <-- Icon
                              // <-- Text
                              ),
                        ),
                        SizedBox(
                          width: Get.width,
                          height: 120,
                          child: InkWell(
                              splashColor: Colors.red,
                              onTap: () {
                                Get.to(BillOfflinePage());
                                // await Get.to(PosSalePage());
                                // hmctrl.getReport();

                                // Get.toNamed("/setting");
                              },
                              child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 1, color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.red),
                                  margin: EdgeInsets.all(1),
                                  padding: EdgeInsets.all(5),
                                  // color: Colors.blue,
                                  child: Text(
                                    "รายการขาย Offline",
                                    style: GoogleFonts.maitree(
                                        fontSize: 32, color: Colors.white),
                                    textAlign: TextAlign.center,
                                  )) // <-- Icon
                              // <-- Text
                              ),
                        ),
                        SizedBox(
                          width: Get.width,
                          height: 120,
                          child: InkWell(
                              splashColor: Colors.red,
                              onTap: () {
                                // Get.to(BillOfflinePage());
                                Get.toNamed("/setting");
                              },
                              child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 1, color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.red),
                                  margin: EdgeInsets.all(1),
                                  padding: EdgeInsets.all(5),
                                  // color: Colors.blue,
                                  child: Text(
                                    "ตั้งค่าเครื่อง",
                                    style: GoogleFonts.maitree(
                                        fontSize: 32, color: Colors.white),
                                    textAlign: TextAlign.center,
                                  )) // <-- Icon
                              // <-- Text
                              ),
                        ),
                      ],
                    )),
                Obx(() => Expanded(
                    flex: 10,
                    child: Container(
                        padding: const EdgeInsets.only(left: 30, top: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: Container(
                                  child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              width: 1, color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.blue),
                                      margin: EdgeInsets.all(1),
                                      padding: EdgeInsets.all(5),
                                      // color: Colors.blue,
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              (hmctrl.repReport!.value!.today !=
                                                      null)
                                                  ? NumberFormat
                                                          .decimalPattern()
                                                      .format(hmctrl
                                                              .repReport!
                                                              .value!
                                                              .today!
                                                              .cashCard ??
                                                          0)
                                                  : "0",
                                              style: GoogleFonts.maitree(
                                                color: Colors.white,
                                                fontSize: 40,
                                              ),
                                            ), // <-- Icon
                                            Text(
                                              "ขายเงินสด",
                                              style: GoogleFonts.maitree(
                                                color: Colors.white,
                                                fontSize: 32,
                                              ),
                                            )
                                          ])),
                                )),

                                // Expanded(
                                //     child: Container(
                                //       child: Container(
                                //           decoration: BoxDecoration(
                                //               border: Border.all(
                                //                   width: 1, color: Colors.grey),
                                //               borderRadius:
                                //               BorderRadius.circular(10),
                                //               color: Colors.cyan),
                                //           margin: EdgeInsets.all(1),
                                //           padding: EdgeInsets.all(5),
                                //           // color: Colors.blue,
                                //           child: Column(
                                //               mainAxisAlignment:
                                //               MainAxisAlignment.center,
                                //               children: <Widget>[
                                //                 Text(
                                //                   (hmctrl.repReport!.value!.today !=
                                //                       null)
                                //                       ? NumberFormat
                                //                       .decimalPattern()
                                //                       .format(hmctrl.repReport
                                //                       .value.today!.card)
                                //                       : "0",
                                //                   style: GoogleFonts.maitree(
                                //                     color: Colors.white,
                                //                     fontSize: 40,
                                //                   ),
                                //                 ), // <-- Icon
                                //                 Text(
                                //                   "บัตร",
                                //                   style: GoogleFonts.maitree(
                                //                     color: Colors.white,
                                //                     fontSize: 32,
                                //                   ),
                                //                 )
                                //               ])),
                                //     )),

                                Expanded(
                                    child: Container(
                                  child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              width: 1, color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.cyan),
                                      margin: EdgeInsets.all(1),
                                      padding: EdgeInsets.all(5),
                                      // color: Colors.blue,
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              (hmctrl.repReport!.value!.today !=
                                                      null)
                                                  ? NumberFormat
                                                          .decimalPattern()
                                                      .format(hmctrl.repReport
                                                          .value.today!.finance)
                                                  : "0",
                                              style: GoogleFonts.maitree(
                                                color: Colors.white,
                                                fontSize: 40,
                                              ),
                                            ), // <-- Icon
                                            Text(
                                              "ขายเงินเชื่อ",
                                              style: GoogleFonts.maitree(
                                                color: Colors.white,
                                                fontSize: 32,
                                              ),
                                            )
                                          ])),
                                )),
                                // Expanded(child: Container(
                                //   child:Container(
                                //       decoration: BoxDecoration(
                                //           border: Border.all(
                                //               width: 1, color: Colors.grey),
                                //           borderRadius: BorderRadius.circular(10),
                                //           color: Colors.cyan),
                                //       margin: EdgeInsets.all(1),
                                //       padding: EdgeInsets.all(5),
                                //       // color: Colors.blue,
                                //       child: Column(
                                //           mainAxisAlignment:
                                //           MainAxisAlignment.center,
                                //           children: <Widget>[
                                //             Text(
                                //               (hmctrl.repReport!.value!.today!=null)?NumberFormat.decimalPattern().format(hmctrl.repReport.value.today!.finance):"0",
                                //
                                //               style: GoogleFonts.maitree(
                                //                 color: Colors.white,
                                //                 fontSize: 40,
                                //               ),
                                //             )
                                //             , // <-- Icon
                                //             Text(
                                //               "เงินทอน",
                                //               style: GoogleFonts.maitree(
                                //                 color: Colors.white,
                                //                 fontSize: 32,
                                //               ),
                                //             )
                                //           ])),
                                // )),
                                Expanded(
                                    child: Container(
                                  child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              width: 1, color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.green),
                                      margin: EdgeInsets.all(1),
                                      padding: EdgeInsets.all(5),
                                      // color: Colors.blue,
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              (hmctrl.repReport!.value!.today !=
                                                      null)
                                                  ? NumberFormat
                                                          .decimalPattern()
                                                      .format(hmctrl.repReport
                                                          .value.today!.total)
                                                  : "0",
                                              style: GoogleFonts.maitree(
                                                color: Colors.white,
                                                fontSize: 40,
                                              ),
                                            ), // <-- Icon
                                            Text(
                                              "รวม",
                                              style: GoogleFonts.maitree(
                                                color: Colors.white,
                                                fontSize: 32,
                                              ),
                                            )
                                          ])),
                                ))
                              ],
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 20),
                              width: Get.width,
                              height: 400,
                              // child: Scaffold(
                              //     backgroundColor: HexColor("f0f8ff"),
                              //     body:
                              child:
                                  // gMenu.MobileSidebar(
                                  //   breakPoint: 3000,
                                  //   items: menuItem!,
                                  //   showList: false,
                                  // ),
                                  Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                                color: const Color(0xff81e5cd),
                                child: Stack(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Text(
                                            'รายงานยอดรายสัปดาห์',
                                            style: GoogleFonts.maitree(
                                              color: Color(0xff0f4a3c),
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 4,
                                          ),
                                          const Text(
                                            '',
                                            style: TextStyle(
                                              color: Color(0xff379982),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 38,
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              child: BarChart(
                                                mainBarData(),
                                                swapAnimationDuration:
                                                    animDuration,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Align(
                                        alignment: Alignment.topRight,
                                        child: IconButton(
                                          icon: Icon(
                                            isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            color: const Color(0xff0f4a3c),
                                          ),
                                          onPressed: () {
                                            // setState(() {
                                            //   isPlaying = !isPlaying;
                                            //   if (isPlaying) {
                                            //     refreshState();
                                            //   }
                                            // });
                                          },
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ))))
              ]),
            )));
  }

  Widget getMainListViewUI() {
    return FutureBuilder<List<Widget>>(
      future: addAllListData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // return CircularProgressLoading();
          return Container();
        } else {
          if (!snapshot.hasData) {
            return SizedBox();
          } else {
            return ListView.builder(
              controller: scrollController,
              padding: EdgeInsets.only(
                top: AppBar().preferredSize.height +
                    MediaQuery.of(context).padding.top +
                    24,
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              itemCount: snapshot.data!.length,
              scrollDirection: Axis.vertical,
              itemBuilder: (context, index) {
                animationController!.forward();
                return snapshot.data![index];
              },
            );
          }
        }
      },
    );
  }

  Widget _divider(context) {
    return Container(
      width: MediaQuery.of(context).size.width - 50,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: HexColor("87cefa"),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  closeSale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    //
    // Get.defaultDialog(
    //     title: "ปิดการขาย",
    //     backgroundColor: Colors.white,
    //     titleStyle: TextStyle(color: Colors.black),
    //     middleTextStyle: TextStyle(color: Colors.black),
    //     radius: 10,
    //     confirm:Container(child: Text("ยืนยันจบการขาย"),),
    //     cancel: Container(child: Text("ปิด"),),
    //     onConfirm:(){
    prefs.setBool('IsAuth', false);
    exit(0);
    //   },
    // onCancel: (){
    //     Get.back();
    // }
    // );
  }

  Future<Dialog> advPopup() async {
    return Dialog(
      child: Container(
        width: 200, //MediaQuery.of(context).size.width
        height: 200,
        decoration: BoxDecoration(
            image: DecorationImage(
                image: NetworkImage('http://piraya.ac.th/index.jpg'),
                fit: BoxFit.cover)),
      ),
    );
  }

  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.blueGrey,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String weekDay;
            switch (group.x) {
              case 0:
                weekDay = 'อา.';
                break;
              case 1:
                weekDay = 'จ.';
                break;
              case 2:
                weekDay = 'อ.';
                break;
              case 3:
                weekDay = 'พ.';
                break;
              case 4:
                weekDay = 'พฤ.';
                break;
              case 5:
                weekDay = 'ศ.';
                break;
              case 6:
                weekDay = 'ส.';
                break;

              default:
                throw Error();
            }
            return BarTooltipItem(
              '$weekDay\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: (rod.toY - 1).toString(),
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {},
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 50,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: showingGroups(),
      gridData: FlGridData(show: false),
    );
  }

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    Color barColor = Colors.white,
    double width = 22,
    List<int> showTooltips = const [],
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + 1 : y,
          color: isTouched ? Colors.yellow : barColor,
          width: width,
          borderSide: isTouched
              ? BorderSide(color: Colors.yellow)
              : const BorderSide(color: Colors.white, width: 0),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: barBackgroundColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<BarChartGroupData> showingGroups() => (List.generate(7, (i) {
        switch (i) {
          case 0:
            return makeGroupData(
                0,
                (hmctrl.repReport.value.week != null)
                    ? hmctrl.repReport.value.week![i].total!.toDouble() + 1
                    : 0,
                isTouched: i == touchedIndex);
          case 1:
            return makeGroupData(
                1,
                (hmctrl.repReport.value.week != null)
                    ? hmctrl.repReport.value.week![i].total!.toDouble() + 1
                    : 0,
                isTouched: i == touchedIndex);
          case 2:
            return makeGroupData(
                2,
                (hmctrl.repReport.value.week != null)
                    ? hmctrl.repReport.value.week![i].total!.toDouble() + 1
                    : 0,
                isTouched: i == touchedIndex);
          case 3:
            return makeGroupData(
                3,
                (hmctrl.repReport.value.week != null)
                    ? hmctrl.repReport.value.week![i].total!.toDouble() + 1
                    : 0,
                isTouched: i == touchedIndex);
          case 4:
            return makeGroupData(
                4,
                (hmctrl.repReport.value.week != null)
                    ? hmctrl.repReport.value.week![i].total!.toDouble() + 1
                    : 0,
                isTouched: i == touchedIndex);
          case 5:
            return makeGroupData(
                5,
                (hmctrl.repReport.value.week != null)
                    ? hmctrl.repReport.value.week![i].total!.toDouble() + 1
                    : 0,
                isTouched: i == touchedIndex);
          case 6:
            return makeGroupData(
                6,
                (hmctrl.repReport.value.week != null)
                    ? hmctrl.repReport.value.week![i].total!.toDouble() + 1
                    : 0,
                isTouched: i == touchedIndex);
          default:
            return throw Error();
        }
      }));
  Widget getTitles(double value, TitleMeta meta) {
    TextStyle style = GoogleFonts.maitree(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 25,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = Text('อา.', style: style);
        break;
      case 1:
        text = Text('จ.', style: style);
        break;
      case 2:
        text = Text('อ.', style: style);
        break;
      case 3:
        text = Text('พ.', style: style);
        break;
      case 4:
        text = Text('พฤ.', style: style);
        break;
      case 5:
        text = Text('ศ.', style: style);
        break;
      case 6:
        text = Text('ส.', style: style);
        break;


        break;
      default:
        text = Text('', style: style);
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: text,
    );
  }
}
