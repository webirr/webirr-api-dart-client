/// Basic statistics object about bills created and payments received over a
/// time range.
class Stat {
  num nBills;
  num nBillsPaid;
  num nBillsUnpaid;
  num amountBills;
  num amountPaid;
  num amountUnpaid;

  Stat({
    this.nBills = 0,
    this.nBillsPaid = 0,
    this.nBillsUnpaid = 0,
    this.amountBills = 0,
    this.amountPaid = 0,
    this.amountUnpaid = 0,
  });

  factory Stat.fromJson(Map<String, dynamic> json) {
    return Stat(
      nBills: _numValue(json['nBills']),
      nBillsPaid: _numValue(json['nBillsPaid']),
      nBillsUnpaid: _numValue(json['nBillsUnpaid']),
      amountBills: _numValue(json['amountBills']),
      amountPaid: _numValue(json['amountPaid']),
      amountUnpaid: _numValue(json['amountUnpaid']),
    );
  }
}

num _numValue(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
