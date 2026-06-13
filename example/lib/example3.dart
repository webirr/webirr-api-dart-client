import 'dart:io';

import 'package:webirr/webirr.dart';

/// Deleting an existing Bill from WeBirr Servers (if it is not paid)
void main() async {
  final apiKey =
      Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? 'YOUR_API_KEY';
  final merchantId =
      Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ?? 'YOUR_MERCHANT_ID';

  final api =
      WeBirrClient(merchantId: merchantId, apikey: apiKey, isTestEnv: true);

  const paymentCode =
      'PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL'; // suchas as '141 263 782';

  print('Deleting Bill...');
  final res = await api.deleteBill(paymentCode);

  if (res.error == null) {
    // success
    print(
        'bill is deleted succesfully'); //res.res will be 'OK'  no need to check here!
  } else {
    // fail
    print('error: ${res.error}');
    print(
        'errorCode: ${res.errorCode}'); // can be used to handle specific bussines error such as ERROR_INVLAID_INPUT
  }

  api.close();
}
