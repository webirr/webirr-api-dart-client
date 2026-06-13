/// Bill or Invoice object issued to a customer.
/// It is used as the create/update request model.
class Bill {
  String customerCode;
  String customerName;
  String customerPhone;

  /// 24 hour format 2020-01-01 16:00
  String time;
  String description;

  /// amount as two decimal digits 1246.50
  String amount;
  String billReference;

  /// Kept for gateway wire compatibility. WeBirrClient sets it automatically
  /// from the client merchant ID when that value is configured.
  String merchantID;
  Map<String, dynamic> extras;

  Bill({
    required this.customerCode,
    required this.customerName,
    this.customerPhone = '',
    required this.time,
    required this.description,
    required this.amount,
    required this.billReference,
    this.merchantID = '',
    Map<String, dynamic>? extras,
  }) : extras = extras ?? <String, dynamic>{};

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      customerCode: _stringValue(json['customerCode']),
      customerName: _stringValue(json['customerName']),
      customerPhone: _stringValue(json['customerPhone']),
      time: _stringValue(json['time']),
      description: _stringValue(json['description']),
      amount: _stringValue(json['amount']),
      billReference: _stringValue(json['billReference']),
      merchantID: _stringValue(json['merchantID']),
      extras: _mapValue(json['extras']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'customerCode': customerCode,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'time': time,
      'description': description,
      'amount': amount,
      'billReference': billReference,
      'merchantID': merchantID,
      'extras': extras,
    };
  }
}

/// Bill retrieval/list response model.
class BillResponse extends Bill {
  String wbcCode;
  int paymentStatus;
  String updateTimeStamp;

  BillResponse({
    required String customerCode,
    required String customerName,
    String customerPhone = '',
    required String time,
    required String description,
    required String amount,
    required String billReference,
    String merchantID = '',
    Map<String, dynamic>? extras,
    this.wbcCode = '',
    this.paymentStatus = 0,
    this.updateTimeStamp = '',
  }) : super(
          customerCode: customerCode,
          customerName: customerName,
          customerPhone: customerPhone,
          time: time,
          description: description,
          amount: amount,
          billReference: billReference,
          merchantID: merchantID,
          extras: extras,
        );

  factory BillResponse.fromJson(Map<String, dynamic> json) {
    return BillResponse(
      customerCode: _stringValue(json['customerCode']),
      customerName: _stringValue(json['customerName']),
      customerPhone: _stringValue(json['customerPhone']),
      time: _stringValue(json['time']),
      description: _stringValue(json['description']),
      amount: _stringValue(json['amount']),
      billReference: _stringValue(json['billReference']),
      merchantID: _stringValue(json['merchantID']),
      extras: _mapValue(json['extras']),
      wbcCode: _stringValue(json['wbcCode']),
      paymentStatus: _intValue(json['paymentStatus']),
      updateTimeStamp: _stringValue(json['updateTimeStamp']),
    );
  }
}

String _stringValue(dynamic value) => value?.toString() ?? '';

int _intValue(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Map<String, dynamic> _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}
