import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Only these curated, localized messages may be displayed to the user.
/// Exception messages, response bodies, URLs and stack traces stay out of UI.
String deviceErrorMessage(Object? error, AppLocalizations l10n) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return l10n.deviceRequestTimeout;
      case DioExceptionType.connectionError:
        return l10n.deviceConnectionError;
      case DioExceptionType.badCertificate:
        return l10n.deviceCertificateError;
      case DioExceptionType.cancel:
        return l10n.deviceRequestCancelled;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) return l10n.tokenRejected;
        if (status == 404) {
          return error.requestOptions.extra['authAttempted'] == true
              ? l10n.tokenRejected
              : l10n.deviceFeatureUnavailable;
        }
        if (status != null && status >= 500) return l10n.deviceServiceError;
        return l10n.deviceRequestRejected;
      case DioExceptionType.unknown:
        if (error.error is SocketException || error.error is HttpException) {
          return l10n.deviceConnectionError;
        }
        if (error.error is FormatException || error.error is TypeError) {
          return l10n.deviceInvalidResponse;
        }
        return l10n.deviceOperationFailed;
    }
  }
  if (error is SocketException || error is HttpException) {
    return l10n.deviceConnectionError;
  }
  if (error is TimeoutException) return l10n.deviceRequestTimeout;
  if (error is FormatException || error is TypeError) {
    return l10n.deviceInvalidResponse;
  }
  if (error is PlatformException && error.code == 'permission_denied') {
    return l10n.wifiPermissionRequired;
  }
  return l10n.deviceOperationFailed;
}

/// Handles feedback only while the requesting screen remains mounted.
extension DeviceErrorFeedback on State {
  void showDeviceError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(deviceErrorMessage(error, AppLocalizations.of(context))),
      ),
    );
  }
}
