import 'dart:convert';
import 'dart:io';

import 'package:webirr/webirr.dart';

/// Webhooks - Payment processing using Webhook Callbacks
void main() async {
  final expectedAuthKey = Platform.environment['WEBIRR_WEBHOOK_AUTH_KEY'] ??
      'YOUR_WEBHOOK_AUTH_KEY';

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
      jsonResponse(
          request.response, HttpStatus.ok, <String, dynamic>{'error': null});
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
