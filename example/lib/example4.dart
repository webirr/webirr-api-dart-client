import 'dart:io';

import 'package:webirr/webirr.dart';

/// Getting list of Payments and process them with Bulk Polling Consumer
class BulkPaymentPollingConsumer {
  BulkPaymentPollingConsumer() {
    final apiKey =
        Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? 'YOUR_API_KEY';
    final merchantId = Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ??
        'YOUR_MERCHANT_ID';

    api = WeBirrClient(merchantId: merchantId, apikey: apiKey, isTestEnv: true);
  }

  late final WeBirrClient api;
  var lastTimeStamp =
      '20251231'; // use a saved cursor; time precision can be like "20251231235959"

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
          print(
              'Last Timestamp: $lastTimeStamp'); // save updateTimeStamp to your database for the next getPayments() call
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
