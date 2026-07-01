import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:webirr/webirr.dart';

const exampleCursor = '20251231';

void main() {
  test('preferred constructor sets bill merchant id before sending', () async {
    final captured = <http.Request>[];
    final api = testClient(captured);
    final bill = sampleBill()..merchantID = 'merchant-on-bill';

    await api.createBill(bill);

    expect(
        jsonDecode(captured.single.body)['merchantID'], 'merchant-from-client');
  });

  test('empty merchant id overwrites existing bill merchant id', () async {
    final captured = <http.Request>[];
    final api = emptyMerchantTestClient(captured);
    final bill = sampleBill()..merchantID = 'merchant-on-bill';

    await api.createBill(bill);

    expect(jsonDecode(captured.single.body)['merchantID'], '');
  });

  test('constructor can use injected http client for requests', () async {
    final captured = <http.Request>[];
    final api = testClient(captured);

    final response = await api.deleteBill('123 456 789');

    expect(response.res, 'OK');
    expect(captured.single.url.queryParameters['merchant_id'],
        'merchant-from-client');
  });

  test('test env defaults to api.webirr.dev', () async {
    final captured = <http.Request>[];
    final api = testClient(captured);

    await api.deleteBill('123 456 789');

    expect(captured.single.url.scheme, 'https');
    expect(captured.single.url.host, 'api.webirr.dev');
    expect(captured.single.url.hasPort, false);
  });

  test('production env uses fixed production gateway', () async {
    final captured = <http.Request>[];
    final api = WeBirrClient(
      merchantId: 'merchant-from-client',
      apikey: 'api-key',
      isTestEnv: false,
      httpClient: mockClient(captured),
    );

    await api.deleteBill('123 456 789');

    expect(captured.single.url.scheme, 'https');
    expect(captured.single.url.host, 'api.webirr.net');
    expect(captured.single.url.port, 8080);
  });

  for (final endpoint in endpointCalls) {
    test('${endpoint.name} includes merchant_id when configured', () async {
      final captured = <http.Request>[];
      final api = testClient(captured, businessErrorResponse());

      await endpoint.call(api);

      final request = captured.single;
      expect(request.method, endpoint.method);
      expect(request.url.path, '/${endpoint.path}');
      expect(request.headers['Accept'], 'application/json');
      expect(request.headers['Content-Type'], 'application/json');
      expect(request.url.queryParameters['api_key'], 'api-key');
      expect(
          request.url.queryParameters['merchant_id'], 'merchant-from-client');
      endpoint.expectedQuery.forEach((key, value) {
        expect(request.url.queryParameters[key], value);
      });
    });

    test(
        '${endpoint.name} includes empty merchant_id when client merchant id is empty',
        () async {
      final captured = <http.Request>[];
      final api = emptyMerchantTestClient(captured, businessErrorResponse());

      await endpoint.call(api);

      expect(
          captured.single.url.queryParameters.containsKey('merchant_id'), true);
      expect(captured.single.url.queryParameters['merchant_id'], '');
    });
  }

  test('bill defaults customerPhone and extras before sending', () async {
    final bill = Bill(
      amount: '270.90',
      customerCode: 'cc01',
      customerName: 'Elias Haileselassie',
      time: '2021-07-22 22:14',
      description: 'hotel booking',
      billReference: 'drt/2021/125',
    );

    expect(bill.toJson()['customerPhone'], '');
    expect(bill.toJson()['extras'], <String, dynamic>{});
  });

  test('bill keeps populated extras as an object before sending', () {
    final bill = sampleBill()
      ..extras = <String, dynamic>{'invoiceNo': 'INV-001', 'branch': 'main'};

    expect(bill.toJson()['extras'],
        <String, dynamic>{'invoiceNo': 'INV-001', 'branch': 'main'});
  });

  test('paymentDate is preferred while legacy time alias remains available',
      () {
    final detail = PaymentDetail.fromJson(<String, dynamic>{
      'paymentDate': '2025-01-01 10:00:00',
      'time': '2025-01-01 10:00:00',
    });

    expect(detail.paymentDate, '2025-01-01 10:00:00');
    expect(detail.time, detail.paymentDate);
  });

  test('response DTOs deserialize bill, payment, bulk payment, and stats',
      () async {
    final billApi = testClient(
      <http.Request>[],
      jsonResponse(<String, dynamic>{'res': billResponseJson()}),
    );
    final bill = (await billApi.getBillByReference('drt/unit/1')).res!;
    expect(bill.wbcCode, '123 456 789');
    expect(bill.paymentStatus, 0);
    expect(bill.customerPhone, '0911000000');

    final paymentApi = testClient(
      <http.Request>[],
      jsonResponse(<String, dynamic>{'res': paymentStatusJson()}),
    );
    final payment = (await paymentApi.getPaymentStatus('123 456 789')).res!;
    expect(payment.isPaid, true);
    expect(payment.data!.paymentDate, '2025-01-01 10:00:00');

    final paymentsApi = testClient(
      <http.Request>[],
      jsonResponse(<String, dynamic>{
        'res': <Map<String, dynamic>>[paymentResponseJson()]
      }),
    );
    final payments =
        (await paymentsApi.getPayments(lastTimeStamp: exampleCursor, limit: 10))
            .res!;
    expect(payments.single.isReversed, true);
    expect(payments.single.updateTimeStamp, '20250101100100000001');

    final statApi = testClient(
      <http.Request>[],
      jsonResponse(<String, dynamic>{
        'res': <String, dynamic>{
          'nBills': 2,
          'nBillsPaid': 1,
          'nBillsUnpaid': 1,
          'amountBills': '548.00',
          'amountPaid': '270.00',
          'amountUnpaid': '278.00',
        }
      }),
    );
    final stat = (await statApi.getStat('2025-01-01', '2030-01-31')).res!;
    expect(stat.nBills, 2);
    expect(stat.amountBills, 548);

    final banksApi = testClient(
      <http.Request>[],
      jsonResponse(<String, dynamic>{
        'res': <Map<String, dynamic>>[
          <String, dynamic>{
            'bankID': 'cbe_mobile',
            'name': 'CBE Mobile Banking'
          }
        ]
      }),
    );
    final banks = (await banksApi.getSupportedBanks()).res!;
    expect(banks.single.bankID, 'cbe_mobile');
    expect(banks.single.name, 'CBE Mobile Banking');
  });

  for (final endpoint in endpointCalls) {
    test('${endpoint.name} returns API error payload', () async {
      final captured = <http.Request>[];
      final api = testClient(
        captured,
        jsonResponse(<String, dynamic>{
          'error': 'invalid api key',
          'errorCode': 'ERROR_INVALID_API_KEY',
          'res': null,
        }),
      );

      final response = await endpoint.call(api);

      expect(response.error, 'invalid api key');
      expect(response.errorCode, 'ERROR_INVALID_API_KEY');
    });
  }

  test('transport error is not converted into ApiResponse', () async {
    final timeout = TimeoutException('request timed out');
    final api = WeBirrClient(
      merchantId: 'merchant-from-client',
      apikey: 'api-key',
      isTestEnv: true,
      httpClient: MockClient((request) async {
        throw timeout;
      }),
    );

    expect(api.deleteBill('123 456 789'), throwsA(same(timeout)));
  });

  test('non-2xx response throws typed HTTP exception', () async {
    final api = testClient(
      <http.Request>[],
      http.Response(
        'gateway unavailable',
        503,
        reasonPhrase: 'Service Unavailable',
      ),
    );

    await expectLater(
      api.getSupportedBanks(),
      throwsA(
        isA<WebirrHttpException>()
            .having((error) => error.statusCode, 'statusCode', 503)
            .having((error) => error.reasonPhrase, 'reasonPhrase',
                'Service Unavailable')
            .having((error) => error.body, 'body', 'gateway unavailable'),
      ),
    );
  });

  test('TransientErrors classifies retryable platform failures', () {
    expect(
      TransientErrors.isTransient(WebirrHttpException(
        statusCode: 503,
        reasonPhrase: 'Service Unavailable',
        body: '',
      )),
      isTrue,
    );
    expect(
      TransientErrors.isTransient(WebirrHttpException(
        statusCode: 429,
        reasonPhrase: 'Too Many Requests',
        body: '',
      )),
      isTrue,
    );
    expect(
      TransientErrors.isTransient(WebirrHttpException(
        statusCode: 408,
        reasonPhrase: 'Request Timeout',
        body: '',
      )),
      isTrue,
    );
    expect(
      TransientErrors.isTransient(WebirrHttpException(
        statusCode: 400,
        reasonPhrase: 'Bad Request',
        body: '',
      )),
      isFalse,
    );
    expect(TransientErrors.isTransient(TimeoutException('request timed out')),
        isTrue);
    expect(
        TransientErrors.isTransient(
            const SocketException('connection refused')),
        isTrue);
    expect(TransientErrors.isTransient(FormatException('bad json')), isFalse);
  });

  for (final invalid in <InvalidResponseCase>[
    InvalidResponseCase('empty body', http.Response('', 200)),
    InvalidResponseCase(
        'non-object body', http.Response('"not an object"', 200)),
    InvalidResponseCase('empty object body', jsonResponse(<String, dynamic>{})),
  ]) {
    test('invalid 2xx ApiResponse body throws: ${invalid.name}', () async {
      final api = testClient(<http.Request>[], invalid.response);

      expect(
        api.getStat('2025-01-01', '2030-01-31'),
        throwsA(isA<FormatException>()),
      );
    });
  }

  test('invalid 2xx result shape throws', () async {
    final api = testClient(
      <http.Request>[],
      jsonResponse(<String, dynamic>{'res': 'not a list'}),
    );

    expect(api.getSupportedBanks(), throwsA(isA<FormatException>()));
  });
}

WeBirrClient testClient(
  List<http.Request> captured, [
  http.Response? response,
]) {
  return WeBirrClient(
    merchantId: 'merchant-from-client',
    apikey: 'api-key',
    isTestEnv: true,
    httpClient: mockClient(captured, response),
  );
}

WeBirrClient emptyMerchantTestClient(
  List<http.Request> captured, [
  http.Response? response,
]) {
  return WeBirrClient(
    merchantId: '',
    apikey: 'api-key',
    isTestEnv: true,
    httpClient: mockClient(captured, response),
  );
}

MockClient mockClient(
  List<http.Request> captured, [
  http.Response? response,
]) {
  return MockClient((request) async {
    captured.add(request);
    return response ??
        jsonResponse(<String, dynamic>{
          'error': null,
          'errorCode': null,
          'res': 'OK',
        });
  });
}

http.Response jsonResponse(Map<String, dynamic> data) {
  return http.Response(
    jsonEncode(data),
    200,
    headers: <String, String>{'content-type': 'application/json'},
  );
}

http.Response businessErrorResponse() {
  return jsonResponse(<String, dynamic>{
    'error': 'invalid api key',
    'errorCode': 'ERROR_INVALID_API_KEY',
    'res': null,
  });
}

Bill sampleBill() => Bill(
      amount: '270.90',
      customerCode: 'cc01',
      customerName: 'Elias Haileselassie',
      customerPhone: '0911000000',
      time: '2021-07-22 22:14',
      description: 'hotel booking',
      billReference: 'drt/2021/125',
      merchantID: 'x',
      extras: <String, dynamic>{},
    );

Map<String, dynamic> billResponseJson() => <String, dynamic>{
      ...sampleBill().toJson(),
      'merchantID': 'merchant-from-client',
      'wbcCode': '123 456 789',
      'paymentStatus': 0,
      'updateTimeStamp': '20250101100000000001',
    };

Map<String, dynamic> paymentStatusJson() => <String, dynamic>{
      'status': 2,
      'data': <String, dynamic>{
        'id': 1,
        'status': 2,
        'bankID': 'cbe_birr',
        'paymentReference': 'BANK-REF-1',
        'paymentDate': '2025-01-01 10:00:00',
        'confirmed': true,
        'confirmedTime': '2025-01-01 10:00:01',
        'amount': '270.90',
        'wbcCode': '123 456 789',
        'updateTimeStamp': '20250101100001000001',
      },
    };

Map<String, dynamic> paymentResponseJson() => <String, dynamic>{
      'status': 3,
      'id': 2,
      'bankID': 'cbe_birr',
      'paymentReference': 'BANK-REF-2',
      'paymentDate': '2025-01-01 10:01:00',
      'confirmed': true,
      'confirmedTime': '2025-01-01 10:01:01',
      'canceled': true,
      'canceledTime': '2025-01-01 10:02:00',
      'amount': '270.90',
      'wbcCode': '123 456 789',
      'updateTimeStamp': '20250101100100000001',
    };

final endpointCalls = <EndpointCall>[
  EndpointCall(
    'createBill',
    'POST',
    'einvoice/api/bill',
    <String, String>{},
    (api) => api.createBill(sampleBill()),
  ),
  EndpointCall(
    'updateBill',
    'PUT',
    'einvoice/api/bill',
    <String, String>{},
    (api) => api.updateBill(sampleBill()),
  ),
  EndpointCall(
    'deleteBill',
    'DELETE',
    'einvoice/api/bill',
    <String, String>{'wbc_code': '123 456 789'},
    (api) => api.deleteBill('123 456 789'),
  ),
  EndpointCall(
    'getPaymentStatus',
    'GET',
    'einvoice/api/paymentStatus',
    <String, String>{'wbc_code': '123 456 789'},
    (api) => api.getPaymentStatus('123 456 789'),
  ),
  EndpointCall(
    'getBillByReference',
    'GET',
    'einvoice/api/bill',
    <String, String>{'bill_reference': 'drt/unit/1'},
    (api) => api.getBillByReference('drt/unit/1'),
  ),
  EndpointCall(
    'getBillByPaymentCode',
    'GET',
    'einvoice/api/bill',
    <String, String>{'wbc_code': '123 456 789'},
    (api) => api.getBillByPaymentCode('123 456 789'),
  ),
  EndpointCall(
    'getBills',
    'GET',
    'einvoice/api/bills',
    <String, String>{
      'payment_status': '-1',
      'last_timestamp': exampleCursor,
      'limit': '10',
    },
    (api) => api.getBills(
      paymentStatus: -1,
      lastTimeStamp: exampleCursor,
      limit: 10,
    ),
  ),
  EndpointCall(
    'getPayments',
    'GET',
    'einvoice/api/payments',
    <String, String>{'last_timestamp': exampleCursor, 'limit': '10'},
    (api) => api.getPayments(lastTimeStamp: exampleCursor, limit: 10),
  ),
  EndpointCall(
    'getStat',
    'GET',
    'merchant/stat',
    <String, String>{'date_from': '2025-01-01', 'date_to': '2030-01-31'},
    (api) => api.getStat('2025-01-01', '2030-01-31'),
  ),
  EndpointCall(
    'getSupportedBanks',
    'GET',
    'einvoice/api/banks',
    <String, String>{},
    (api) => api.getSupportedBanks(),
  ),
];

class EndpointCall {
  final String name;
  final String method;
  final String path;
  final Map<String, String> expectedQuery;
  final Future<ApiResponse<dynamic>> Function(WeBirrClient api) call;

  EndpointCall(
    this.name,
    this.method,
    this.path,
    this.expectedQuery,
    this.call,
  );
}

class InvalidResponseCase {
  final String name;
  final http.Response response;

  InvalidResponseCase(this.name, this.response);
}
