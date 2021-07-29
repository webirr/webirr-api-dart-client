import 'package:webirr/webirr.dart';

void main() async {
  const apikey = 'YOUR_API_KEY';

  var api = new WeBirrClient(apikey: apikey, isTestEnv: true);

  var paymentCode =
      'PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL'; // suchas as '141 263 782';

  print('Deleting Bill...');
  var res = await api.deleteBill(paymentCode);

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
}
