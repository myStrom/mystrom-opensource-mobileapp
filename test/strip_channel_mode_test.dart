import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystrom_local/core/network/device_http_client.dart';
import 'package:mystrom_local/data/datasources/device_remote_ds.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpServer server;
  late DeviceHttpClient client;
  late DeviceRemoteDataSource remote;
  late String host;
  late String responseBody;
  late String contentType;
  late int status;
  late Duration delay;
  final requests = <String>[];

  setUp(() async {
    HttpOverrides.global = null;
    responseBody = '{"ch_mode":"channels"}';
    contentType = 'text/plain; charset=utf-8';
    status = 200;
    delay = Duration.zero;
    requests.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    host = '127.0.0.1:${server.port}';
    server.listen((request) async {
      requests.add('${request.method} ${request.uri}');
      if (request.uri.path == '/api/v1/device') {
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            '020000000105': {
              'type': 'strip',
              'on': false,
              'color': 'FF00FF00',
              'mode': 'rgb',
              'ramp': 505,
            },
          }),
        );
      } else if (request.uri.path == '/api/v1/ch_mode') {
        await Future<void>.delayed(delay);
        request.response.statusCode = status;
        request.response.headers.set(
          HttpHeaders.contentTypeHeader,
          contentType,
        );
        request.response.write(responseBody);
      } else {
        request.response.statusCode = 404;
      }
      try {
        await request.response.close();
      } on HttpException {
        // The timeout test closes its client before the delayed response.
      }
    });
    client = DeviceHttpClient(
      timeout: const Duration(milliseconds: 200),
      authentication: false,
    );
    remote = DeviceRemoteDataSource(client);
  });

  tearDown(() async {
    client.dispose();
    await server.close(force: true);
  });

  for (final header in [
    'application/json',
    'text/plain',
    'text/plain; charset=utf-8',
  ]) {
    for (final mode in ['colors', 'channels', 'cold_warm']) {
      test('$mode is read by both consumers with $header', () async {
        contentType = header;
        responseBody = jsonEncode({'ch_mode': mode});
        expect(await remote.getChMode(host), mode);
        final state = await remote.getStripState(host);
        expect(state.chMode, mode);
        expect(state.color, 'FF00FF00');
        expect(state.on, isFalse);
        expect(requests, [
          'GET /api/v1/ch_mode',
          'GET /api/v1/device',
          'GET /api/v1/ch_mode',
        ]);
      });
    }
  }

  for (final invalid in [
    'not json',
    'null',
    '[]',
    '{}',
    '{"ch_mode":123}',
    '{"ch_mode":"undef"}',
  ]) {
    test('invalid mode response is not reported as colors: $invalid', () async {
      responseBody = invalid;
      await expectLater(remote.getChMode(host), throwsFormatException);
      await expectLater(remote.getStripState(host), throwsFormatException);
    });
  }

  test('missing optional mode endpoint keeps legacy colors fallback', () async {
    status = 404;
    expect((await remote.getStripState(host)).chMode, 'colors');
    await expectLater(
      remote.getChMode(host),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          404,
        ),
      ),
    );
  });

  test('server failure is not reported as a successful colors read', () async {
    status = 500;
    await expectLater(
      remote.getStripState(host),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          500,
        ),
      ),
    );
    await expectLater(remote.getChMode(host), throwsA(isA<DioException>()));
  });

  test('timeout is not reported as a successful colors read', () async {
    delay = const Duration(milliseconds: 500);
    await expectLater(
      remote.getStripState(host),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.receiveTimeout,
        ),
      ),
    );
    await expectLater(remote.getChMode(host), throwsA(isA<DioException>()));
  });
}
