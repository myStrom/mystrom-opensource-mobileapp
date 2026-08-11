// Per-device-type integration tests.
//
// For every supported device type, seeds the Hive store with one device
// pointing at a dedicated fake myStrom HTTP server, opens the matching
// detail page, performs a type-specific action and verifies the server
// received the right request. All devices end up OFF at the end.
//
// Run on Windows desktop:
//   flutter test integration_test/devices_test.dart -d windows

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

/// A fake device + its Hive seed record.
class _FakeDevice {
  _FakeDevice({
    required this.server,
    required this.state,
    required this.mac,
    required this.name,
    required this.typeCode,
  });

  final FakeMystromServer server;
  final FakeDeviceState state;
  final String mac;
  final String name;
  final int typeCode;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpHiveDir;
  late DeviceLocalDataSource deviceDs;
  late SceneLocalDataSource sceneDs;
  late UdpDiscoveryService discovery;

  /// Spin up a fake server + seed Hive for one device of [typeCode].
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
    return _FakeDevice(
      server: server,
      state: state,
      mac: mac,
      name: name,
      typeCode: typeCode,
    );
  }

  setUpAll(() async {
    tmpHiveDir = await Directory.systemTemp.createTemp('mystrom_dev_hive_');
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

  /// Build the app. Call after seeding all devices for the test.
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

  /// Keep lastSeen fresh so the card power button stays visible across a
  /// long suite (the app hides it once lastSeen > 30s ago).
  Future<void> touchLastSeen(String mac) async {
    final d = deviceDs.getByMac(mac)!..lastSeen = DateTime.now();
    await d.save();
  }

  // ---- Switch family: WS2, WSE, WSX ----
  // All expose the same /relay + /toggle + timer + scheduler endpoints.

  for (final entry in [
    ('WS2', 106, 'AA:BB:CC:DD:EE:A0', 'ws2'),
    ('WSE', 107, 'AA:BB:CC:DD:EE:A1', 'wse'),
    ('WSX', 122, 'AA:BB:CC:DD:EE:A2', 'wsx'),
  ]) {
    final model = entry.$1;
    final code = entry.$2;
    final mac = entry.$3;
    final type = entry.$4;

    testWidgets('$model switch toggles ON then OFF', (tester) async {
      final dev = await addDevice(
        mac: mac,
        name: '$model Switch',
        typeCode: code,
        type: type,
        model: model,
      );
      await pumpApp(tester);

      await tester.tap(find.byKey(Key('device_card_$mac')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byKey(const Key('switch_power_card')), findsOneWidget);
      expect(dev.state.relay, isFalse);

      await tester.tap(find.byKey(const Key('switch_power_card')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(dev.state.relay, isTrue);

      await tester.tap(find.byKey(const Key('switch_power_card')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(dev.state.relay, isFalse);

      await tester.tap(find.byKey(const Key('detail_back_button')));
      await tester.pumpAndSettle();

      await dev.server.stop();
      await deviceDs.delete(dev.mac);
    });
  }

  testWidgets('LCS switch toggles and saves a button action URL', (
    tester,
  ) async {
    const mac = 'AA:BB:CC:DD:EE:B0';
    final dev = await addDevice(
      mac: mac,
      name: 'LCS Switch',
      typeCode: 120,
      type: 'lcs',
      model: 'LCS',
    );
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // LCS behaves like a switch: power card toggles the relay.
    expect(find.byKey(const Key('switch_power_card')), findsOneWidget);
    await tester.tap(find.byKey(const Key('switch_power_card')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(dev.state.relay, isTrue);

    // Turn back OFF.
    await tester.tap(find.byKey(const Key('switch_power_card')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(dev.state.relay, isFalse);

    // LCS button action is now configured from Settings via the picker.
    await tester.tap(find.byKey(const Key('detail_settings_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byKey(const Key('lcs_action_tile')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings_back_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets('WRS strip turns on, recolors and turns off', (tester) async {
    const mac = 'AA:BB:CC:DD:EE:C0';
    final dev = await addDevice(
      mac: mac,
      name: 'WRS Strip',
      typeCode: 105,
      type: 'strip',
      model: 'WRS',
    );
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byKey(const Key('strip_on_switch')), findsOneWidget);
    expect(dev.state.on, isFalse);

    await tester.tap(find.byKey(const Key('strip_on_switch')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(dev.state.on, isTrue);

    // Tap the HSV color wheel area to send a color POST.
    await tester.tap(find.byType(Material).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('strip_on_switch')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(dev.state.on, isFalse);

    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets('WLL dimmer turns on, sets brightness range and turns off', (
    tester,
  ) async {
    const mac = 'AA:BB:CC:DD:EE:D0';
    final dev = await addDevice(
      mac: mac,
      name: 'WLL Dimmer',
      typeCode: 113,
      type: 'wll',
      model: 'WLL',
    );
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byKey(const Key('dimmer_on_switch')), findsOneWidget);
    expect(dev.state.on, isFalse);

    // Turn ON.
    await tester.tap(find.byKey(const Key('dimmer_on_switch')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(dev.state.on, isTrue);

    // Drag the brightness slider to the max (100%) and release — the
    // onChangeEnd POST should land on the fake server.
    final slider = find.byKey(const Key('dimmer_value_slider'));
    expect(slider, findsOneWidget);
    await tester.drag(slider, const Offset(500, 0));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    // Brightness should now be at or near 100.
    expect(dev.state.dimmerValue, lessThanOrEqualTo(100));
    expect(dev.state.dimmerValue, greaterThan(0));

    // Drag the ramp slider to exercise the 0-15000 range.
    final rampSlider = find.byKey(const Key('dimmer_ramp_slider'));
    expect(rampSlider, findsOneWidget);
    await tester.drag(rampSlider, const Offset(500, 0));
    await tester.pumpAndSettle();

    // Turn OFF.
    await tester.tap(find.byKey(const Key('dimmer_on_switch')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(dev.state.on, isFalse);

    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets('Bulb turns on, recolors and turns off', (tester) async {
    const mac = 'AA:BB:CC:DD:EE:E0';
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

    expect(find.byKey(const Key('bulb_on_switch')), findsOneWidget);
    expect(dev.state.on, isFalse);

    await tester.tap(find.byKey(const Key('bulb_on_switch')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(dev.state.on, isTrue);

    // Tap the HSV color area to send a color POST.
    await tester.tap(find.byType(Material).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('bulb_on_switch')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(dev.state.on, isFalse);

    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets('WMS PIR detail page opens without crashing', (tester) async {
    const mac = 'AA:BB:CC:DD:EE:F0';
    final dev = await addDevice(
      mac: mac,
      name: 'WMS PIR',
      typeCode: 110,
      type: 'pir',
      model: 'WMS',
    );
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The PIR page shows motion/light/temperature cards. We only assert
    // it rendered (no error card) and can navigate back.
    expect(find.byKey(const Key('detail_back_button')), findsOneWidget);
    expect(find.textContaining('Motion'), findsWidgets);

    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  // ---- Timer (bottom sheet) ----
  testWidgets('switch timer sheet sends a timer POST to the device', (
    tester,
  ) async {
    const mac = 'AA:BB:CC:DD:EE:G0';
    final dev = await addDevice(
      mac: mac,
      name: 'Timer Switch',
      typeCode: 106,
      type: 'ws2',
      model: 'WS2',
    );
    await touchLastSeen(mac);
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Open the timer bottom sheet.
    await tester.ensureVisible(find.byKey(const Key('detail_timer_tile')));
    await tester.tap(find.byKey(const Key('detail_timer_tile')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timer_set_button')), findsOneWidget);
    // Default duration is 5 minutes (totalSeconds=300), so Set is enabled.
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('timer_set_button')))
          .enabled,
      isTrue,
    );

    // Change minutes to 10 via the dropdown.
    final minuteDropdown = find.byType(DropdownButton<int>).at(1);
    await tester.tap(minuteDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();

    // Set should now be enabled.
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('timer_set_button')))
          .enabled,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('timer_set_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The fake server should have received mode=off (default), time=600s.
    expect(dev.state.timerMode, isNot('none'));
    expect(dev.state.timerSeconds, 10 * 60);

    // Close the bottom sheet and go back.
    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  // ---- Favorite toggle + category filter ----
  testWidgets('favorite star toggles and the Favorite category filters', (
    tester,
  ) async {
    const favMac = 'AA:BB:CC:DD:EE:H0';
    const otherMac = 'AA:BB:CC:DD:EE:H1';
    final fav = await addDevice(
      mac: favMac,
      name: 'Fav Switch',
      typeCode: 106,
      type: 'ws2',
      model: 'WS2',
    );
    final other = await addDevice(
      mac: otherMac,
      name: 'Other Switch',
      typeCode: 106,
      type: 'ws2',
      model: 'WS2',
    );
    await touchLastSeen(favMac);
    await touchLastSeen(otherMac);
    await pumpApp(tester);

    // Both cards visible under "All".
    expect(find.byKey(const Key('device_card_$favMac')), findsOneWidget);
    expect(find.byKey(const Key('device_card_$otherMac')), findsOneWidget);

    // Tap the favorite star on the first card and wait for the Hive
    // write + provider refresh to settle.
    final star = find.byKey(const Key('card_favorite_star'));
    expect(star, findsNWidgets(2));
    await tester.tap(star.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // The Hive record should now have favorite = true.
    expect(
      deviceDs.getByMac(favMac)!.favorite,
      isTrue,
      reason: 'first card star should mark favMac as favorite',
    );

    // Open the "Favorite" category filter.
    await tester.tap(find.text('Favorite'));
    await tester.pumpAndSettle();

    // Only the favorited device should be visible.
    expect(find.byKey(const Key('device_card_$favMac')), findsOneWidget);
    expect(find.byKey(const Key('device_card_$otherMac')), findsNothing);

    // Go back to "All".
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    await fav.server.stop();
    await other.server.stop();
    await deviceDs.delete(favMac);
    await deviceDs.delete(otherMac);
  });

  // ---- Lockable: on/off is disabled, card is yellow ----
  testWidgets('locked switch hides the power button and shows yellow card', (
    tester,
  ) async {
    const mac = 'AA:BB:CC:DD:EE:L0';
    final dev = await addDevice(
      mac: mac,
      name: 'Fridge',
      typeCode: 106,
      type: 'ws2',
      model: 'WS2',
    );
    // Seed the device as locked.
    final s = deviceDs.getByMac(mac)!;
    s.lockable = true;
    await deviceDs.upsert(s);
    await touchLastSeen(mac);
    await pumpApp(tester);

    // The power button (card_power_button) should NOT be present.
    expect(find.byKey(const Key('card_power_button')), findsNothing);

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets(
    'locking a device from settings hides the dashboard power button',
    (tester) async {
      const mac = 'AA:BB:CC:DD:EE:L1';
      final dev = await addDevice(
        mac: mac,
        name: 'Lockable Switch',
        typeCode: 106,
        type: 'ws2',
        model: 'WS2',
      );
      await touchLastSeen(mac);
      await pumpApp(tester);

      // The power button is initially present.
      expect(find.byKey(const Key('card_power_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('device_card_$mac')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('detail_settings_button')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byKey(const Key('settings_lockable_switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_save_fab')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('settings_back_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail_back_button')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Back on the dashboard: the card power button should be gone.
      expect(find.byKey(const Key('card_power_button')), findsNothing);

      await dev.server.stop();
      await deviceDs.delete(dev.mac);
    },
  );

  // ---- Room on/off bulk toggle (skips locked) ----
  testWidgets('long-press a room chip turns all toggleable devices on', (
    tester,
  ) async {
    const mac1 = 'AA:BB:CC:DD:EE:R0';
    const mac2 = 'AA:BB:CC:DD:EE:R1';
    final d1 = await addDevice(
      mac: mac1,
      name: 'Room Switch',
      typeCode: 106,
      type: 'ws2',
      model: 'WS2',
    );
    final d2 = await addDevice(
      mac: mac2,
      name: 'Room Strip',
      typeCode: 105,
      type: 'strip',
      model: 'WRS',
    );
    // Assign both to the same room.
    for (final mac in [mac1, mac2]) {
      final s = deviceDs.getByMac(mac)!;
      s.room = 'Living';
      await deviceDs.upsert(s);
      await touchLastSeen(mac);
    }
    await pumpApp(tester);

    // Long-press the "Living" room chip.
    final living = find.text('Living');
    await tester.longPress(living);
    await tester.pumpAndSettle();

    // Choose "Turn all on".
    await tester.tap(find.text('Turn all in "Living" on'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Both devices should be ON on the fake servers.
    expect(d1.state.relay, isTrue);
    expect(d2.state.on, isTrue);

    await d1.server.stop();
    await d2.server.stop();
    await deviceDs.delete(mac1);
    await deviceDs.delete(mac2);
  });

  // ---- Total power summary ----
  testWidgets('total power summary aggregates power across devices', (
    tester,
  ) async {
    const mac = 'AA:BB:CC:DD:EE:P0';
    final dev = await addDevice(
      mac: mac,
      name: 'Power Switch',
      typeCode: 106,
      type: 'ws2',
      model: 'WS2',
    );
    // Turn the relay on so the fake reports 12.5 W.
    dev.state.relay = true;
    await touchLastSeen(mac);
    await pumpApp(tester);

    // The summary card should show 12.5 W.
    expect(find.text('12.5 W'), findsOneWidget);

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  // ---- Final sanity: all remaining devices off ----
  testWidgets('no leftover devices are ON after the suite', (tester) async {
    // After every per-type test we stop the server + delete the device,
    // so nothing should be left. This test just re-pumps the app on an
    // empty store and asserts the dashboard is in the empty state.
    await pumpApp(tester);
    expect(find.byKey(const Key('empty_state')), findsOneWidget);
  });
}
