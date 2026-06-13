import 'dart:io';

import 'package:webirr/webirr.dart';

/// Getting Payment status of an existing Bill from WeBirr Servers
void main() async {
  final apiKey =
      Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? 'YOUR_API_KEY';
  final merchantId =
      Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ?? 'YOUR_MERCHANT_ID';

  final api =
      WeBirrClient(merchantId: merchantId, apikey: apiKey, isTestEnv: true);

  const paymentCode =
      'PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL'; // suchas as '141 263 782';

  print('Getting Payment Status...');
  final r = await api.getPaymentStatus(paymentCode);

  if (r.error == null) {
    // success
    if (r.res?.isPaid ?? false) {
      print('bill is paid');
      print('bill payment detail');
      print('Bank: ${r.res?.data?.bankID}');
      print('Bank Reference Number: ${r.res?.data?.paymentReference}');
      print('Amount Paid: ${r.res?.data?.amount}');
      print('Payment Date: ${r.res?.data?.paymentDate}');
    } else {
      print('bill is pending payment');
    }
  } else {
    // fail
    print('error: ${r.error}');
    print(
        'errorCode: ${r.errorCode}'); // can be used to handle specific busines error such as ERROR_INVLAID_INPUT
  }

  api.close();
}
