import "dart:async";
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

import 'bill.dart';
import 'payment.dart';
import 'api_response.dart';

/// A WeBirrClient instance object can be used to
/// Create, Update or Delete a Bill at WeBirr Servers and also to
/// Get the Payment Status of a bill.
/// It is a wrapper for the REST Web Service API.
class WeBirrClient {
  late String _baseAddress;
  late String _apiKey;

  WeBirrClient({required String apikey, required bool isTestEnv}) {
    _apiKey = apikey;
    _baseAddress =
        isTestEnv ? 'https://api.webirr.com' : 'https://api.webirr.com:8080';
  }

  /// Create a new bill at WeBirr Servers.
  /// Check if(ApiResponse.error == null) to see if there are errors.
  /// ApiResponse.res will have the value of the returned PaymentCode on success.
  Future<ApiResponse<String>> createBill(Bill bill) async {
    var client = RetryClient(http.Client());
    try {
      var resp = await client.post(
          Uri.parse('${_baseAddress}/einvoice/api/postbill?api_key=${_apiKey}'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(bill.toJson()));

      if (resp.statusCode == 200) {
        var map = jsonDecode(resp.body) as Map<String, dynamic>;
        return ApiResponse<String>(
            error: map['error'], errorCode: map['errorCode'], res: map['res']);
      } else {
        return new ApiResponse<String>(
            error: 'http error ${resp.statusCode} ${resp.reasonPhrase}');
      }
    } finally {
      client.close();
    }
  }

  /// Update an existing bill at WeBirr Servers, if the bill is not paid yet.
  /// The billReference has to be the same as the original bill created.
  /// Check if(ApiResponse.error == null) to see if there are errors.
  /// ApiResponse.res will have the value of "OK" on success.
  Future<ApiResponse<String>> updateBill(Bill bill) async {
    var client = RetryClient(http.Client());
    try {
      var resp = await client.put(
          Uri.parse('${_baseAddress}/einvoice/api/postbill?api_key=${_apiKey}'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(bill.toJson()));

      if (resp.statusCode == 200) {
        var map = jsonDecode(resp.body) as Map<String, dynamic>;
        return ApiResponse<String>(
            error: map['error'], errorCode: map['errorCode'], res: map['res']);
      } else {
        return new ApiResponse<String>(
            error: 'http error ${resp.statusCode} ${resp.reasonPhrase}');
      }
    } finally {
      client.close();
    }
  }

  /// Delete an existing bill at WeBirr Servers, if the bill is not paid yet.
  /// [paymentCode] is the number that WeBirr Payment Gateway returns on createBill.
  /// Check if(ApiResponse.error == null) to see if there are errors.
  /// ApiResponse.res will have the value of "OK" on success.
  Future<ApiResponse<String>> deleteBill(String paymentCode) async {
    var client = RetryClient(http.Client());
    try {
      var resp = await client.put(Uri.parse(
          '${_baseAddress}/einvoice/api/deletebill?api_key=${_apiKey}&wbc_code=$paymentCode'));

      if (resp.statusCode == 200) {
        var map = jsonDecode(resp.body) as Map<String, dynamic>;
        return ApiResponse<String>(
            error: map['error'], errorCode: map['errorCode'], res: map['res']);
      } else {
        return new ApiResponse<String>(
            error: 'http error ${resp.statusCode} ${resp.reasonPhrase}');
      }
    } finally {
      client.close();
    }
  }

  /// Get Payment Status of a bill from WeBirr Servers
  /// [paymentCode] is the number that WeBirr Payment Gateway returns on createBill.
  /// Check if(ApiResponse.error == null) to see if there are errors.
  /// ApiResponse.res will have `Payment` object on success (will be null otherwise!)
  /// ApiResponse.res?.isPaid ?? false -> will return true if the bill is paid (payment completed)
  /// ApiResponse.res?.data ?? null -> will have `PaymentDetail` object
  Future<ApiResponse<Payment>> getPaymentStatus(String paymentCode) async {
    var client = RetryClient(http.Client());
    try {
      var resp = await client.get(Uri.parse(
          '${_baseAddress}/einvoice/api/getPaymentStatus?api_key=${_apiKey}&wbc_code=$paymentCode'));
      if (resp.statusCode == 200) {
        var map = jsonDecode(resp.body) as Map<String, dynamic>;
        return ApiResponse<Payment>(
            error: map['error'],
            errorCode: map['errorCode'],
            res: map['res'] != null ? Payment.fromJson(map['res']) : null);
      } else {
        return new ApiResponse<Payment>(
            error: 'http error ${resp.statusCode} ${resp.reasonPhrase}');
      }
    } finally {
      client.close();
    }
  }
}
