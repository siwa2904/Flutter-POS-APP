// To parse this JSON data, do
//
//     final reportSaleModel = reportSaleModelFromJson(jsonString);

import 'dart:convert';

ReportSaleModel reportSaleModelFromJson(String str) => ReportSaleModel.fromJson(json.decode(str));

// OrderModel customerDisplayModelFromJson(String str) =>
//     OrderModel.fromJson(json.decode(str));

String reportSaleModelToJson(ReportSaleModel data) => json.encode(data.toJson());

class ReportSaleModel {
  ReportSaleModel({
    this.today,
    this.week,
    this.month,
    this.year,
  });

  Today? today;
  List<Week>? week;
  List<Month>? month;
  List<Year>? year;

  factory ReportSaleModel.fromJson(Map<String, dynamic> json) => ReportSaleModel(
    today: Today.fromJson(json["Today"]),
    week: List<Week>.from(json["Week"].map((x) => Week.fromJson(x))),
    month: List<Month>.from(json["Month"].map((x) => Month.fromJson(x))),
    year: List<Year>.from(json["Year"].map((x) => Year.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "Today": today!.toJson(),
    "Week": List<dynamic>.from(week!.map((x) => x.toJson())),
    "Month": List<dynamic>.from(month!.map((x) => x.toJson())),
    "Year": List<dynamic>.from(year!.map((x) => x.toJson())),
  };
}

class Month {
  Month({
    this.date,
    this.day,
    this.total,
  });

  DateTime? date;
  int? day;
  String? total;

  factory Month.fromJson(Map<String, dynamic> json) => Month(
    date: DateTime.parse(json["Date"]),
    day: json["Day"],
    total: json["Total"],
  );

  Map<String, dynamic> toJson() => {
    "Date": "${date!.year!.toString().padLeft(4, '0')}-${date!.month!.toString().padLeft(2, '0')}-${date!.day!.toString().padLeft(2, '0')}",
    "Day": day,
    "Total": total,
  };
}

class Today {
  Today({
    this.total,
    this.cashCard,
    this.finance,
    this.card,
    this.growthRate,
  });

  double? total;
  double? cashCard;
  double? finance;
  double? card;
  String? growthRate;

  factory Today.fromJson(Map<String, dynamic> json) => Today(
    total: json["Total"]?.toDouble(),
    cashCard: json["CashCard"]?.toDouble(),
    card: json["Card"]?.toDouble(),
    finance: json["Finance"]?.toDouble(),
     growthRate: json["GrowthRate"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "Total": total,
    "CashCard": cashCard,
    "Finance": finance,
    "Card":card,
    "GrowthRate": growthRate,
  };
}

class Week {
  Week({
    this.sort,
    this.dayNo,
    this.dayName,
    this.total,
  });

  int? sort;
  String? dayNo;
  String? dayName;
  int? total;

  factory Week.fromJson(Map<String, dynamic> json) => Week(
    sort: json["sort"],
    dayNo: json["DayNo"],
    dayName: json["DayName"],
    total: json["Total"],
  );

  Map<String, dynamic> toJson() => {
    "sort": sort,
    "DayNo": dayNo,
    "DayName": dayName,
    "Total": total,
  };
}

class Year {
  Year({
    this.month,
    this.monthName,
    this.total,
  });

  String? month;
  String? monthName;
  String? total;

  factory Year.fromJson(Map<String, dynamic> json) => Year(
    month: json["Month"],
    monthName: json["MonthName"],
    total: json["Total"].toString(),
  );

  Map<String, dynamic> toJson() => {
    "Month": month,
    "MonthName": monthName,
    "Total": total,
  };
}
