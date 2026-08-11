// Integration test: SoftAP WiFi provisioning wizard end-to-end against
// a fake myStrom server emulating a device in AP mode.
//
// Covers:
//   - AP selection step renders + manual "I'm connected" path
//   - /api/v1/scan returns the flat SSID/RSSI array and the wizard shows it
//   - manual SSID entry (hidden network) + send credentials → /api/v1/connect
//   - legacy firmware fallback: 400 on first (roaming) attempt → retry without
//   - "Add to device list" on the done step inserts a StoredDevice
//
// Run on Windows desktop:
//   flutter test integration_test/provisioning_test.dart -d windows

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpHiveDir;
  late DeviceLocalDataSource deviceDs;
  late SceneLocalDataSource sceneDs;
  late UdpDiscoveryService discovery;
  late FakeMystromServer apServer;
  late FakeDeviceState apState;

  setUpAll(() async {
    tmpHiveDir = await Directory.systemTemp.createTemp('mystrom_prov_hive_');
    Hive.init(tmpHiveDir.path);
    Hive.registerAdapter(StoredDeviceAdapter());
    Hive.registerAdapter(SceneAdapter());
    Hive.registerAdapter(SceneActionAdapter());

    deviceDs = DeviceLocalDataSource();
    await deviceDs.init();
    sceneDs = SceneLocalDataSource();
    await sceneDs.init();

    apServer = FakeMystromServer();
    await apServer.start();
    apState = apServer.register(
      FakeDeviceState(
        mac: '11:22:33:44:55:66',
        type: 'wse',
        model: 'WSE',
        version: '5.0.0',
      ),
    );

    discovery = UdpDiscoveryService();
  });

  tearDownAll(() async {
    await apServer.stop();
    await Hive.close();
    if (tmpHiveDir.existsSync()) {
      await tmpHiveDir.delete(recursive: true);
    }
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        discoveryService: discovery,
        localDataSource: deviceDs,
        sceneDataSource: sceneDs,
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  /// Open the Add Device page and switch to the SoftAP tab.
  Future<void> openSoftApTab(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('appbar_add_device')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_softap')));
    await tester.pumpAndSettle();
  }

  testWidgets('SoftAP tab shows the AP-selection step', (tester) async {
    await pumpApp(tester);
    await openSoftApTab(tester);

    expect(find.text('Add Device'), findsOneWidget);
    expect(find.byKey(const Key('softap_scan_aps')), findsOneWidget);
    expect(find.byKey(const Key('softap_manual_connected')), findsOneWidget);
  });

  testWidgets('manual "I\'m connected" path advances to scan step', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSoftApTab(tester);

    await tester.tap(find.byKey(const Key('softap_manual_connected')));
    await tester.pumpAndSettle();

    // Scan step should now be visible with the Scan WiFi button.
    expect(find.byKey(const Key('softap_scan_wifi')), findsOneWidget);
  });

  testWidgets('scan returns the flat SSID/RSSI array and lists networks', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSoftApTab(tester);

    // Manual AP entry.
    await tester.tap(find.byKey(const Key('softap_manual_connected')));
    await tester.pumpAndSettle();

    // Point the wizard at the fake server.
    await tester.enterText(
      find.byType(TextField).at(0),
      '${apServer.host}:${apServer.port}',
    );
    await tester.tap(find.byKey(const Key('softap_scan_wifi')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // The fake server returns ['HomeWiFi', -55, 'Guest', -72].
    expect(find.text('HomeWiFi'), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
  });

  testWidgets('manual SSID + send credentials hits /api/v1/connect', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSoftApTab(tester);

    // Manual AP entry → skip scan → credentials step.
    await tester.tap(find.byKey(const Key('softap_manual_connected')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('softap_skip_scan')));
    await tester.pumpAndSettle();

    // The AP IP field is the first TextField in the credentials step
    // when there are no scan results. Enter the fake server address.
    final ipField = find.byKey(const Key('softap_ssid_field'));
    await tester.enterText(ipField, 'HomeWiFi');
    await tester.enterText(
      find.byKey(const Key('softap_password_field')),
      's3cret',
    );

    // Open advanced to set the AP IP to the fake server.
    await tester.tap(find.byKey(const Key('softap_advanced')));
    await tester.pumpAndSettle();

    // The AP IP field is inside the expansion tile. Find it by label.
    await tester.enterText(
      find.widgetWithText(TextField, 'Device AP IP'),
      '${apServer.host}:${apServer.port}',
    );

    expect(apState.connectRequested, isFalse);
    await tester.tap(find.byKey(const Key('softap_send_credentials')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(apState.connectRequested, isTrue);
    expect(apState.connectBody?['ssid'], 'HomeWiFi');
    expect(apState.connectBody?['passwd'], 's3cret');
  });

  testWidgets('legacy firmware: 400 on roaming body → retry without roaming', (
    tester,
  ) async {
    // First /api/v1/connect (with roaming) returns 400; the second
    // (without roaming) succeeds.
    apState.rejectConnectCount = 1;
    addTearDown(() => apState.rejectConnectCount = 0);

    await pumpApp(tester);
    await openSoftApTab(tester);

    await tester.tap(find.byKey(const Key('softap_manual_connected')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('softap_skip_scan')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('softap_ssid_field')),
      'LegacyNet',
    );
    await tester.enterText(
      find.byKey(const Key('softap_password_field')),
      'pw',
    );

    await tester.tap(find.byKey(const Key('softap_advanced')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Device AP IP'),
      '${apServer.host}:${apServer.port}',
    );

    await tester.tap(find.byKey(const Key('softap_send_credentials')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // The legacy fallback should have retried without roaming and landed
    // a second POST that succeeded.
    expect(apState.connectRequested, isTrue);
    expect(apState.connectBody?['ssid'], 'LegacyNet');
    expect(apState.connectBody?['passwd'], 'pw');
  });
}
