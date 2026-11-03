import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mystrom_local/core/network/device_http_client.dart';
import 'package:mystrom_local/core/utils/device_type.dart';
import 'package:mystrom_local/data/datasources/device_remote_ds.dart';

import '../integration_test/fake_mystrom_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('WRS advertises lighting controls without measurement capabilities', () {
    expect(DeviceType.wrs.hasPower, isFalse);
    expect(DeviceType.wrs.hasTemperature, isFalse);
    expect(DeviceType.wrs.hasHistory, isFalse);
    expect(DeviceType.wrs.isStrip, isTrue);
    expect(DeviceType.wrs.hasTimer, isTrue);
    expect(DeviceType.ws2.hasPower, isTrue);
    expect(DeviceType.wse.hasPower, isTrue);
  });

  test(
    'power read does not issue any request to WRS; WS2 is still read',
    () async {
      HttpOverrides.global = null;
      final server = FakeMystromServer();
      await server.start();
      final state = server.register(
        FakeDeviceState(
          mac: '020000000105',
          type: 'strip',
          model: 'WRS',
          version: '5.0.4',
        ),
      )..on = true;
      final client = DeviceHttpClient(authentication: false);
      final remote = DeviceRemoteDataSource(client);
      final host = '${server.host}:${server.port}';
      try {
        expect(await remote.getPower(host, DeviceType.wrs), isNull);
        expect(server.requests, isEmpty);
        state.relay = true;
        expect(await remote.getPower(host, DeviceType.ws2), 12.5);
        expect(server.requests, hasLength(1));
        expect(server.requests.single.method, 'GET');
        expect(server.requests.single.path, '/report');
        expect((await remote.getStripState(host)).on, isTrue);
      } finally {
        client.dispose();
        await server.stop();
      }
    },
  );
}
