import 'package:webirr/webirr.dart';

void main() async {
  const apikey = 'YOUR_API_KEY';
  const merchantId = 'YOUR_MERCHANT_ID';

  var api = new WeBirrClient(apikey: apikey, isTestEnv: true);

  var bill = new Bill(
    amount: '270.90',
    customerCode:
        'cc01', // it can be email address or phone number if you dont have customer code
    customerName: 'Elias Haileselassie',
    time: '2021-07-22 22:14', // your bill time, always in this format
    description: 'hotel booking',
    billReference: 'drt/2021/125', // your unique reference number
    merchantID: merchantId,
  );

  print('Creating Bill...');
  var res = await api.createBill(bill);

  var paymentCode = '';

  if (res.error == null) {
    // success
    paymentCode = res.res ?? ''; // returns paymentcode such as 429 723 975
    print(
        'Payment Code = $paymentCode'); // we may want to save payment code in local db.

  } else {
    // fail
    print('error: ${res.error}');
    print(
        'errorCode: ${res.errorCode}'); // can be used to handle specific busines error such as ERROR_INVLAID_INPUT_DUP_REF
  }

  // update existing bill if it is not paid
  bill.amount = "278.00";
  bill.customerName = 'Elias dart3';
  //bill.billReference = "WE CAN NOT CHANGE THIS";

  print('Updating Bill...');
  res = await api.updateBill(bill);

  if (res.error == null) {
    // success
    print(
        'bill is updated succesfully'); //res.res will be 'OK'  no need to check here!
  } else {
    // fail
    print('error: ${res.error}');
    print(
        'errorCode: ${res.errorCode}'); // can be used to handle specific busines error such as ERROR_INVLAID_INPUT
  }
}
