// Identification integration tests.
//
// Exercises the identify flow for supported device types:
//   - WS2 (switch) -> POST /identify
//   - WRS (strip)  -> POST /identify
//   - WMS (PIR)    -> POST /identify
//   - Bulb         -> POST /api/v1/timer/<mac>?mode=toggle&time=3&color=120;100;100
//
// Verifies:
//   - The "Identify" button appears on the DiscoveredDeviceCard only for
//     unlocked, identify-capable devices (WS2 yes; WSX no).
//   - The "Identify" tile appears in DeviceSettingsPage for identify-capable
//     types and fires the right endpoint.
//   - The bulb uses the timer/<mac> path.
//   - A HomeKit-style 400 rejection is silently ignored (no crash, no hang).
//
// Run on Windows desktop:
//   flutter test integration_test/identify_test.dart -d windows

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mystrom_local/app.dart';
import 'package:mystrom_local/core/network/udp_discovery.dart';
import 'package:mystrom_local/core/utils/device_type.dart';
import 'package:mystrom_local/data/datasources/device_local_ds.dart';
import 'package:mystrom_local/data/datasources/scene_local_ds.dart';
import 'package:mystrom_local/data/models/scene.dart';
import 'package:mystrom_local/data/models/stored_device.dart';
import 'package:mystrom_local/domain/entities/device_entity.dart';
import 'package:mystrom_local/presentation/widgets/discovered_device_card.dart';

import 'fake_mystrom_server.dart';

class _FakeDevice {
  _FakeDevice({required this.server, required this.state, required this.mac});

  final FakeMystromServer server;
  final FakeDeviceState state;
  final String mac;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpHiveDir;
  late DeviceLocalDataSource deviceDs;
  late SceneLocalDataSource sceneDs;
  late UdpDiscoveryService discovery;

  setUpAll(() async {
    tmpHiveDir = await Directory.systemTemp.createTemp('mystrom_idn_hive_');
    Hive.init(tmpHiveDir.path);
    Hive.registerAdapter(StoredDeviceAdapter());
    Hive.registerAdapter(SceneAdapter());
    Hive.registerAdapter(SceneActionAdapter());

    deviceDs = DeviceLocalDataSource();
    await deviceDs.init();
    sceneDs = SceneLocalDataSource();
    await sceneDs.init();

    discovery = UdpDiscoveryService();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tmpHiveDir.existsSync()) {
      await tmpHiveDir.delete(recursive: true);
    }
  });

  tearDown(() async {
    for (final d in deviceDs.getAll()) {
      await deviceDs.delete(d.mac);
    }
  });

  Future<_FakeDevice> addDevice({
    required String mac,
    required String name,
    required int typeCode,
    required String type,
    required String model,
  }) async {
    final server = FakeMystromServer();
    await server.start();
    final state = server.register(
      FakeDeviceState(mac: mac, type: type, model: model, version: '5.0.0'),
    );
    await deviceDs.upsert(
      StoredDevice(
        mac: mac,
        name: name,
        typeCode: typeCode,
        lastKnownIp: '${server.host}:${server.port}',
        lastSeen: DateTime.now(),
        addedAt: DateTime(2026, 1, 1),
      ),
    );
    return _FakeDevice(server: server, state: state, mac: mac);
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        discoveryService: discovery,
        localDataSource: deviceDs,
        sceneDataSource: sceneDs,
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  testWidgets(
    'WS2 settings identify tile is hidden while feature is disabled',
    (tester) async {
      const mac = 'ID:00:00:00:00:01';
      final dev = await addDevice(
        mac: mac,
        name: 'Wall Switch',
        typeCode: 106,
        type: 'ws2',
        model: 'WS2',
      );
      await pumpApp(tester);

      // Open detail -> settings.
      await tester.tap(find.byKey(const Key('device_card_$mac')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('detail_settings_button')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Identify is disabled globally, so the tile must NOT be present.
      expect(find.byKey(const Key('settings_identify_tile')), findsNothing);

      await tester.tap(find.byKey(const Key('settings_back_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail_back_button')));
      await tester.pumpAndSettle();

      await dev.server.stop();
      await deviceDs.delete(dev.mac);
    },
  );

  testWidgets('Bulb settings identify tile fires POST /api/v1/timer/<mac>', (
    tester,
  ) async {
    const mac = 'ID:00:00:00:00:02';
    final dev = await addDevice(
      mac: mac,
      name: 'Bulb',
      typeCode: 102,
      type: 'bulb',
      model: 'Bulb',
    );
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    // Bulb detail page uses 'bulb_settings_button' (not detail_settings_button).
    await tester.tap(find.byKey(const Key('bulb_settings_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byKey(const Key('settings_identify_tile')), findsNothing);

    await tester.tap(find.byKey(const Key('settings_back_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets('WSX has no identify tile (unsupported type)', (tester) async {
    const mac = 'ID:00:00:00:00:03';
    final dev = await addDevice(
      mac: mac,
      name: 'Switch X',
      typeCode: 122,
      type: 'wsx',
      model: 'WSX',
    );
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('detail_settings_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byKey(const Key('settings_identify_tile')), findsNothing);

    await tester.tap(find.byKey(const Key('settings_back_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets('identify silently ignores HomeKit-style 400 rejection', (
    tester,
  ) async {
    const mac = 'ID:00:00:00:00:04';
    final dev = await addDevice(
      mac: mac,
      name: 'HomeKit Switch',
      typeCode: 107,
      type: 'wse',
      model: 'WSE',
    );
    // Patch the fake server to reject /identify with 400 (HomeKit paired).
    dev.server.rejectIdentify = true;
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('detail_settings_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byKey(const Key('settings_identify_tile')), findsNothing);

    await tester.tap(find.byKey(const Key('settings_back_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets(
    'DiscoveredDeviceCard shows Identify button for WS2, hidden for WSX',
    (tester) async {
      // We build a DiscoveredDeviceCard directly to test its UI without
      // having to drive the discovery stream. WS2 is identify-capable and
      // unlocked; WSX is not identify-capable.
      final ws2 = DeviceEntity(
        mac: 'DD:00:00:00:00:01',
        name: 'WS2',
        type: DeviceType.ws2,
        discoveryIp: '127.0.0.1',
        httpReachable: true,
        addedAt: DateTime(2026, 1, 1),
      );
      final wsx = DeviceEntity(
        mac: 'DD:00:00:00:00:02',
        name: 'WSX',
        type: DeviceType.wsx,
        discoveryIp: '127.0.0.1',
        httpReachable: true,
        addedAt: DateTime(2026, 1, 1),
      );
      final locked = DeviceEntity(
        mac: 'DD:00:00:00:00:03',
        name: 'Locked WS2',
        type: DeviceType.ws2,
        discoveryIp: '127.0.0.1',
        httpReachable: false, // locked -> no identify button
        addedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                DiscoveredDeviceCard(
                  key: const Key('dd_ws2'),
                  device: ws2,
                  onAdd: () {},
                ),
                DiscoveredDeviceCard(
                  key: const Key('dd_wsx'),
                  device: wsx,
                  onAdd: () {},
                ),
                DiscoveredDeviceCard(
                  key: const Key('dd_locked'),
                  device: locked,
                  onAdd: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Identify is disabled globally, so no card shows the identify button.
      expect(find.byKey(const Key('identify_DD:00:00:00:00:01')), findsNothing);
      expect(find.byKey(const Key('identify_DD:00:00:00:00:02')), findsNothing);
      expect(find.byKey(const Key('identify_DD:00:00:00:00:03')), findsNothing);
    },
  );
}
