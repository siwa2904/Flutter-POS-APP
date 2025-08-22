import 'dart:convert';
import 'dart:io';

import 'package:mispos/models/bill_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BillDatabaseHelper {
  static Database? _billOfflineDb;
  static BillDatabaseHelper? _billDatabaseHelper;

  String billTable = 'billTable';
  String billItemTable = 'billItemTable';

  String colId = 'id';
  String colBillNo = "BillNo";
  String colBillDate = "BillDate";
  String colBranchNo = "BranchNo";
  String colCustomer = "Customer";
  String colPayType = "PayType";
  String colEmployeeNo = "EmployeeNo";
  String colIsPayment = "IsPayment";
  String colBillSubTotal = "BillSubTotal";
  String colBillDiscount = "BillDiscount";
  String colBillTotalBV = "BillTotalBV";
  String colBillVatAmount = "BillVatAmount";
  String colBillVat = "BillVat";
  String colBillTotal = "BillTotal";
  String colPayAmount = "PayAmount";
  String colPOS = "POS";
  String colReceiveCash = "ReceiveCash";
  String colReceiveCard = "ReceiveCard";
  String colStatus = "Status";
  String colBillItem = "BillItem";
  String colBillTrans = "BillTrans";
  String colTMRef="TMRef";
//Items
  String colCardNumber ="CardNumber";


  String cliIBillNo = 'BillNo';
  String cliIProductID = '';
  String cliIProductName = '';
  String cliICost = '';
  String cliIQty = '';
  String cliIPrice = '';
  String cliI = '';
  String cliITotal = '';
  String cliILotID = '';

  BillDatabaseHelper._createInstance();

  static final BillDatabaseHelper db = BillDatabaseHelper._createInstance();

  factory BillDatabaseHelper() {
    if (_billDatabaseHelper == null) {
      _billDatabaseHelper = BillDatabaseHelper._createInstance();
    }
    return _billDatabaseHelper!;
  }

  Future<Database> get database async {
    if (_billOfflineDb == null) {
      _billOfflineDb = await initializeDatabase();
    }
    print("CreatedDatabase");
    return _billOfflineDb!;
  }

  Future<Database> initializeDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = 'billOffline.db';
    var myDatabase = await openDatabase(path, version: 2, onCreate: _createDb);
    return myDatabase;
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute("CREATE TABLE $billTable"
        "($colId INTEGER PRIMARY KEY AUTOINCREMENT,"
        "$colBillNo TEXT,"
        "$colBillDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,"
        "$colBranchNo TEXT,"
        "$colCustomer TEXT,"
        "CustomerNo TEXT,"
        "CustomerName TEXT,"
        "$colPayType TEXT,"
        "$colEmployeeNo TEXT,"
        "$colIsPayment TEXT,"
        "$colBillSubTotal TEXT,"
        "$colBillDiscount TEXT,"
        "$colBillTotalBV TEXT,"
        "$colBillVatAmount TEXT,"
        "$colBillVat TEXT,"
        "$colBillTotal TEXT,"
        "$colPayAmount TEXT,"
        "$colPOS TEXT,"
        "$colReceiveCash TEXT,"
        "$colReceiveCard TEXT,"
    "$colCardNumber TEXT,"
        "$colStatus TEXT,"
        "$colBillItem TEXT,"
        "$colTMRef TEXT,"
        "$colBillTrans NUMERIC DEFAULT 0"
        ")");
    await db.execute('CREATE TABLE $billItemTable'
        "($colId INTEGER PRIMARY KEY,"
        "BillNo TEXT,"
        "ProductID TEXT,"
        "ProductName TEXT,"
        "Cost TEXT,"
        "Qty INTEGER,"
        "Price REAL,"
        "Discount TEXT,"
        "Total REAL,"
        "LotID TEXT)");
  }

  Future<List<Map<String, dynamic>>> getBillsMapList(String whereString) async {
    Database db = await database;
    var result = await db.query(billTable,
        orderBy: "$colId DESC", where: "$colBillDate like '$whereString%'");
    return result;
  }

  Future<int> insertBill(BillModel bill, {cart = false}) async {
    // print(cart);
    Database db = await database;

    print("ResultBefor");
    var bb = bill.toJson();

    List<dynamic> bm = bb["BillItem"];

    bb["CustomerNo"] = bb["Customer"]["CustomerNo"];
    bb["CustomerName"] = bb["Customer"]["CustomerName"];
    bb["Customer"] = jsonEncode(
      bb["Customer"],
    );
    bb["BillItem"] = jsonEncode(
      bb["BillItem"],
    );
    var resust = await db.insert(billTable, bb);
    print("Result");
    print(bb);
    if (resust != 0) {
      for (var element in bm) {
        // await db.insert(billItemTable, element);
      }
    }

    return resust;
  }

  Future<int> deleteBill(int id, {cart = false}) async {
    // print("Deleting Product with id: $id ");
    var db = await database;
    int result =
        await db.delete(billTable, where: '$colId = ?', whereArgs: [id]);
    // print("Delete result: $result");
    return result;
  }

  Future<int> updateTransfer(int id, int isTrans, String billNo,
      {cart = false}) async {
    // print("updating task ${task.id} ${task.name} current status ${task.completed}");
    var db = await this.database;
    var result = await db.update(
        billTable, {"BillTrans": isTrans, "BillNo": billNo},
        where: '$colId = ?', whereArgs: [id]);
    return result;
  }

  Future<int> getCount(tableName) async {
    Database db = await database;
    List<Map<String, dynamic>> x =
        await db.rawQuery('SELECT COUNT (*) from $tableName');
    int result = Sqflite.firstIntValue(x) ?? 0;
    return result;
  }

  Future<List<BillModel>> getBillsList() async {
    var productMapList = await getBillsMapList('');
    int count = await getCount(billTable);

    List<BillModel> productList = <BillModel>[];
    for (int i = 0; i < count; i++) {
      productList.add(BillModel.fromJson(productMapList[i]));
    }
    return productList;
  }

  close() async {
    var db = await database;
    var result = db.close();
    return result;
  }
}
