// Smoke integration test: launches the real Flutter app with an isolated
// Hive store (temp dir) and a silent UDP discovery service (no socket
// binding), then walks the main screens to make sure nothing crashes.
//
// Run on Windows desktop:
//   flutter test integration_test/smoke_test.dart -d windows

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
import 'package:mystrom_local/data/repositories/scene_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpHiveDir;
  late DeviceLocalDataSource deviceDs;
  late SceneLocalDataSource sceneDs;
  late UdpDiscoveryService discovery;

  setUpAll(() async {
    // Use a unique temp directory so the test never touches the user's
    // real Hive store on the machine.
    tmpHiveDir = await Directory.systemTemp.createTemp('mystrom_test_hive_');
    Hive.init(tmpHiveDir.path);
    Hive.registerAdapter(StoredDeviceAdapter());
    Hive.registerAdapter(SceneAdapter());
    Hive.registerAdapter(SceneActionAdapter());

    deviceDs = DeviceLocalDataSource();
    await deviceDs.init();
    sceneDs = SceneLocalDataSource();
    await sceneDs.init();

    // Real service, but we deliberately do NOT call start(), so the UDP
    // socket is never bound. The discovery stream stays silent and the
    // dashboard shows the empty state — perfect for a smoke test.
    discovery = UdpDiscoveryService();
  });

  tearDownAll(() async {
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

  testWidgets('dashboard shows empty state and opens Add Device page', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('myStrom Local'), findsOneWidget);
    expect(find.byKey(const Key('empty_state')), findsOneWidget);
    expect(find.text('Add device manually'), findsOneWidget);

    await tester.tap(find.byKey(const Key('appbar_add_device')));
    await tester.pumpAndSettle();

    expect(find.text('Add Device'), findsOneWidget);
    expect(find.byKey(const Key('tab_discovered')), findsOneWidget);
    expect(find.byKey(const Key('tab_softap')), findsOneWidget);
    expect(find.byKey(const Key('tab_wps')), findsOneWidget);

    // Switch tabs and make sure the page does not blow up.
    await tester.tap(find.byKey(const Key('tab_softap')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_wps')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_discovered')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add_device_back_button')));
    await tester.pumpAndSettle();
    expect(find.text('myStrom Local'), findsOneWidget);
  });

  testWidgets('scene editor can be opened, filled and discarded', (
    tester,
  ) async {
    // Seed data BEFORE pumping the app so DeviceProvider picks it up
    // during construction (its _refresh() runs in the constructor and
    // is private, so we cannot trigger it after the fact).
    await deviceDs.upsert(
      StoredDevice(
        mac: 'AA:BB:CC:DD:EE:F0',
        name: 'Test Switch',
        typeCode: 106, // WS2
        lastKnownIp: '192.0.2.1',
        addedAt: DateTime(2026, 1, 1),
      ),
    );
    final sceneRepo = SceneRepository(sceneDs);
    await sceneRepo.save(
      Scene(
        id: 'seed-scene',
        name: 'Seed scene',
        iconCode: Icons.home.codePoint,
        colorValue: Colors.blue.toARGB32(),
        actions: const [],
      ),
    );

    await pumpApp(tester);

    expect(find.byKey(const Key('scene_add_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('scene_add_button')));
    await tester.pumpAndSettle();

    // The editor page is open; the name field is seeded with "New scene".
    expect(find.byKey(const Key('scene_name_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('scene_name_field')),
      'Test scene',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Save the scene so it persists in the temp Hive store.
    await tester.tap(find.byKey(const Key('scene_save_fab')));
    await tester.pumpAndSettle();

    // Back on the dashboard, the new scene chip should appear.
    expect(find.text('Test scene'), findsWidgets);

    // Open it again from the editor via long-press to edit.
    await tester.longPress(find.text('Test scene').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scene_delete_button')), findsOneWidget);

    // Delete it. _delete() removes the scene and pops immediately.
    await tester.tap(find.byKey(const Key('scene_delete_button')));
    await tester.pumpAndSettle();

    // Back on the dashboard the scene chip should be gone.
    expect(find.text('Test scene'), findsNothing);
  });

  testWidgets('multiple scenes can be created without overwriting', (
    tester,
  ) async {
    await deviceDs.upsert(
      StoredDevice(
        mac: 'AA:BB:CC:DD:EE:G0',
        name: 'Test Switch 2',
        typeCode: 106,
        lastKnownIp: '192.0.2.2',
        addedAt: DateTime(2026, 1, 1),
      ),
    );
    await pumpApp(tester);

    // Create scene #1.
    await tester.tap(find.byKey(const Key('scene_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('scene_name_field')),
      'Scene A',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scene_save_fab')));
    await tester.pumpAndSettle();
    expect(find.text('Scene A'), findsWidgets);

    // Create scene #2 — must NOT overwrite scene A.
    await tester.tap(find.byKey(const Key('scene_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('scene_name_field')),
      'Scene B',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scene_save_fab')));
    await tester.pumpAndSettle();

    // Both scene chips should be visible.
    expect(find.text('Scene A'), findsWidgets);
    expect(find.text('Scene B'), findsWidgets);

    // Verify both persisted in Hive with distinct ids.
    final scenes = sceneDs.getAll();
    expect(scenes.length, greaterThanOrEqualTo(2));
    expect(scenes.map((s) => s.id).toSet().length, scenes.length);
  });
}
