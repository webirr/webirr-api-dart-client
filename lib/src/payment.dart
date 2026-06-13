/// Payment status wrapper returned from getPaymentStatus().
class Payment {
  /// 0 = not paid, 1 = payment in progress, 2 = paid.
  int status;
  PaymentDetail? data;

  Payment({this.status = 0, this.data});

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      status: _intValue(json['status']),
      data: json['data'] != null
          ? PaymentDetail.fromJson(Map<String, dynamic>.from(json['data']))
          : null,
    );
  }

  /// true if the bill is paid (payment process completed).
  bool get isPaid => status == 2;
}

/// Payment detail returned inside the single payment status wrapper.
class PaymentDetail {
  int id;
  int status;
  String paymentReference;
  String paymentDate;
  bool confirmed;
  String confirmedTime;
  String bankID;
  String amount;
  String wbcCode;
  String updateTimeStamp;

  PaymentDetail({
    this.id = 0,
    this.status = 0,
    this.paymentReference = '',
    this.paymentDate = '',
    this.confirmed = false,
    this.confirmedTime = '',
    this.bankID = '',
    this.amount = '',
    this.wbcCode = '',
    this.updateTimeStamp = '',
  });

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    final paymentDate = _stringValue(json['paymentDate'] ?? json['time']);
    return PaymentDetail(
      id: _intValue(json['id']),
      status: _intValue(json['status']),
      paymentReference: _stringValue(json['paymentReference']),
      paymentDate: paymentDate,
      confirmed: _boolValue(json['confirmed']),
      confirmedTime: _stringValue(json['confirmedTime']),
      bankID: _stringValue(json['bankID']),
      amount: _stringValue(json['amount']),
      wbcCode: _stringValue(json['wbcCode']),
      updateTimeStamp: _stringValue(json['updateTimeStamp']),
    );
  }

  /// Deprecated compatibility alias. Prefer paymentDate.
  String get time => paymentDate;
  set time(String value) => paymentDate = value;
}

/// Payment item returned from timestamp-based bulk polling and webhook payloads.
class PaymentResponse {
  int status;
  int id;
  String bankID;
  String paymentReference;
  String paymentDate;
  bool confirmed;
  String confirmedTime;
  bool canceled;
  String canceledTime;
  String amount;
  String wbcCode;
  String updateTimeStamp;

  PaymentResponse({
    this.status = 0,
    this.id = 0,
    this.bankID = '',
    this.paymentReference = '',
    this.paymentDate = '',
    this.confirmed = false,
    this.confirmedTime = '',
    this.canceled = false,
    this.canceledTime = '',
    this.amount = '',
    this.wbcCode = '',
    this.updateTimeStamp = '',
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    final paymentDate = _stringValue(json['paymentDate'] ?? json['time']);
    return PaymentResponse(
      status: _intValue(json['status']),
      id: _intValue(json['id']),
      bankID: _stringValue(json['bankID']),
      paymentReference: _stringValue(json['paymentReference']),
      paymentDate: paymentDate,
      confirmed: _boolValue(json['confirmed']),
      confirmedTime: _stringValue(json['confirmedTime']),
      canceled: _boolValue(json['canceled']),
      canceledTime: _stringValue(json['canceledTime']),
      amount: _stringValue(json['amount']),
      wbcCode: _stringValue(json['wbcCode']),
      updateTimeStamp: _stringValue(json['updateTimeStamp']),
    );
  }

  /// Deprecated compatibility alias. Prefer paymentDate.
  String get time => paymentDate;
  set time(String value) => paymentDate = value;

  bool get isPaid => status == 2;
  bool get isReversed => status == 3;
}

String _stringValue(dynamic value) => value?.toString() ?? '';

int _intValue(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _boolValue(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1';
}
