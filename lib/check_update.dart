import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mispos/utils/constants.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';



class CheckUpdate {
  static bool _hasChecked = false;

  static Future<void> check(BuildContext context, {bool isManual = false}) async {
    // ป้องกันการเรียกซ้ำซ้อนจาก build() ใน HomePage
    if (!isManual && _hasChecked) return;
    _hasChecked = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? ipServer = prefs.getString(Constant.ipServer);
      
      if (ipServer == null || ipServer.isEmpty) {
        print("CheckUpdate: IP Server is null, skip update check.");
        return;
      }

      // ใส่ Timeout กันแอปรอค้างถ้ายิงไปเซิร์ฟไม่ติด (Dio 4.x ใช้หน่วย ms เป็น int)
      final dio = Dio(BaseOptions(
        connectTimeout: 5000,
        receiveTimeout: 5000,
      ));

      final response = await dio.get(
          "http://$ipServer/api/update.json"
      );

      final data = jsonDecode(response.data);

      String serverVersion = data['version'];

      if (currentVersion != serverVersion) {
        bool force = data['force'] ?? false;

        showGeneralDialog(
          context: context,
          barrierDismissible: !force,
          barrierLabel: "",
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, __, ___) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.system_update_alt_rounded,
                          size: 50,
                          color: Colors.blue,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "มีอัปเดตใหม่",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Version $serverVersion",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          data['message'],
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          if (!force)
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("ภายหลัง"),
                              ),
                            ),

                          if (!force)
                            const SizedBox(width: 12),

                          Expanded(
                            child: InkWell(
                              borderRadius:
                              BorderRadius.circular(14),
                              onTap: () async {
                                Navigator.pop(context);

                                await downloadAndInstall(
                                  context,
                                  data['apk_url'],
                                );
                              },
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff2196F3),
                                      Color(0xff1976D2),
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    "อัปเดตตอนนี้",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      print(e);
    }
  }

  static Future<void> downloadAndInstall(
    BuildContext context,
    String url,
  ) async {
    try {
      Directory dir = await getApplicationDocumentsDirectory();

      String savePath = '${dir.path}/update.apk';

      ValueNotifier<double> progress = ValueNotifier(0);

      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: "",
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: ValueListenableBuilder(
                valueListenable: progress,
                builder: (_, double value, __) {
                  return Container(
                    width:
                    MediaQuery.of(context).size.width *
                        0.82,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 90,
                              height: 90,
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 7,
                              ),
                            ),
                            Text(
                              "${(value * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          "กำลังดาวน์โหลดอัปเดต",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "กรุณารอสักครู่\nระบบกำลังดาวน์โหลดเวอร์ชันล่าสุด",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        ClipRRect(
                          borderRadius:
                          BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      );

      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progress.value = received / total;
          }
        },
      );

      Navigator.pop(context);

      OpenFilex.open(savePath);
    } catch (e) {
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text("ดาวน์โหลดไม่สำเร็จ"),
            content: Text(e.toString()),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("ตกลง"),
              ),
            ],
          );
        },
      );
    }
  }
}
