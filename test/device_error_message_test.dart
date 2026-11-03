import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystrom_local/l10n/app_localizations_en.dart';
import 'package:mystrom_local/presentation/utils/device_error_message.dart';

void main() {
  final l10n = AppLocalizationsEn();
  const privateDetail = 'private-fixture-url-token-stacktrace';
  DioException dio(DioExceptionType type, {int? status, bool auth = false}) {
    final request = RequestOptions(
      path: privateDetail,
      headers: {'Token': privateDetail},
      extra: {'authAttempted': auth},
    );
    return DioException(
      requestOptions: request,
      type: type,
      message: privateDetail,
      response: status == null
          ? null
          : Response(
              requestOptions: request,
              statusCode: status,
              data: privateDetail,
            ),
    );
  }

  final cases = <(Object, String)>[
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.transformTimeout,
    ])
      (dio(type), l10n.deviceRequestTimeout),
    (dio(DioExceptionType.connectionError), l10n.deviceConnectionError),
    (dio(DioExceptionType.badCertificate), l10n.deviceCertificateError),
    (dio(DioExceptionType.cancel), l10n.deviceRequestCancelled),
    (dio(DioExceptionType.badResponse, status: 401), l10n.tokenRejected),
    (dio(DioExceptionType.badResponse, status: 403), l10n.tokenRejected),
    (
      dio(DioExceptionType.badResponse, status: 404, auth: true),
      l10n.tokenRejected,
    ),
    (
      dio(DioExceptionType.badResponse, status: 404),
      l10n.deviceFeatureUnavailable,
    ),
    (
      dio(DioExceptionType.badResponse, status: 400),
      l10n.deviceRequestRejected,
    ),
    (dio(DioExceptionType.badResponse, status: 503), l10n.deviceServiceError),
    (const SocketException(privateDetail), l10n.deviceConnectionError),
    (TimeoutException(privateDetail), l10n.deviceRequestTimeout),
    (const FormatException(privateDetail), l10n.deviceInvalidResponse),
    (StateError(privateDetail), l10n.deviceOperationFailed),
    (
      PlatformException(code: 'permission_denied', message: privateDetail),
      l10n.wifiPermissionRequired,
    ),
    (
      PlatformException(code: privateDetail, message: privateDetail),
      l10n.deviceOperationFailed,
    ),
  ];
  for (var i = 0; i < cases.length; i++) {
    test(
      'error category $i has concise localized feedback without raw details',
      () {
        final (error, expected) = cases[i];
        final message = deviceErrorMessage(error, l10n);
        expect(message, expected);
        expect(message, isNot(contains(privateDetail)));
        expect(message, isNot(contains('DioException')));
        expect(message.length, lessThan(160));
        expect(message, isNot(contains('\n')));
      },
    );
  }
}
