// Integration test: Energy History page (firmware >= 5.0.0; WS2, WSE, WSX).
//
// Drives the real Flutter app against a local fake myStrom HTTP server with
// WS2 history records seeded. Exercises the History tile → date selector,
// chart rendering, summary cards, "no history" state, and unsupported
// firmware detection. No real hardware needed.
//
// Run on Windows desktop:
//   flutter test integration_test/history_test.dart -d windows

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
  late FakeMystromServer switchServer;
  late FakeDeviceState switchState;
  late FakeMystromServer legacyServer;
  late FakeDeviceState legacyState;

  setUpAll(() async {
    tmpHiveDir = await Directory.systemTemp.createTemp('mystrom_hist_hive_');
    Hive.init(tmpHiveDir.path);
    Hive.registerAdapter(StoredDeviceAdapter());
    Hive.registerAdapter(SceneAdapter());
    Hive.registerAdapter(SceneActionAdapter());

    deviceDs = DeviceLocalDataSource();
    await deviceDs.init();
    sceneDs = SceneLocalDataSource();
    await sceneDs.init();

    // ---- WS2 with firmware 5.0.0 + seeded history ----
    switchServer = FakeMystromServer();
    await switchServer.start();
    switchState = switchServer.register(
      FakeDeviceState(
        mac: 'AA:BB:CC:DD:EE:F2',
        type: 'ws2',
        model: 'WS2',
        version: '5.0.0',
      ),
    );

    // Seed 3 hourly records (newest-first) for "today" so the History
    // page has data to chart. Cumulative energy `e` is in watt-seconds,
    // increasing by ~36000 Ws (0.01 kWh) per hour.
    final now = DateTime.now().toUtc();
    final t0 = DateTime.utc(now.year, now.month, now.day, 10, 0, 0);
    final t1 = DateTime.utc(now.year, now.month, now.day, 11, 0, 0);
    final t2 = DateTime.utc(now.year, now.month, now.day, 12, 0, 0);
    switchState.history = [
      {'t': _iso(t2), 'e': 72000.0},
      {'t': _iso(t1), 'e': 36000.0},
      {'t': _iso(t0), 'e': 0.0},
    ];

    // ---- WS2 with legacy firmware (no history support) ----
    legacyServer = FakeMystromServer();
    await legacyServer.start();
    legacyState = legacyServer.register(
      FakeDeviceState(
        mac: 'AA:BB:CC:DD:EE:F3',
        type: 'ws2',
        model: 'WS2',
        version: '2.0.0',
      ),
    );

    final now2 = DateTime.now();
    await deviceDs.upsert(
      StoredDevice(
        mac: switchState.mac,
        name: 'History Switch',
        typeCode: 106, // WS2
        lastKnownIp: '${switchServer.host}:${switchServer.port}',
        lastSeen: now2,
        addedAt: DateTime(2026, 1, 1),
      ),
    );
    await deviceDs.upsert(
      StoredDevice(
        mac: legacyState.mac,
        name: 'Legacy Switch',
        typeCode: 106, // WS2
        lastKnownIp: '${legacyServer.host}:${legacyServer.port}',
        lastSeen: now2,
        addedAt: DateTime(2026, 1, 1),
      ),
    );

    discovery = UdpDiscoveryService();
  });

  tearDownAll(() async {
    await switchServer.stop();
    await legacyServer.stop();
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
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  testWidgets('History tile opens the history page and shows a chart', (
    tester,
  ) async {
    await pumpApp(tester);

    // Open the WS2 detail page.
    await tester.tap(find.byKey(const Key('device_card_AA:BB:CC:DD:EE:F2')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The History tile should be present (WS2 + fw 5.0.0).
    final historyTile = find.byKey(const Key('detail_history_tile'));
    expect(historyTile, findsOneWidget);

    // Tap the History tile.
    await tester.ensureVisible(historyTile);
    await tester.tap(historyTile);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // History page loaded: date bar present, summary cards, chart.
    expect(find.byKey(const Key('history_back_button')), findsOneWidget);
    expect(find.byKey(const Key('history_date_label')), findsOneWidget);
    expect(find.text('Total Energy'), findsOneWidget);
    expect(find.text('Avg Power'), findsOneWidget);
    expect(find.text('Peak Power'), findsOneWidget);
    expect(find.text('Intervals'), findsOneWidget);

    // Two intervals are derived from three records.
    expect(find.text('2'), findsOneWidget);

    // Navigate back.
    await tester.tap(find.byKey(const Key('history_back_button')));
    await tester.pumpAndSettle();
  });

  testWidgets('History page shows unsupported message on legacy firmware', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_AA:BB:CC:DD:EE:F3')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The History tile is still shown (the type supports it); the page
    // checks firmware and shows the unsupported message.
    final historyTile = find.byKey(const Key('detail_history_tile'));
    expect(historyTile, findsOneWidget);
    await tester.ensureVisible(historyTile);
    await tester.tap(historyTile);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byKey(const Key('history_back_button')), findsOneWidget);
    expect(find.textContaining('firmware'), findsWidgets);

    await tester.tap(find.byKey(const Key('history_back_button')));
    await tester.pumpAndSettle();
  });

  testWidgets('History page handles a device with no records', (tester) async {
    // Clear history for the WS2 device.
    switchState.history = const [];
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_AA:BB:CC:DD:EE:F2')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final historyTile = find.byKey(const Key('detail_history_tile'));
    await tester.ensureVisible(historyTile);
    await tester.tap(historyTile);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byKey(const Key('history_back_button')), findsOneWidget);
    expect(find.textContaining('No history data'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history_back_button')));
    await tester.pumpAndSettle();
  });
}

/// Format a UTC [DateTime] as an ISO-8601 timestamp with a trailing `Z`,
/// matching the myStrom history API.
String _iso(DateTime utc) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)}'
      'T${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}Z';
}