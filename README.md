Official Dart Client Library for WeBirr Payment Gateway APIs

This Client Library provides convenient access to WeBirr Payment Gateway APIs from Dart/Flutter Apps.

*Requires Dart SDK >=2.17.0 <4.0.0*

## Install

run the following command to install webirr client library

With Dart

```bash
$ dart pub add webirr
```

With Flutter

```bash
$ flutter pub add webirr
```

## Usage

The library needs to be configured with a *merchant Id* & *API key*. You can get it by contacting [webirr.com](https://webirr.com)

> You can use this library for production or test environments. you will need to set isTestEnv=true for test, and false for production apps when creating objects of class WeBirrClient

For TestEnv examples and smoke tests, set these environment variables:

```bash
export WEBIRR_TEST_ENV_MERCHANT_ID="YOUR_MERCHANT_ID"
export WEBIRR_TEST_ENV_API_KEY="YOUR_API_KEY"
```

Create the client with merchant ID, API key, and environment. The client sets `Bill.merchantID` automatically before create/update calls, so examples should not set bill merchant ID manually.

```dart
final api = WeBirrClient(
  merchantId: merchantId,
  apikey: apiKey,
  isTestEnv: true,
);
```

For batch or mass bill workloads, you can pass a caller-owned `http.Client` so your application controls connection reuse and retry policy. Add `http` directly to your app if you import it in your own code.

```dart
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

final httpClient = RetryClient(http.Client());
final api = WeBirrClient(
  merchantId: merchantId,
  apikey: apiKey,
  isTestEnv: true,
  httpClient: httpClient,
);

// Your app owns an injected client lifecycle.
httpClient.close();
```

## Example

### Creating a new Bill / Updating an existing Bill on WeBirr Servers

```dart
import 'dart:io';

import 'package:webirr/webirr.dart';

void main() async {
  final apikey = Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? 'YOUR_API_KEY';
  final merchantId =
      Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ?? 'YOUR_MERCHANT_ID';

  final api = WeBirrClient(merchantId: merchantId, apikey: apikey, isTestEnv: true);

  final bill = Bill(
    amount: '270.90',
    customerCode: 'cc01', // it can be email address or phone number if you dont have customer code
    customerName: 'Elias Haileselassie',
    customerPhone: '0911000000',
    time: '2021-07-22 22:14', // your bill time, always in this format
    description: 'hotel booking',
    billReference: 'drt/2021/125', // your unique reference number
    extras: <String, dynamic>{},
  );

  print('Creating Bill...');
  var res = await api.createBill(bill);

  var paymentCode = '';

  if (res.error == null) {
    // success
    paymentCode = res.res ?? ''; // returns paymentcode such as 429 723 975
    print('Payment Code = $paymentCode'); // we may want to save payment code in local db.
  } else {
    // fail
    print('error: ${res.error}');
    print('errorCode: ${res.errorCode}'); // can be used to handle specific busines error such as ERROR_INVLAID_INPUT_DUP_REF
  }

  // update existing bill if it is not paid
  bill.amount = '278.00';
  bill.customerName = 'Elias dart';
  //bill.billReference = "WE CAN NOT CHANGE THIS";

  print('Updating Bill...');
  res = await api.updateBill(bill);

  if (res.error == null) {
    // success
    print('bill is updated succesfully'); //res.res will be 'OK'  no need to check here!
  } else {
    // fail
    print('error: ${res.error}');
    print('errorCode: ${res.errorCode}'); // can be used to handle specific busines error such as ERROR_INVLAID_INPUT
  }

  api.close();
}
```

### Getting a Bill and Listing Bills

```dart
import 'dart:io';

import 'package:webirr/webirr.dart';

void main() async {
  final apikey = Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? 'YOUR_API_KEY';
  final merchantId =
      Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ?? 'YOUR_MERCHANT_ID';

  final api = WeBirrClient(merchantId: merchantId, apikey: apikey, isTestEnv: true);

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
  const lastTimeStamp = '20251231'; // Date-only cursor; use "20251231235959" when you need time precision.
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
```

### Getting Supported Banks for Checkout

```dart
import 'dart:io';

import 'package:webirr/webirr.dart';

void main() async {
  final apikey = Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? 'YOUR_API_KEY';
  final merchantId =
      Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ?? 'YOUR_MERCHANT_ID';

  final api = WeBirrClient(merchantId: merchantId, apikey: apikey, isTestEnv: true);

  print('Getting supported banks...');
  final response = await api.getSupportedBanks();

  if (response.error == null) {
    for (final bank in response.res ?? <SupportedBank>[]) {
      print('${bank.bankID} - ${bank.name}');
    }
    print('Use only these merchant-specific banks when showing checkout payment instructions.');
  } else {
    print('error: ${response.error}');
    print('errorCode: ${response.errorCode}');
  }

  api.close();
}
```

Checkout pages should render bank-specific instructions only from `getSupportedBanks()`. Do not show a broad static bank list unless those banks are returned for the configured merchant.

### Getting Payment status of an existing Bill from WeBirr Servers

```dart
import 'dart:io';

import 'package:webirr/webirr.dart';

void main() async {
  final apikey = Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? 'YOUR_API_KEY';
  final merchantId =
      Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ?? 'YOUR_MERCHANT_ID';

  final api = WeBirrClient(merchantId: merchantId, apikey: apikey, isTestEnv: true);

  const paymentCode = 'PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL'; // suchas as '141 263 782';

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
    print('errorCode: ${r.errorCode}'); // can be used to handle specific busines error such as ERROR_INVLAID_INPUT
  }

  api.close();
}
```

*Sample object returned from getPaymentStatus()*

```json
{
  "status": 2,
  "data": {
    "id": 1,
    "status": 2,
    "bankID": "cbe_birr",
    "paymentReference": "BANK-REF-1",
    "paymentDate": "2025-01-01 10:00:00",
    "confirmed": true,
    "confirmedTime": "2025-01-01 10:00:01",
    "amount": "270.90",
    "wbcCode": "429 723 975",
    "updateTimeStamp": "20250101100001000001"
  }
}
```

### Deleting an existing Bill from WeBirr Servers (if it is not paid)

```dart
import 'dart:io';

import 'package:webirr/webirr.dart';

void main() async {
  final apikey = Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? 'YOUR_API_KEY';
  final merchantId =
      Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ?? 'YOUR_MERCHANT_ID';

  final api = WeBirrClient(merchantId: merchantId, apikey: apikey, isTestEnv: true);

  const paymentCode = 'PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL'; // suchas as '141 263 782';

  print('Deleting Bill...');
  final res = await api.deleteBill(paymentCode);

  if (res.error == null) {
    // success
    print('bill is deleted succesfully'); //res.res will be 'OK'  no need to check here!
  } else {
    // fail
    print('error: ${res.error}');
    print('errorCode: ${res.errorCode}'); // can be used to handle specific bussines error such as ERROR_INVLAID_INPUT
  }

  api.close();
}
```

### Getting list of Payments and process them with Bulk Polling Consumer

```dart
import 'dart:io';

import 'package:webirr/webirr.dart';

class BulkPaymentPollingConsumer {
  BulkPaymentPollingConsumer() {
    final apikey = Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? 'YOUR_API_KEY';
    final merchantId =
        Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ?? 'YOUR_MERCHANT_ID';

    api = WeBirrClient(merchantId: merchantId, apikey: apikey, isTestEnv: true);
  }

  late final WeBirrClient api;
  var lastTimeStamp = '20251231'; // use a saved cursor; time precision can be like "20251231235959"

  Future<void> run() async {
    await fetchAndProcessPayments();
    api.close();
  }

  Future<void> fetchAndProcessPayments() async {
    const limit = 100;

    print('Getting Payments...');
    final response =
        await api.getPayments(lastTimeStamp: lastTimeStamp, limit: limit);

    if (response.error == null) {
      // success
      for (final payment in response.res ?? <PaymentResponse>[]) {
        processPayment(payment);
        if (payment.updateTimeStamp.isNotEmpty) {
          lastTimeStamp = payment.updateTimeStamp;
          print('Last Timestamp: $lastTimeStamp'); // save updateTimeStamp to your database for the next getPayments() call
        }
      }
    } else {
      // fail
      print('error: ${response.error}');
      print('errorCode: ${response.errorCode}');
    }
  }

  void processPayment(PaymentResponse payment) {
    if (payment.isPaid) {
      print('bill is paid');
    } else if (payment.isReversed) {
      print('bill payment is reversed');
    }

    print('Bank: ${payment.bankID}');
    print('Bank Reference Number: ${payment.paymentReference}');
    print('Amount Paid: ${payment.amount}');
    print('Payment Date: ${payment.paymentDate}');
    print('Canceled Time: ${payment.canceledTime}');
    print('Update Timestamp: ${payment.updateTimeStamp}');
  }
}

void main() async {
  await BulkPaymentPollingConsumer().run();
}
```

### Webhooks - Payment processing using Webhook Callbacks

```dart
import 'dart:convert';
import 'dart:io';

import 'package:webirr/webirr.dart';

void main() async {
  final expectedAuthKey =
      Platform.environment['WEBIRR_WEBHOOK_AUTH_KEY'] ?? 'YOUR_WEBHOOK_AUTH_KEY';

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 3000);
  print('Webhook listening on port ${server.port}');

  await for (final request in server) {
    final authKey = request.uri.queryParameters['authKey'];

    if (request.method != 'POST') {
      jsonResponse(request.response, HttpStatus.methodNotAllowed,
          <String, dynamic>{'error': 'method not allowed'});
      continue;
    }

    if (authKey != expectedAuthKey) {
      jsonResponse(request.response, HttpStatus.unauthorized,
          <String, dynamic>{'error': 'unauthorized'});
      continue;
    }

    final body = await utf8.decoder.bind(request).join();
    if (body.isEmpty) {
      jsonResponse(request.response, HttpStatus.badRequest,
          <String, dynamic>{'error': 'empty request body'});
      continue;
    }

    try {
      final payment =
          PaymentResponse.fromJson(jsonDecode(body) as Map<String, dynamic>);
      processPayment(payment);
      jsonResponse(request.response, HttpStatus.ok, <String, dynamic>{'error': null});
    } catch (_) {
      jsonResponse(request.response, HttpStatus.badRequest,
          <String, dynamic>{'error': 'invalid json'});
    }
  }
}

void processPayment(PaymentResponse payment) {
  if (payment.isPaid) {
    print('bill is paid');
  } else if (payment.isReversed) {
    print('bill payment is reversed');
  }

  print('Bank: ${payment.bankID}');
  print('Bank Reference Number: ${payment.paymentReference}');
  print('Amount Paid: ${payment.amount}');
  print('Payment Date: ${payment.paymentDate}');
  print('Canceled Time: ${payment.canceledTime}');
  print('Update Timestamp: ${payment.updateTimeStamp}');
}

void jsonResponse(
  HttpResponse response,
  int statusCode,
  Map<String, dynamic> body,
) {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  response.close();
}
```

Host webhook handlers on HTTPS, validate the `authKey`, make payment processing idempotent, and enqueue longer work to a background process.

### Gettting basic Statistics about bills created and payments received for a date range

```dart
import 'dart:io';

import 'package:webirr/webirr.dart';

void main() async {
  final apikey = Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? 'YOUR_API_KEY';
  final merchantId =
      Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ?? 'YOUR_MERCHANT_ID';

  final api = WeBirrClient(merchantId: merchantId, apikey: apikey, isTestEnv: true);

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
```

## Standalone Examples

The `example/lib` directory has runnable examples equivalent to the README sections:

| File | Coverage |
| --- | --- |
| `example.dart` | Create bill, save payment code, update same bill. |
| `example2.dart` | Single payment status by saved payment code. |
| `example3.dart` | Delete unpaid bill by payment code. |
| `example4.dart` | Poll payments with `lastTimeStamp`, process each payment, save `updateTimeStamp`. |
| `example5.dart` | Merchant stats by date range. |
| `example6.dart` | Webhook callback handler/sink. |
| `example7.dart` | Get bill by reference, get bill by payment code, list bills. |
| `example8.dart` | Get banks enabled for the configured merchant checkout. |

Run examples from the package root:

```bash
WEBIRR_TEST_ENV_MERCHANT_ID="YOUR_MERCHANT_ID" \
WEBIRR_TEST_ENV_API_KEY="YOUR_API_KEY" \
dart run example/lib/example.dart
```

## Tests

Fast tests use a mock HTTP client:

```bash
dart test test/webirr_test.dart
```

Live TestEnv smoke tests call the running gateway and require TestEnv credentials:

```bash
export WEBIRR_TEST_ENV_MERCHANT_ID="YOUR_MERCHANT_ID"
export WEBIRR_TEST_ENV_API_KEY="YOUR_API_KEY"
dart test test/webirr_testenv_test.dart
```

## Backward Compatibility

The older constructor style remains available for 1.x compatibility:

```dart
final api = WeBirrClient(apikey: apikey, isTestEnv: true);
```

When merchant ID is not configured, the client does not send an empty `merchant_id` query parameter and does not overwrite `Bill.merchantID`.
