import 'dart:math';
import 'dart:io';

import 'package:test/test.dart';
import 'package:webirr/webirr.dart';

void main() {
  final envMerchantId =
      Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ?? '';
  final envApiKey = Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? '';
  final missingCredentials = envMerchantId.isEmpty || envApiKey.isEmpty;

  group(
    'TestEnv smoke tests',
    () {
      late final WeBirrClient api;
      final billReference =
          'drt/test/${DateTime.now().millisecondsSinceEpoch}/${Random().nextInt(100000)}';
      const exampleCursor = '20251231';
      var paymentCode = '';
      var updateTimeStamp = '';
      var billDeleted = false;

      setUpAll(() {
        api = WeBirrClient(
          merchantId: envMerchantId,
          apikey: envApiKey,
          isTestEnv: true,
        );
      });

      tearDownAll(() async {
        if (paymentCode.isNotEmpty && !billDeleted) {
          await api.deleteBill(paymentCode);
        }
        api.close();
      });

      test('createBill creates bill without manual merchant id', () async {
        final response = await api.createBill(sampleBill(billReference));
        assertNoApiError(response, 'createBill');

        paymentCode = response.res ?? '';
        expect(paymentCode, isNotEmpty);
        expect(normalizePaymentCode(paymentCode), matches(RegExp(r'^\d+$')));
      });

      test('updateBill updates created bill', () async {
        final bill = sampleBill(billReference)..amount = '278.00';

        final response = await api.updateBill(bill);
        assertNoApiError(response, 'updateBill');
        expect((response.res ?? '').toLowerCase(), 'ok');
      });

      test('getPaymentStatus returns pending for new bill', () async {
        final response = await api.getPaymentStatus(paymentCode);
        assertNoApiError(response, 'getPaymentStatus');

        expect(response.res, isNotNull);
        expect(response.res!.status, 0);
        expect(response.res!.data, isNull);
      });

      test('getBillByReference returns created bill', () async {
        final bill = await getCreatedBillByReference(api, billReference);
        assertCreatedBill(bill, billReference, envMerchantId, paymentCode);
        expect(double.parse(bill.amount), closeTo(278, 0.01));
        updateTimeStamp = bill.updateTimeStamp;
      });

      test('getBillByPaymentCode returns created bill', () async {
        final response = await api.getBillByPaymentCode(paymentCode);
        assertNoApiError(response, 'getBillByPaymentCode');
        assertCreatedBill(
          response.res!,
          billReference,
          envMerchantId,
          paymentCode,
        );
      });

      test('getBills finds created bill', () async {
        if (updateTimeStamp.isEmpty) {
          final bill = await getCreatedBillByReference(api, billReference);
          updateTimeStamp = bill.updateTimeStamp;
        }

        final response = await api.getBills(
          paymentStatus: 0,
          lastTimeStamp: cursorBefore(updateTimeStamp, exampleCursor),
          limit: 100,
        );
        assertNoApiError(response, 'getBills');
        expect(response.res, isNotNull);

        final found = response.res!.firstWhere(
          (bill) =>
              bill.billReference.toLowerCase() == billReference.toLowerCase(),
        );
        assertCreatedBill(found, billReference, envMerchantId, paymentCode);
      });

      test('getPayments returns payment array', () async {
        final response =
            await api.getPayments(lastTimeStamp: exampleCursor, limit: 10);
        assertNoApiError(response, 'getPayments');
        expect(response.res, isA<List<PaymentResponse>>());
      });

      test('getStat returns stat object', () async {
        final response = await api.getStat('2025-01-01', '2030-01-31');
        assertNoApiError(response, 'getStat');
        expect(response.res, isNotNull);
      });

      test('deleteBill removes created bill', () async {
        final response = await api.deleteBill(paymentCode);
        assertNoApiError(response, 'deleteBill');
        expect((response.res ?? '').toLowerCase(), 'ok');
        billDeleted = true;

        final deletedBill = await api.getBillByReference(billReference);
        expect(deletedBill.error, isNotNull);
      });
    },
    skip: missingCredentials
        ? 'WEBIRR_TEST_ENV_MERCHANT_ID and WEBIRR_TEST_ENV_API_KEY are required'
        : false,
  );
}

Bill sampleBill(String billReference) => Bill(
      amount: '270.90',
      customerCode: 'cc01',
      customerName: 'Elias Haileselassie',
      customerPhone: '0911000000',
      time: '2021-07-22 22:14',
      description: 'hotel booking',
      billReference: billReference,
      extras: <String, dynamic>{},
    );

Future<BillResponse> getCreatedBillByReference(
  WeBirrClient api,
  String billReference,
) async {
  final response = await api.getBillByReference(billReference);
  assertNoApiError(response, 'getBillByReference');
  return response.res!;
}

void assertNoApiError(ApiResponse<dynamic> response, String operation) {
  if (response.error != null) {
    throw StateError(
        '$operation failed: ${response.error} ${response.errorCode ?? ''}');
  }
}

void assertCreatedBill(
  BillResponse bill,
  String billReference,
  String merchantId,
  String paymentCode,
) {
  expect(bill.billReference.toLowerCase(), billReference.toLowerCase());
  expect(bill.customerCode.toLowerCase(), 'cc01');
  expect(bill.customerName, 'Elias Haileselassie');
  expect(bill.customerPhone, '0911000000');
  expect(bill.description, 'hotel booking');
  expect(bill.merchantID, merchantId);
  expect(normalizePaymentCode(bill.wbcCode), normalizePaymentCode(paymentCode));
  expect(bill.updateTimeStamp, isNotEmpty);
}

String normalizePaymentCode(String value) =>
    value.replaceAll(RegExp(r'\s+'), '');

String cursorBefore(String updateTimeStamp, String fallback) {
  if (updateTimeStamp.isEmpty || !RegExp(r'^\d+$').hasMatch(updateTimeStamp)) {
    return fallback;
  }

  final parsed = BigInt.parse(updateTimeStamp);
  final previous = parsed > BigInt.zero ? parsed - BigInt.one : parsed;
  return previous.toString().padLeft(updateTimeStamp.length, '0');
}
