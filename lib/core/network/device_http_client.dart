import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Thin wrapper around [Dio] for talking to myStrom devices on port 80.
///
/// Adds optional `Token` auth. Note: we do NOT send an `Origin` header —
/// myStrom firmware rejects requests with Origin/Referer with 404.
class DeviceHttpClient {
  DeviceHttpClient({this._token, Duration? timeout})
    : _timeout = timeout ?? AppConfig.httpTimeout,
      _dio = Dio(
        BaseOptions(
          connectTimeout: timeout ?? AppConfig.httpTimeout,
          receiveTimeout: timeout ?? AppConfig.httpTimeout,
          responseType: ResponseType.json,
        ),
      ) {
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: _createHttpClient,
    );
  }

  final String? _token;
  final Dio _dio;
  final Duration _timeout;
  HttpClient? _httpClient;

  Dio get dio => _dio;

  HttpClient _createHttpClient() {
    _httpClient ??= HttpClient()
      ..idleTimeout = const Duration(seconds: 30)
      ..maxConnectionsPerHost = 1
      ..connectionTimeout = _timeout;
    return _httpClient!;
  }

  void _resetHttpClient() {
    _httpClient?.close(force: true);
    _httpClient = null;
  }

  String _base(String ip) => 'http://$ip';

  Map<String, dynamic> _auth() {
    final headers = <String, dynamic>{'Connection': 'keep-alive'};
    if (_token != null) headers['Token'] = _token;
    return headers;
  }

  Future<Response<T>> get<T>(
    String ip,
    String path, {
    Map<String, dynamic>? query,
    ResponseType? responseType,
  }) {
    final url = '${_base(ip)}$path';
    debugPrint('[HTTP] GET $url query=$query');
    return _executeWithRetry<T>(() {
      return _dio.get<T>(
        url,
        queryParameters: query,
        options: Options(responseType: responseType, headers: _auth()),
      );
    });
  }

  Future<Response<T>> post<T>(
    String ip,
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    ResponseType? responseType,
    String? contentType,
  }) {
    final url = '${_base(ip)}$path';
    debugPrint('[HTTP] POST $url body=$body query=$query');
    return _executeWithRetry<T>(() {
      return _dio.post<T>(
        url,
        data: body,
        queryParameters: query,
        options: Options(
          responseType: responseType,
          headers: _auth(),
          contentType: contentType,
        ),
      );
    });
  }

  /// Send a URL-encoded form body (used by strip/dimmer/bulb).
  Future<Response<dynamic>> postForm(
    String ip,
    String path,
    Map<String, dynamic> fields,
  ) {
    final url = '${_base(ip)}$path';
    debugPrint('[HTTP] POST_FORM $url body=$fields');
    return _executeWithRetry<dynamic>(() {
      return _dio.post(
        url,
        data: fields,
        options: Options(
          headers: _auth(),
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
    });
  }

  /// Send a raw form-encoded string body (used when values contain
  /// characters like semicolons that must NOT be URL-encoded).
  ///
  /// [body] should already be in `key=value&key=value` format.
  Future<Response<dynamic>> postRawForm(String ip, String path, String body) {
    final url = '${_base(ip)}$path';
    debugPrint('[HTTP] POST_RAW_FORM $url body=$body');
    return _executeWithRetry<dynamic>(() {
      return _dio.post(
        url,
        data: body,
        options: Options(
          headers: _auth(),
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
    });
  }

  /// Send a raw text body (used by button-se action URLs).
  Future<Response<dynamic>> postRawText(String ip, String path, String text) {
    final url = '${_base(ip)}$path';
    debugPrint('[HTTP] POST_RAW_TEXT $url body=$text');
    return _executeWithRetry<dynamic>(() {
      return _dio.post(
        url,
        data: text,
        options: Options(headers: _auth(), contentType: 'text/plain'),
      );
    });
  }

  /// POST with a raw, already-formatted query string appended to the path.
  ///
  /// Use this when query values contain characters that must NOT be
  /// URL-encoded, e.g. the bulb timer `color=120;100;100` (semicolons).
  /// [rawQuery] should NOT include the leading `?`.
  Future<Response<dynamic>> postRawQuery(
    String ip,
    String path,
    String rawQuery,
  ) {
    final url = '${_base(ip)}$path?$rawQuery';
    debugPrint('[HTTP] POST_RAW_QUERY $url');
    return _executeWithRetry<dynamic>(() {
      return _dio.post(url, options: Options(headers: _auth()));
    });
  }

  Future<Response<T>> _executeWithRetry<T>(
    Future<Response<T>> Function() action,
  ) async {
    try {
      final res = await action();
      debugPrint('[HTTP] ← ${res.statusCode}');
      return res;
    } on DioException catch (e) {
      if (_shouldResetForClosedConnection(e)) {
        debugPrint('[HTTP] Connection reset, retrying...');
        _resetHttpClient();
        final res = await action();
        debugPrint('[HTTP] ← ${res.statusCode} (after retry)');
        return res;
      }
      debugPrint('[HTTP] ← ERROR ${e.type} ${e.message}');
      rethrow;
    } on SocketException catch (e) {
      // HttpClient.connectionTimeout surfaces as a raw SocketException
      // ("HTTP connection timed out after ..."). It can escape Dio on
      // some platforms when the connect timeout fires first, and it would
      // otherwise become an Unhandled Exception. Wrap it as a DioException
      // so callers only ever see a single exception type.
      debugPrint('[HTTP] ← ERROR socket ${e.message}');
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
        error: e,
        message: e.message,
      );
    } on HttpException catch (e) {
      debugPrint('[HTTP] ← ERROR http ${e.message}');
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
        error: e,
        message: e.message,
      );
    }
  }

  bool _shouldResetForClosedConnection(DioException e) {
    final error = e.error;
    if (error is HttpException) {
      final message = error.message.toLowerCase();
      return message.contains('closed before full header') ||
          message.contains('connection closed') ||
          message.contains('connection reset');
    }
    if (error is SocketException) {
      final message = error.message.toLowerCase();
      return message.contains('connection closed') ||
          message.contains('connection reset');
    }
    final message = e.message?.toLowerCase() ?? '';
    return message.contains('closed before full header') ||
        message.contains('connection closed') ||
        message.contains('connection reset');
  }

  void dispose() {
    _httpClient?.close(force: true);
    _httpClient = null;
    _dio.close();
  }
}
