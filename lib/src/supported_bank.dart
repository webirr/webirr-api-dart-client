class SupportedBank {
  String bankID = '';
  String name = '';

  SupportedBank({this.bankID = '', this.name = ''});

  SupportedBank.fromJson(Map<String, dynamic> json)
      : bankID = (json['bankID'] ?? json['bankid'] ?? '').toString(),
        name = (json['name'] ?? json['bankName'] ?? '').toString();
}
