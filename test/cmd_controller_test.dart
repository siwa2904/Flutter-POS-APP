import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mispos/controllers/cmd_controller.dart';

void main() {
  testWidgets('กดเคลียร์แล้วจอลูกค้าล้างข้อมูลคนก่อน', (tester) async {
    final cdc = CmdController()..onInit();
    await tester.pumpWidget(MaterialApp(
      home: Obx(() => Text('ยอด ${cdc.orderDis.value.billTotal}')),
    ));

    cdc.setDataDisplay({
      'BillTotal': 30,
      'ReceiveCash': 0,
      'BillItem': [],
      'Customer': {'CustomerNo': 'C1', 'FName': 'ลูกค้าคนก่อน'},
    });
    await tester.pump();
    expect(find.text('ยอด 30.0'), findsOneWidget);

    // เดิม resetDisplay สร้าง Rx ตัวใหม่ Obx ยังผูกกับตัวเก่า จอค้างยอด 30 ไว้
    cdc.setDataDisplay('CLEAR');
    await tester.pump();
    expect(find.text('ยอด 0.0'), findsOneWidget);
    expect(cdc.orderDis.value.customer?.fName, 'เงินสด');
  });
}
