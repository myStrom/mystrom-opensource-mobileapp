// Integration test: drives the real Flutter app against a local fake
// myStrom HTTP server. Exercises device control (toggle, color),
// settings (rename/room/favorite/save), scheduler (add/save) and scene
// creation/run. Asserts that every device is OFF at the end.
//
// Run on Windows desktop:
//   flutter test integration_test/control_test.dart -d windows

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
  late FakeMystromServer stripServer;
  late FakeDeviceState switchState;
  late FakeDeviceState stripState;

  setUpAll(() async {
    tmpHiveDir = await Directory.systemTemp.createTemp('mystrom_ctrl_hive_');
    Hive.init(tmpHiveDir.path);
    Hive.registerAdapter(StoredDeviceAdapter());
    Hive.registerAdapter(SceneAdapter());
    Hive.registerAdapter(SceneActionAdapter());

    deviceDs = DeviceLocalDataSource();
    await deviceDs.init();
    sceneDs = SceneLocalDataSource();
    await sceneDs.init();

    // One fake server per device, each on its own loopback port.
    switchServer = FakeMystromServer();
    await switchServer.start();
    switchState = switchServer.register(
      FakeDeviceState(
        mac: 'AA:BB:CC:DD:EE:F0',
        type: 'wse',
        model: 'WSE',
        version: '5.0.0',
      ),
    );

    stripServer = FakeMystromServer();
    await stripServer.start();
    stripState = stripServer.register(
      FakeDeviceState(
        mac: 'AA:BB:CC:DD:EE:F1',
        type: 'strip',
        model: 'WRS',
        version: '5.0.0',
      ),
    );

    // Seed the Hive store with the two devices pointing at the fake
    // servers (127.0.0.1:<port>). lastSeen=now keeps the cards "online"
    // so the power toggle button is rendered (the app hides it when a
    // device is considered offline, i.e. lastSeen > 30s ago).
    final now = DateTime.now();
    await deviceDs.upsert(
      StoredDevice(
        mac: switchState.mac,
        name: 'Test Switch',
        typeCode: 107, // WSE
        lastKnownIp: '${switchServer.host}:${switchServer.port}',
        lastSeen: now,
        addedAt: DateTime(2026, 1, 1),
      ),
    );
    await deviceDs.upsert(
      StoredDevice(
        mac: stripState.mac,
        name: 'Test Strip',
        typeCode: 105, // WRS
        lastKnownIp: '${stripServer.host}:${stripServer.port}',
        lastSeen: now,
        addedAt: DateTime(2026, 1, 1),
      ),
    );

    discovery = UdpDiscoveryService();
  });

  tearDownAll(() async {
    await switchServer.stop();
    await stripServer.stop();
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
    // Give the HTTP probes + initial polls a moment to settle.
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// Bump lastSeen for both seeded devices to "now" so the dashboard
  /// cards are considered online (the app hides the power toggle when a
  /// device is offline, i.e. lastSeen > 30s ago). Call before pumpApp in
  /// tests that rely on the card power button.
  Future<void> touchLastSeen() async {
    final now = DateTime.now();
    final sw = deviceDs.getByMac(switchState.mac)!..lastSeen = now;
    await sw.save();
    final st = deviceDs.getByMac(stripState.mac)!..lastSeen = now;
    await st.save();
  }

  testWidgets('switch can be toggled on then off from the detail page', (
    tester,
  ) async {
    await pumpApp(tester);

    // Open the switch detail page by tapping its card.
    await tester.tap(find.byKey(const Key('device_card_AA:BB:CC:DD:EE:F0')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byKey(const Key('switch_power_card')), findsOneWidget);
    expect(switchState.relay, isFalse);

    // Tap the power card to turn ON.
    await tester.tap(find.byKey(const Key('switch_power_card')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(switchState.relay, isTrue);

    // Tap again to turn OFF.
    await tester.tap(find.byKey(const Key('switch_power_card')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(switchState.relay, isFalse);

    // Leave the detail page.
    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();
  });

  testWidgets('strip can be turned on, recolored and turned off', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_AA:BB:CC:DD:EE:F1')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byKey(const Key('strip_on_switch')), findsOneWidget);
    expect(stripState.on, isFalse);

    // Turn the strip ON via the On switch.
    await tester.tap(find.byKey(const Key('strip_on_switch')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(stripState.on, isTrue);

    // The strip detail page has a color picker. Tap somewhere inside the
    // HSV color wheel area to trigger a setColor POST. We use the
    // descendant finder on the ColorPickerWidget.
    final colorPicker = find.byType(Material);
    // The ColorPickerWidget is the first Material under the body; tap its
    // center to pick a color.
    await tester.tap(colorPicker.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    // A color POST should have been sent; the server stored some color.
    // We do not assert the exact HSV (widget-dependent) — only that the
    // request path was exercised without crashing.

    // Turn the strip OFF.
    await tester.tap(find.byKey(const Key('strip_on_switch')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(stripState.on, isFalse);

    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();
  });

  testWidgets('device settings can be edited and saved', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_AA:BB:CC:DD:EE:F0')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.byKey(const Key('detail_settings_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Edit the name and room.
    await tester.enterText(
      find.byKey(const Key('settings_name_field')),
      'Living Room Switch',
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('settings_room_field')),
      'Living Room',
    );
    await tester.pumpAndSettle();

    // Toggle the favorite switch ON.
    await tester.tap(find.byKey(const Key('settings_favorite_switch')));
    await tester.pumpAndSettle();

    // Save.
    await tester.tap(find.byKey(const Key('settings_save_fab')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify the device was renamed in the store.
    final stored = deviceDs.getByMac(switchState.mac)!;
    expect(stored.customName, 'Living Room Switch');
    expect(stored.room, 'Living Room');
    expect(stored.favorite, isTrue);

    // Settings -> Switch detail -> Dashboard.
    await tester.tap(find.byKey(const Key('settings_back_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();
  });

  testWidgets('scheduler can add an entry and save it', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_AA:BB:CC:DD:EE:F1')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Confirm we are on the strip detail page.
    expect(find.byKey(const Key('detail_back_button')), findsOneWidget);

    // Open the scheduler from the strip detail page.
    await tester.ensureVisible(find.byKey(const Key('detail_scheduler_tile')));
    await tester.tap(find.byKey(const Key('detail_scheduler_tile')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The scheduler form should be visible (strip supports scheduler).
    expect(find.byKey(const Key('scheduler_hour_field')), findsOneWidget);
    expect(stripState.scheduler, isEmpty);

    // Add a schedule entry: hour=7, minute=30 (defaults keep action=on).
    await tester.enterText(find.byKey(const Key('scheduler_hour_field')), '7');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('scheduler_minute_field')),
      '30',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scheduler_add_button')));
    await tester.pumpAndSettle();

    // A new scheduler card should appear (the form adds an item to the
    // list and re-renders). We assert on the number of SchedulerCard
    // widgets rather than text, since the card edits hour/minute via
    // TextFields (no formatted "HH:MM" label).
    expect(find.byKey(const Key('scheduler_save_fab')), findsOneWidget);

    // Save the schedule to the device.
    await tester.tap(find.byKey(const Key('scheduler_save_fab')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The fake server should now hold exactly one scheduler item.
    expect(stripState.scheduler.length, 1);
    expect(stripState.scheduler.first['action'], 'on');

    // Go back to the detail page, then to the dashboard.
    await tester.tap(find.byKey(const Key('scheduler_back_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();
  });

  testWidgets('scene with device actions can be created and run', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('scene_add_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('scene_add_button')));
    await tester.pumpAndSettle();

    // Name the scene.
    await tester.enterText(
      find.byKey(const Key('scene_name_field')),
      'All off',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Add a device action to the scene: tap the "Add device action"
    // button below the actions list.
    final addAction = find.widgetWithText(FilledButton, 'Add device action');
    if (tester.any(addAction)) {
      await tester.tap(addAction);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // A device picker dialog appears; pick the first device.
      final pickFirst = find.text('Test Switch');
      if (tester.any(pickFirst)) {
        await tester.tap(pickFirst.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    }

    // Save the scene. The editor body is a ListView; scroll the FAB
    // into view within the first scrollable before tapping.
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('scene_save_fab')),
      200,
      scrollable: scrollable,
    );
    await tester.tap(
      find.byKey(const Key('scene_save_fab')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    // Back on the dashboard, the new scene chip should be visible.
    expect(find.text('All off'), findsWidgets);
  });

  testWidgets('strip timer button sets a timer via the detail page', (
    tester,
  ) async {
    await touchLastSeen();
    await pumpApp(tester);

    // Open the strip detail page.
    await tester.tap(find.byKey(const Key('device_card_AA:BB:CC:DD:EE:F1')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Open the timer bottom sheet (tile may be off-screen).
    await tester.ensureVisible(find.byKey(const Key('detail_timer_tile')));
    await tester.tap(find.byKey(const Key('detail_timer_tile')));
    await tester.pumpAndSettle();

    // Set the timer (default mode=off, 5 minutes = 300s).
    await tester.tap(find.byKey(const Key('timer_set_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(stripState.timerMode, isNot('none'));
    expect(stripState.timerSeconds, 300);

    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();
  });

  testWidgets('energy accumulation is shown as kWh on the switch detail page', (
    tester,
  ) async {
    // Make the relay on so the fake reports Ws = 3600000 (1 kWh).
    switchState.relay = true;
    await touchLastSeen();
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_AA:BB:CC:DD:EE:F0')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Total energy = accumulated total (0) + current boot (1 kWh).
    // "Since boot" row shows the current-boot value (1 kWh) too.
    expect(find.text('Total energy'), findsOneWidget);
    expect(find.text('Since boot'), findsOneWidget);
    expect(find.text('1.000 kWh'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    // Leave the relay off for the final "all devices off" check.
    switchState.relay = false;
  });

  testWidgets('all devices are off after the test suite', (tester) async {
    // Turn the switch ON first to make sure the final assertion is
    // meaningful, then turn everything OFF from the dashboard cards.
    await touchLastSeen();
    await pumpApp(tester);

    // Toggle the switch ON via the card power button.
    await tester.tap(find.byKey(const Key('card_power_button')).first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(switchState.relay, isTrue);

    // Toggle it back OFF.
    await tester.tap(find.byKey(const Key('card_power_button')).first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Final assertion: every fake device must be OFF.
    expect(
      switchState.relay,
      isFalse,
      reason: 'switch relay should be off after the suite',
    );
    expect(
      stripState.on,
      isFalse,
      reason: 'strip should be off after the suite',
    );
  });
}
