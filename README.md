# webirr-api-dart-client
Official Dart Client Library for WeBirr Payment Gateway APIs 

*Requires Dart SDK >=2.12.0 <3.0.0*

>This Client Library provides convenient access to WeBirr Payment Gateway APIs from Dart/Flutter Apps.

## Install
1. Add the dependecny in pubspec.yaml 

>dependencies:
>   webirr: ^0.1.0

2. run the dart pub get command

```bash
$ dart pub get
```

## Usage

The library needs to be configured with a *merchant Id* & *API key*. You can get it by contacting [webirr.com](https://webirr.com)

> You can use this library for production or test environments. you will need to set isTestEnv=true for test, and false for production apps when creating objects of class WeBirrClient

## Example

# Creating a new Bill / Updating an existing Bill on WeBirr Servers

```dart

  import 'package:webirr/webirr.dart';

  const apikey = 'YOUR_API_KEY';
  const merchantId = 'YOUR_MERCHANT_ID';

  var api = new WeBirrClient(apikey: apikey, isTestEnv: true);

  var bill = new Bill(
    amount: '270.90',
    customerCode: 'cc01', // it can be email address or phone number if you dont have customer code
    customerName: 'Elias Haileselassie',
    time: '2021-07-22 22:14',   // your bill time, always in this format
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

```

# Getting Payment status of an existing Bill from WeBirr Servers

```dart

  import 'package:webirr/webirr.dart';

  const apikey = 'YOUR_API_KEY';
  const merchantId = 'YOUR_MERCHANT_ID';

  var api = new WeBirrClient(apikey: apikey, isTestEnv: true);

  var paymentCode = 'PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL'  // suchas as '141 263 782';
  
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

```  

# Deleting an existing Bill from WeBirr Servers (if it is not paid)

```dart

  import 'package:webirr/webirr.dart';

  const apikey = 'YOUR_API_KEY';
  const merchantId = 'YOUR_MERCHANT_ID';

  var api = new WeBirrClient(apikey: apikey, isTestEnv: true);

  var paymentCode = 'PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL'  // suchas as '141 263 782';
  
  print('Deleting Bill...');
  res = await api.deleteBill(paymentCode);

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

```  
