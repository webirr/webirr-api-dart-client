class Payment {
  /// 0 = not paid, 1 = payment in progress,  2. paid !
  late int status;
  PaymentDetail? data;

  Payment.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    data =
        json['data'] != null ? new PaymentDetail.fromJson(json['data']) : null;
  }

  /// true if the bill is paid (payment process completed)
  bool get isPaid => status == 2;
}

class PaymentDetail {
  late int id;
  late String paymentReference;
  late bool confirmed;
  late String confirmedTime;
  late String bankID;
  late String time;
  late String amount;
  late String wbcCode;

  PaymentDetail.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    paymentReference = json['paymentReference'];
    confirmed = json['confirmed'];
    confirmedTime = json['confirmedTime'];
    bankID = json['bankID'];
    time = json['time'];
    amount = json['amount'];
    wbcCode = json['wbcCode'];
  }
}
