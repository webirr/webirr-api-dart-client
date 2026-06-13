import 'dart:io';

import 'package:webirr/webirr.dart';

/// Getting a Bill and Listing Bills
void main() async {
  final apiKey =
      Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? 'YOUR_API_KEY';
  final merchantId =
      Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ?? 'YOUR_MERCHANT_ID';

  final api =
      WeBirrClient(merchantId: merchantId, apikey: apiKey, isTestEnv: true);

  const billReference = 'BILL_REFERENCE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL';
  const paymentCode = 'PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL';

  print('Getting Bill By Reference...');
  var res = await api.getBillByReference(billReference);

  if (res.error == null) {
    // success
    print('Payment Code = ${res.res?.wbcCode}');
    print('Payment Status = ${res.res?.paymentStatus}');
    print('Last Timestamp = ${res.res?.updateTimeStamp}');
  } else {
    // fail
    print('error: ${res.error}');
    print('errorCode: ${res.errorCode}');
  }

  print('Getting Bill By Payment Code...');
  res = await api.getBillByPaymentCode(paymentCode);

  if (res.error == null) {
    // success
    print('Bill Reference = ${res.res?.billReference}');
    print('Payment Status = ${res.res?.paymentStatus}');
    print('Last Timestamp = ${res.res?.updateTimeStamp}');
  } else {
    // fail
    print('error: ${res.error}');
    print('errorCode: ${res.errorCode}');
  }

  print('Listing Bills...');
  const paymentStatus = -1; // -1 all, 0 pending, 1 unconfirmed payment, 2 paid.
  const lastTimeStamp =
      '20251231'; // Date-only cursor; use "20251231235959" when you need time precision.
  const limit = 10;

  final listResponse = await api.getBills(
    paymentStatus: paymentStatus,
    lastTimeStamp: lastTimeStamp,
    limit: limit,
  );

  if (listResponse.error == null) {
    // success
    print('Bills returned: ${listResponse.res?.length ?? 0}');
    for (final bill in listResponse.res ?? <BillResponse>[]) {
      print('Bill Reference = ${bill.billReference}');
      print('Payment Code = ${bill.wbcCode}');
      print('Payment Status = ${bill.paymentStatus}');
      print('Last Timestamp = ${bill.updateTimeStamp}');
    }
  } else {
    // fail
    print('error: ${listResponse.error}');
    print('errorCode: ${listResponse.errorCode}');
  }

  api.close();
}
