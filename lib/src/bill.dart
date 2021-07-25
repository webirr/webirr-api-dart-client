class Bill {
  String customerCode;
  String customerName;

  /// 24 hour format 2020-01-01 16:00
  String time;
  String description;

  /// amount as two decimal digits 1246.50
  String amount;
  String billReference;
  String merchantID;

  Bill(
      {required this.customerCode,
      required this.customerName,
      required this.time,
      required this.description,
      required this.amount,
      required this.billReference,
      required this.merchantID});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['customerCode'] = this.customerCode;
    data['customerName'] = this.customerName;
    data['time'] = this.time;
    data['description'] = this.description;
    data['amount'] = this.amount;
    data['billReference'] = this.billReference;
    data['merchantID'] = this.merchantID;
    return data;
  }
}
