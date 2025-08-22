import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:mispos/models/product_model.dart';
import 'package:mispos/services/pos_service.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../models/customer_model.dart';

class POSController extends GetxController {
  RxList<ProductModel> products = (List<ProductModel>.of([])).obs;
  RxList<ProductModel> productsTemp = (List<ProductModel>.of([])).obs;
  RxList<FavoritModel> productsFavo = (List<FavoritModel>.of([])).obs;
  RxList<Cat> catego = (List<Cat>.of([])).obs;
  RxString keyCodes = "".obs;
  RxList<CustomerModel> customers = (List<CustomerModel>.of([])).obs;
  late int countup = 0;
  RxBool topWay = false.obs;
  DisplayManager displayManager = DisplayManager();

  Rx<CustomerModel> searchCustomer = CustomerModel().obs;

  @override
  void onInit() {
    super.onInit();
    // getFavorite();
    getProducts();
    getCategory();
    getCustomer();
    searchCustomer.value =  CustomerModel();
  }

  increament() {
    countup++;
  }

  getInite() async {}
  getCategory() async {
    try {
      var catFromApi = await POSService().getProductCate();
      catego.value = catFromApi;

      // productsTemp.sort((a,b) {
      //   var adate = a.bookmark;//before -> var adate = a.expiry;
      //   var bdate = b.barcode; //var bdate = b.expiry;
      //   return adate.toString().compareTo(bdate.toString());
      // });
    } catch (err) {
      Get.snackbar("Error", "ไม่สามารถเชื่อมต่อ Server ได้");
      Get.defaultDialog(
        title: "ไม่สามารถเชื่อมต่อ Server ได้",
      );
    }
  }

  getProducts() async {
    getFavorite();
    try {
      var prodFromApi = await POSService().getProductForSale();
      products.value = prodFromApi;

      productsTemp.value = prodFromApi;

      for (var i = 0; i < products.length; i++) {
        int ind = productsFavo
            .indexWhere((elm) => elm.produncID == products[i].productId);

        if (ind > -1) {
          products[i].favorite = 1;
        } else {
          products[i].favorite = 0;
        }
      }
      products.sort((a, b) {
        var adate = a.favorite; //before -> var adate = a.expiry;
        var bdate = b.favorite; //var bdate = b.expiry;
        return bdate!.compareTo(adate!);
      });
    } catch (err) {

    }
  }

  getFavorite() {
    getApplicationDocumentsDirectory().then((Directory directory) {
      dir = directory;
      File filePath =  File("${dir.path}/favorite2.json");
      bool fileExists = filePath.existsSync();
      print(filePath);
print(fileExists);
      if (fileExists) {
        // createFile(json
        //     .encode(List<dynamic>.from(productsFavo.map((x) => x.toJson()))));
        String jsonData = filePath.readAsStringSync();
        var parsed = jsonDecode(jsonData);
        jsonResult = parsed
            .map<FavoritModel>((json) => FavoritModel.fromJsonFile(json))
            .toList();
        productsFavo.value = List<FavoritModel>.from(
            json.decode(jsonData).map((x) => FavoritModel.fromJson(x)));
      } else {
        createFile("");
      }
    });
    print(productsFavo.length);
  }

  addFavorite(ProductModel prd) {
    productsFavo.value = [];
    int ind = productsTemp
        .indexWhere((element) => element.productId == prd.productId);
    if (ind > -1) {
      int old = productsTemp[ind].favorite!;
      productsTemp[ind].favorite = (old == 1) ? 0 : 1;
    }
    for (var i = 0; i < productsTemp.length; i++) {
      if (productsTemp[i].favorite == 1) {
        FavoritModel fm = FavoritModel(produncID: productsTemp[i]!.productId!);
        productsFavo.add(fm);
      }
    }
    getApplicationDocumentsDirectory().then((Directory directory) {
      dir = directory;
      print("${dir.path}/favorite2.json");
      File filePath =  File("${dir.path}/favorite2.json");
      bool fileExists = filePath.existsSync();
      if (fileExists) {
        createFile(json
            .encode(List<dynamic>.from(productsFavo.map((x) => x.toJson()))));
        String jsonData = filePath.readAsStringSync();
        var parsed = jsonDecode(jsonData);
        jsonResult = parsed
            .map<FavoritModel>((json) => FavoritModel.fromJsonFile(json))
            .toList();
      } else {
        createFile(json
            .encode(List<dynamic>.from(productsFavo.map((x) => x.toJson()))));
      }
    });
  }

  /////////////////
  late Directory dir;
  List<FavoritModel> jsonResult =  List<FavoritModel>.of([]);
  Future<void> createFile(String? content) async {
    print("${dir.path}/favorite2.json");
    File file =  File("${dir.path}/favorite2.json");
    file.createSync();

    file.writeAsStringSync(content!);
  }

  fillterProduct(String q) async {
    var strOpt = q.contains("*");
    if (strOpt) {
      var expString = q.split("*");
      int ind = productsTemp.indexWhere((element) =>
          element.barcode.toString().toUpperCase() ==
          expString[1].toUpperCase());
      if (ind > -1) {
        var prd = ProductModel();
        prd = productsTemp[ind];
        prd.qty = int.parse(expString[0]);

        return prd;
      } else {
        Get.snackbar("Error", "ไม่พบสินค้า");
      }
      // var prd = new ProductModel();
      return null;
    } else {
      if (q != "") {
        var pSearch = productsTemp.where((o) {
          o.qty = 1;
          bool bb = false;
          if (o.barcode != null) {
            bb = o.barcode.toString().contains(q);
          }
          return o.name!.contains(q) || bb || o.productId!.contains(q);
        }).toList();

        products.value = pSearch;

      } else {
        products.value = productsTemp;
      }
      var prd =  ProductModel();
      prd.productId = "";
      return prd;
    }

    // List outputList = productsTemp.where((o) => o['category_id'] == '1').toList();
  }

  fillterProductCate(String q) async {

    if (q != "") {
      List<ProductModel> ind = productsTemp
          .where((element) => element.categoryId.toString() == q)
          .toList();
      products.value = ind;

      // var prd = new ProductModel();

    } else {
      products.value = productsTemp;

      var prd =  ProductModel();
      prd.productId = "";
      return prd;
    }

    // List outputList = productsTemp.where((o) => o['category_id'] == '1').toList();
  }

  Future<ProductModel> addProductToOrder(String barcode) async {
    int ind = products.indexWhere((element) => element.barcode == barcode);
    if (ind > -1) {
      var prd = ProductModel();
      prd = products[ind];
      return prd;
    }
    var prd = new ProductModel();
    return prd;
  }

  getCustomer() async {
    var custFromApi = await POSService().geCustomer();
    customers.value = custFromApi;
  }
}
