import 'dart:io';

import 'package:webirr/webirr.dart';

/// Gettting basic Statistics about bills created and payments received for a date range
void main() async {
  final apiKey =
      Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? 'YOUR_API_KEY';
  final merchantId =
      Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ?? 'YOUR_MERCHANT_ID';

  final api =
      WeBirrClient(merchantId: merchantId, apikey: apiKey, isTestEnv: true);

  const dateFrom = '2025-01-01';
  const dateTo = '2030-01-31';

  print('Getting Stat...');
  final response = await api.getStat(dateFrom, dateTo);

  if (response.error == null) {
    // success
    print('Bills Created: ${response.res?.nBills}');
    print('Bills Paid: ${response.res?.nBillsPaid}');
    print('Bills Unpaid: ${response.res?.nBillsUnpaid}');
    print('Amount Bills: ${response.res?.amountBills}');
    print('Amount Paid: ${response.res?.amountPaid}');
    print('Amount Unpaid: ${response.res?.amountUnpaid}');
  } else {
    // fail
    print('error: ${response.error}');
    print('errorCode: ${response.errorCode}');
  }

  api.close();
}
