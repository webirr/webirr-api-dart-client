import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_response.dart';
import 'bill.dart';
import 'payment.dart';
import 'stat.dart';
import 'supported_bank.dart';

/// A WeBirrClient instance object can be used to create, update or delete a
/// bill at WeBirr Servers, retrieve bill/payment information, and get basic
/// merchant statistics. It is a wrapper for the REST Web Service API.
class WeBirrClient {
  static const String _testBaseAddress = 'https://api.webirr.dev';
  static const String _prodBaseAddress = 'https://api.webirr.net:8080';
  static const String _gatewayUrlOverride =
      String.fromEnvironment('GATEWAY_URL');

  final String _baseAddress;
  final String _merchantId;
  final String _apiKey;
  final http.Client _client;
  final bool _ownsClient;

  WeBirrClient({
    String merchantId = '',
    required String apikey,
    required bool isTestEnv,
    http.Client? httpClient,
  })  : _merchantId = merchantId,
        _apiKey = apikey,
        _baseAddress = _resolveBaseAddress(isTestEnv),
        _client = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  static String _resolveBaseAddress(bool isTestEnv) {
    if (!isTestEnv) {
      return _prodBaseAddress;
    }

    final gatewayUrl = _gatewayUrlOverride.trim();
    if (gatewayUrl.isNotEmpty) {
      return gatewayUrl.replaceFirst(RegExp(r'/+$'), '');
    }

    return _testBaseAddress;
  }

  /// Close the default SDK-owned HTTP client.
  ///
  /// If you pass your own [httpClient], your application owns its lifecycle.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  /// Create a new bill at WeBirr Servers.
  /// Check if(ApiResponse.error == null) to see if there are errors.
  /// ApiResponse.res will have the value of the returned PaymentCode on success.
  Future<ApiResponse<String>> createBill(Bill bill) {
    return _send<String>(
      'POST',
      'einvoice/api/bill',
      body: _prepareBill(bill).toJson(),
      parse: _stringResult,
    );
  }

  /// Update an existing bill at WeBirr Servers, if the bill is not paid yet.
  /// The billReference has to be the same as the original bill created.
  /// Check if(ApiResponse.error == null) to see if there are errors.
  /// ApiResponse.res will have the value of "OK" on success.
  Future<ApiResponse<String>> updateBill(Bill bill) {
    return _send<String>(
      'PUT',
      'einvoice/api/bill',
      body: _prepareBill(bill).toJson(),
      parse: _stringResult,
    );
  }

  /// Delete an existing bill at WeBirr Servers, if the bill is not paid yet.
  /// [paymentCode] is the number that WeBirr Payment Gateway returns on createBill.
  /// Check if(ApiResponse.error == null) to see if there are errors.
  /// ApiResponse.res will have the value of "OK" on success.
  Future<ApiResponse<String>> deleteBill(String paymentCode) {
    return _send<String>(
      'DELETE',
      'einvoice/api/bill',
      query: <String, String>{'wbc_code': paymentCode},
      body: <String, dynamic>{},
      parse: _stringResult,
    );
  }

  /// Get Payment Status of a bill from WeBirr Servers.
  /// [paymentCode] is the number that WeBirr Payment Gateway returns on createBill.
  Future<ApiResponse<Payment>> getPaymentStatus(String paymentCode) {
    return _send<Payment>(
      'GET',
      'einvoice/api/paymentStatus',
      query: <String, String>{'wbc_code': paymentCode},
      parse: (value) => _mapResult(value, Payment.fromJson),
    );
  }

  /// Get one bill by the merchant bill reference.
  Future<ApiResponse<BillResponse>> getBillByReference(String billReference) {
    return _send<BillResponse>(
      'GET',
      'einvoice/api/bill',
      query: <String, String>{'bill_reference': billReference},
      parse: (value) => _mapResult(value, BillResponse.fromJson),
    );
  }

  /// Get one bill by WeBirr payment code / WBC code.
  Future<ApiResponse<BillResponse>> getBillByPaymentCode(String paymentCode) {
    return _send<BillResponse>(
      'GET',
      'einvoice/api/bill',
      query: <String, String>{'wbc_code': paymentCode},
      parse: (value) => _mapResult(value, BillResponse.fromJson),
    );
  }

  /// Get list of bills updated after the last processed timestamp.
  Future<ApiResponse<List<BillResponse>>> getBills({
    int paymentStatus = -1,
    String lastTimeStamp = '',
    int limit = 100,
  }) {
    return _send<List<BillResponse>>(
      'GET',
      'einvoice/api/bills',
      query: <String, String>{
        'payment_status': paymentStatus.toString(),
        'last_timestamp': lastTimeStamp,
        'limit': limit.toString(),
      },
      parse: (value) => _listResult(value, BillResponse.fromJson),
    );
  }

  /// Get list of Payments from WeBirr Servers received after the last processed
  /// timestamp for bulk polling.
  Future<ApiResponse<List<PaymentResponse>>> getPayments({
    String lastTimeStamp = '',
    int limit = 100,
  }) {
    return _send<List<PaymentResponse>>(
      'GET',
      'einvoice/api/payments',
      query: <String, String>{
        'last_timestamp': lastTimeStamp,
        'limit': limit.toString(),
      },
      parse: (value) => _listResult(value, PaymentResponse.fromJson),
    );
  }

  /// Retrieves basic statistics about bills created and payments received over
  /// a date range.
  Future<ApiResponse<Stat>> getStat(String dateFrom, String dateTo) {
    return _send<Stat>(
      'GET',
      'merchant/stat',
      query: <String, String>{
        'date_from': dateFrom,
        'date_to': dateTo,
      },
      parse: (value) => _mapResult(value, Stat.fromJson),
    );
  }

  /// Get banks enabled for this merchant checkout.
  Future<ApiResponse<List<SupportedBank>>> getSupportedBanks() {
    return _send<List<SupportedBank>>(
      'GET',
      'einvoice/api/banks',
      parse: (value) => _listResult(value, SupportedBank.fromJson),
    );
  }

  Bill _prepareBill(Bill bill) {
    if (_merchantId.isNotEmpty) {
      bill.merchantID = _merchantId;
    }
    return bill;
  }

  Future<ApiResponse<T>> _send<T>(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required T? Function(dynamic value) parse,
  }) async {
    final request = http.Request(method, _buildUri(path, query));
    request.headers['Accept'] = 'application/json';
    request.headers['Content-Type'] = 'application/json';

    if (body != null) {
      request.body = jsonEncode(body);
    }

    try {
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      return _decodeResponse<T>(response, parse);
    } catch (error) {
      return ApiResponse<T>(error: error.toString());
    }
  }

  Uri _buildUri(String path, Map<String, String>? query) {
    final params = <String, String>{'api_key': _apiKey};
    if (_merchantId.isNotEmpty) {
      params['merchant_id'] = _merchantId;
    }
    if (query != null) {
      params.addAll(query);
    }

    return Uri.parse('$_baseAddress/$path').replace(queryParameters: params);
  }

  ApiResponse<T> _decodeResponse<T>(
    http.Response response,
    T? Function(dynamic value) parse,
  ) {
    if (response.statusCode != 200) {
      return ApiResponse<T>(
        error: 'http error ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return ApiResponse<T>(
      error: map['error']?.toString(),
      errorCode: map['errorCode']?.toString(),
      res: map['res'] != null ? parse(map['res']) : null,
    );
  }
}

String? _stringResult(dynamic value) => value?.toString();

T? _mapResult<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) {
  if (value == null) return null;
  return fromJson(Map<String, dynamic>.from(value as Map));
}

List<T> _listResult<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List) return <T>[];
  return value
      .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
}
