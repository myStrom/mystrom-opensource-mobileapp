import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mystrom_local/app.dart';
import 'package:mystrom_local/core/network/udp_discovery.dart';
import 'package:mystrom_local/data/datasources/device_local_ds.dart';
import 'package:mystrom_local/data/datasources/scene_local_ds.dart';
import 'package:mystrom_local/data/models/scene.dart';
import 'package:mystrom_local/data/models/stored_device.dart';

import 'fake_mystrom_server.dart';

class _QuietDiscovery extends UdpDiscoveryService {
  @override
  Future<void> start() async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'WRS is excluded from home/room power and energy; controls remain',
    (tester) async {
      final folder = await Directory.systemTemp.createTemp('wrs_no_power_');
      final stripServer = FakeMystromServer();
      final switchServer = FakeMystromServer();
      await stripServer.start();
      await switchServer.start();
      final strip =
          stripServer.register(
              FakeDeviceState(
                mac: '020000000105',
                type: 'strip',
                model: 'WRS',
                version: '5.0.4',
              ),
            )
            ..on = true
            ..chMode = 'channels'
            ..mode = 'rgb'
            ..color = '10203040';
      final outlet = switchServer.register(
        FakeDeviceState(
          mac: '020000000106',
          type: 'ws2',
          model: 'WS2',
          version: '5.0.4',
        ),
      )..relay = true;
      Hive.init(folder.path);
      Hive.registerAdapter(StoredDeviceAdapter());
      Hive.registerAdapter(SceneAdapter());
      Hive.registerAdapter(SceneActionAdapter());
      final local = DeviceLocalDataSource();
      final scenes = SceneLocalDataSource();
      await local.init();
      await scenes.init();
      try {
        await local.upsert(
          StoredDevice(
            mac: strip.mac,
            name: 'Strip without meter',
            typeCode: 105,
            lastKnownIp: '${stripServer.host}:${stripServer.port}',
            lastSeen: DateTime.now(),
            addedAt: DateTime.now(),
            room: 'Strip only',
            // Legacy/stale stored values must not leak into any energy sum.
            totalEnergyWs: 360000000,
            bootEnergyWs: 360000000,
          ),
        );
        await local.upsert(
          StoredDevice(
            mac: outlet.mac,
            name: 'Metered outlet',
            typeCode: 106,
            lastKnownIp: '${switchServer.host}:${switchServer.port}',
            lastSeen: DateTime.now(),
            addedAt: DateTime.now(),
            bootId: 'boot-1',
            bootEnergyWs: 3600000,
          ),
        );
        await tester.pumpWidget(
          MyApp(
            locale: const Locale('en'),
            discoveryService: _QuietDiscovery(),
            localDataSource: local,
            sceneDataSource: scenes,
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        for (var i = 0; i < 20 && find.text('12.5 W').evaluate().isEmpty; i++) {
          await tester.pumpAndSettle(const Duration(milliseconds: 200));
        }
        expect(find.text('12.5 W'), findsOneWidget);
        expect(find.text('1.000 kWh'), findsOneWidget);
        expect(find.text('201.000 kWh'), findsNothing);

        await tester.tap(find.text('Strip only'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(find.text('Total power'), findsNothing);
        expect(find.text('Total energy'), findsNothing);
        expect(
          find.byKey(const Key('device_card_020000000105')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('card_power_button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(strip.on, isFalse);
        final writes = stripServer.requests.where((r) => r.method == 'POST');
        expect(writes, hasLength(1));
        expect(writes.single.path, '/device');
        expect(Uri.splitQueryString(writes.single.body!), {'action': 'off'});
        expect(
          stripServer.requests.any(
            (r) => ['/report', '/power', '/api/v1/power'].contains(r.path),
          ),
          isFalse,
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await Hive.close();
        await stripServer.stop();
        await switchServer.stop();
        await folder.delete(recursive: true);
      }
    },
  );
}
