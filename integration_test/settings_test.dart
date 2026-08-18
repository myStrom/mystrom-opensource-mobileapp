// Settings & dialog integration tests.
//
// Covers the remaining UI flows not exercised by the smoke/control/devices
// suites: device removal, color palette, scheduler discard-changes
// dialog, scene editor discard-changes dialog, strip channel-mode page
// and button action URL picker (smoke).
//
// Run on Windows desktop:
//   flutter test integration_test/settings_test.dart -d windows

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

  setUpAll(() async {
    tmpHiveDir = await Directory.systemTemp.createTemp('mystrom_set_hive_');
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

  /// Clean the Hive box after every test so the final sanity test sees
  /// an empty store regardless of which earlier tests left devices behind.
  tearDown(() async {
    for (final d in deviceDs.getAll()) {
      await deviceDs.delete(d.mac);
    }
  });

  /// Spin up a fake server + seed Hive for one device.
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

  Future<void> touchLastSeen(String mac) async {
    final d = deviceDs.getByMac(mac)!..lastSeen = DateTime.now();
    await d.save();
  }

  testWidgets('remove device deletes it from Hive and dashboard', (
    tester,
  ) async {
    const mac = 'AA:BB:CC:DD:EE:I0';
    final dev = await addDevice(
      mac: mac,
      name: 'Remove Me',
      typeCode: 106,
      type: 'ws2',
      model: 'WS2',
    );
    await pumpApp(tester);

    // Open the detail page then settings.
    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('detail_settings_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The remove button sits at the bottom of the settings ListView.
    // Scroll it into view before tapping.
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_remove_button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('settings_remove_button')), findsOneWidget);

    // Tap remove. removeDevice + Navigator.pop return to the dashboard,
    // and the card should disappear.
    await tester.tap(find.byKey(const Key('settings_remove_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The device must no longer be in Hive.
    expect(deviceDs.getByMac(mac), isNull);
    expect(find.byKey(const Key('device_card_$mac')), findsNothing);

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets('color palette selection persists to Hive on save', (
    tester,
  ) async {
    const mac = 'AA:BB:CC:DD:EE:J0';
    final dev = await addDevice(
      mac: mac,
      name: 'Color Me',
      typeCode: 106,
      type: 'ws2',
      model: 'WS2',
    );
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('detail_settings_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The color palette should render a set of circles.
    final palette = find.byKey(const Key('settings_color_palette'));
    expect(palette, findsOneWidget);
    // Tap the third circle in the palette (any non-null color).
    final circles = find.descendant(
      of: palette,
      matching: find.byType(GestureDetector),
    );
    expect(circles, findsWidgets);
    await tester.tap(circles.at(3));
    await tester.pumpAndSettle();

    // Save.
    await tester.tap(find.byKey(const Key('settings_save_fab')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The Hive record should now carry a non-null colorValue.
    final stored = deviceDs.getByMac(mac)!;
    expect(stored.colorValue, isNotNull);

    await tester.tap(find.byKey(const Key('settings_back_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets('scheduler discard-changes dialog keeps unsaved edits', (
    tester,
  ) async {
    const mac = 'AA:BB:CC:DD:EE:K0';
    final dev = await addDevice(
      mac: mac,
      name: 'Sched Strip',
      typeCode: 105,
      type: 'strip',
      model: 'WRS',
    );
    await touchLastSeen(mac);
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.ensureVisible(find.byKey(const Key('detail_scheduler_tile')));
    await tester.tap(find.byKey(const Key('detail_scheduler_tile')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Add a schedule entry (this marks the page dirty).
    await tester.enterText(find.byKey(const Key('scheduler_hour_field')), '6');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('scheduler_minute_field')),
      '45',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scheduler_add_button')));
    await tester.pumpAndSettle();

    // Press back — the discard dialog should appear.
    await tester.tap(find.byKey(const Key('scheduler_back_button')));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    // Cancel: we stay on the scheduler page (unsaved edits kept).
    await tester.tap(find.byKey(const Key('scheduler_discard_cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scheduler_save_fab')), findsOneWidget);

    // Confirm discard: we leave the page, and the server has no schedule.
    await tester.tap(find.byKey(const Key('scheduler_back_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scheduler_discard_confirm')));
    await tester.pumpAndSettle();
    expect(dev.state.scheduler, isEmpty);

    // Back on the detail page, then dashboard.
    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets('scene editor discard-changes dialog keeps unsaved edits', (
    tester,
  ) async {
    const mac = 'AA:BB:CC:DD:EE:L0';
    final dev = await addDevice(
      mac: mac,
      name: 'Scene Host',
      typeCode: 106,
      type: 'ws2',
      model: 'WS2',
    );
    await touchLastSeen(mac);
    await pumpApp(tester);

    // Open the scene editor.
    await tester.tap(find.byKey(const Key('scene_add_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scene_name_field')), findsOneWidget);

    // Edit the name (marks the editor dirty).
    await tester.enterText(
      find.byKey(const Key('scene_name_field')),
      'Discard me',
    );
    await tester.pumpAndSettle();

    // Press back — discard dialog appears.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    // Cancel: stay on the editor.
    await tester.tap(find.byKey(const Key('scene_discard_cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scene_name_field')), findsOneWidget);

    // Confirm discard: leave the editor; the scene should not persist.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scene_discard_confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Discard me'), findsNothing);

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets('strip channel mode page sets a new mode', (tester) async {
    const mac = 'AA:BB:CC:DD:EE:M0';
    final dev = await addDevice(
      mac: mac,
      name: 'ChMode Strip',
      typeCode: 105,
      type: 'strip',
      model: 'WRS',
    );
    await touchLastSeen(mac);
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    // The strip detail page settings button opens DeviceSettingsPage.
    await tester.tap(find.byKey(const Key('strip_settings_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    // On the settings page, the strip channel mode tile opens the
    // StripSettingsPage. Scroll it into view (it sits below the color
    // palette on the settings ListView).
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_strip_settings_tile')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('settings_strip_settings_tile')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Strip Settings'), findsOneWidget);
    expect(dev.state.chMode, 'colors');

    // Switch to "channels" mode.
    await tester.tap(find.byKey(const Key('strip_chmode_channels')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(dev.state.chMode, 'channels');

    // Switch back to "colors".
    await tester.tap(find.byKey(const Key('strip_chmode_colors')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(dev.state.chMode, 'colors');

    await tester.tap(find.byKey(const Key('strip_settings_back_button')));
    await tester.pumpAndSettle();
    // StripSettings -> DeviceSettings
    await tester.tap(find.byKey(const Key('settings_back_button')));
    await tester.pumpAndSettle();
    // DeviceSettings -> strip detail
    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets('button detail page lists action schemes and opens picker', (
    tester,
  ) async {
    const mac = 'AA:BB:CC:DD:EE:N0';
    final dev = await addDevice(
      mac: mac,
      name: 'Button',
      typeCode: 101,
      type: 'button',
      model: 'Button',
    );
    await touchLastSeen(mac);
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The button detail page lists the 5 action schemes.
    expect(find.byKey(const Key('button_scheme_single')), findsOneWidget);
    expect(find.byKey(const Key('button_scheme_double')), findsOneWidget);
    expect(find.byKey(const Key('button_scheme_long')), findsOneWidget);
    expect(find.byKey(const Key('button_scheme_touch')), findsOneWidget);
    expect(find.byKey(const Key('button_scheme_generic')), findsOneWidget);

    // Tap "single" — the ActionUrlPicker dialog opens.
    await tester.tap(find.byKey(const Key('button_scheme_single')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Assign'), findsOneWidget);

    // Close the dialog and go back.
    await tester.tap(find.text('Cancel').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();

    await dev.server.stop();
    await deviceDs.delete(dev.mac);
  });

  testWidgets('all leftover devices off after the suite', (tester) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('empty_state')), findsOneWidget);
  });
}
