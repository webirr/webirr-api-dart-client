import 'dart:io';

import 'package:webirr/webirr.dart';

void main() async {
  final apikey =
      Platform.environment['WEBIRR_TEST_ENV_API_KEY'] ?? 'YOUR_API_KEY';
  final merchantId = Platform.environment['WEBIRR_TEST_ENV_MERCHANT_ID'] ??
      'YOUR_MERCHANT_ID';

  final api = WeBirrClient(
    merchantId: merchantId,
    apikey: apikey,
    isTestEnv: true,
  );

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
