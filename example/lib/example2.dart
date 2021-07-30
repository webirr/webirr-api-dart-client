import 'package:webirr/webirr.dart';

/// Getting Payment status of an existing Bill from WeBirr Servers
void main() async {
  const apikey = 'YOUR_API_KEY';

  var api = new WeBirrClient(apikey: apikey, isTestEnv: true);

  var paymentCode =
      'PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL'; // suchas as '141 263 782';

  print('Getting Payment Status...');
  var r = await api.getPaymentStatus(paymentCode);

  if (r.error == null) {
    // success
    if (r.res?.isPaid ?? false) {
      print('bill is paid');
      print('bill payment detail');
      print('Bank: ${r.res?.data?.bankID}');
      print('Bank Reference Number: ${r.res?.data?.paymentReference}');
      print('Amount Paid: ${r.res?.data?.amount}');
    } else
      print('bill is pending payment');
  } else {
    // fail
    print('error: ${r.error}');
    print(
        'errorCode: ${r.errorCode}'); // can be used to handle specific busines error such as ERROR_INVLAID_INPUT
  }
}
