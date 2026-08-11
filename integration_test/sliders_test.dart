// Sliders, tabs and dropdown integration tests.
//
// Exercises the remaining interactive controls: strip/bulb color tabs,
// WRGB sliders (0-255), whites sliders (1-18 white + 0-100 brightness),
// ramp sliders (0-40950), timer mode dropdown, scheduler action
// dropdown and the scene editor action picker (device dropdown + action
// chips + Add).
//
// Run on Windows desktop:
//   flutter test integration_test/sliders_test.dart -d windows

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
    tmpHiveDir = await Directory.systemTemp.createTemp('mystrom_sli_hive_');
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

  Future<void> touchLastSeen(String mac) async {
    final d = deviceDs.getByMac(mac)!..lastSeen = DateTime.now();
    await d.save();
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

  testWidgets('strip WRGB sliders send color POST on release', (tester) async {
    const mac = 'AA:BB:CC:DD:EE:S0';
    final dev = await addDevice(
      mac: mac,
      name: 'WRS Sliders',
      typeCode: 105,
      type: 'strip',
      model: 'WRS',
    );
    await touchLastSeen(mac);
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Switch to the WRGB tab.
    await tester.tap(find.byKey(const Key('strip_tab_wrgb')));
    await tester.pumpAndSettle();

    // Drag the Red slider to the max and release (onChangeEnd fires the
    // debounced color POST).
    final red = find.byKey(const Key('strip_wrgb_red'));
    expect(red, findsOneWidget);
    await tester.drag(red, const Offset(500, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // A color POST should have landed; the server color is an 8-hex WRGB
    // string when mode is rgb.
    expect(dev.state.mode, anyOf('rgb', 'hsv'));
    expect(dev.state.color, isNotEmpty);

    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();
    await dev.server.stop();
  });

  testWidgets('strip whites sliders send mono color POST', (tester) async {
    const mac = 'AA:BB:CC:DD:EE:S1';
    final dev = await addDevice(
      mac: mac,
      name: 'WRS Whites',
      typeCode: 105,
      type: 'strip',
      model: 'WRS',
    );
    await touchLastSeen(mac);
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('strip_tab_whites')));
    await tester.pumpAndSettle();

    final white = find.byKey(const Key('strip_whites_white'));
    expect(white, findsOneWidget);
    await tester.drag(white, const Offset(200, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    final brightness = find.byKey(const Key('strip_whites_brightness'));
    expect(brightness, findsOneWidget);
    await tester.drag(brightness, const Offset(300, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // The mono color POST should set mode=mono.
    expect(dev.state.mode, 'mono');

    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();
    await dev.server.stop();
  });

  testWidgets('strip ramp slider stays within 0-15000', (tester) async {
    const mac = 'AA:BB:CC:DD:EE:S2';
    final dev = await addDevice(
      mac: mac,
      name: 'WRS Ramp',
      typeCode: 105,
      type: 'strip',
      model: 'WRS',
    );
    await touchLastSeen(mac);
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The ramp slider is visible directly in the body (not in a tab).
    final sliders = find.byType(Slider);
    expect(sliders, findsWidgets);

    // Drag the first slider (ramp) all the way right.
    await tester.drag(sliders.first, const Offset(500, 0));
    await tester.pumpAndSettle();

    // Toggle on so a POST carrying ramp lands on the server.
    await tester.tap(find.byKey(const Key('strip_on_switch')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(dev.state.on, isTrue);
    expect(dev.state.ramp, lessThanOrEqualTo(15000));

    // Turn off.
    await tester.tap(find.byKey(const Key('strip_on_switch')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();
    await dev.server.stop();
  });

  testWidgets('bulb WRGB sliders send color POST on release', (tester) async {
    const mac = 'AA:BB:CC:DD:EE:S3';
    final dev = await addDevice(
      mac: mac,
      name: 'Bulb Sliders',
      typeCode: 102,
      type: 'bulb',
      model: 'Bulb',
    );
    await touchLastSeen(mac);
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('bulb_tab_wrgb')));
    await tester.pumpAndSettle();

    final blue = find.byKey(const Key('bulb_wrgb_blue'));
    expect(blue, findsOneWidget);
    await tester.drag(blue, const Offset(500, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    expect(dev.state.color, isNotEmpty);

    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();
    await dev.server.stop();
  });

  testWidgets('bulb whites sliders send mono color POST', (tester) async {
    const mac = 'AA:BB:CC:DD:EE:S4';
    final dev = await addDevice(
      mac: mac,
      name: 'Bulb Whites',
      typeCode: 102,
      type: 'bulb',
      model: 'Bulb',
    );
    await touchLastSeen(mac);
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('bulb_tab_whites')));
    await tester.pumpAndSettle();

    final white = find.byKey(const Key('bulb_whites_white'));
    await tester.drag(white, const Offset(200, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    final brightness = find.byKey(const Key('bulb_whites_brightness'));
    await tester.drag(brightness, const Offset(300, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    expect(dev.state.mode, 'mono');

    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();
    await dev.server.stop();
  });

  testWidgets('timer mode dropdown changes the posted mode', (tester) async {
    const mac = 'AA:BB:CC:DD:EE:S5';
    final dev = await addDevice(
      mac: mac,
      name: 'Timer Drop',
      typeCode: 106,
      type: 'ws2',
      model: 'WS2',
    );
    await touchLastSeen(mac);
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('device_card_$mac')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.ensureVisible(find.byKey(const Key('detail_timer_tile')));
    await tester.tap(find.byKey(const Key('detail_timer_tile')));
    await tester.pumpAndSettle();

    // Change the mode to "on".
    await tester.tap(find.byKey(const Key('timer_mode_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('On').last);
    await tester.pumpAndSettle();

    // Set minutes to 2.
    final minuteDropdown = find.byType(DropdownButton<int>).at(1);
    await tester.tap(minuteDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('02').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('timer_set_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(dev.state.timerMode, 'on');
    expect(dev.state.timerSeconds, 2 * 60);

    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();
    await dev.server.stop();
  });

  testWidgets('scheduler action dropdown changes the action', (tester) async {
    const mac = 'AA:BB:CC:DD:EE:S6';
    final dev = await addDevice(
      mac: mac,
      name: 'Sched Drop',
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

    // Change the action to "off".
    await tester.tap(find.byKey(const Key('scheduler_action_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('off').last);
    await tester.pumpAndSettle();

    // Add the entry and save.
    await tester.tap(find.byKey(const Key('scheduler_add_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scheduler_save_fab')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(dev.state.scheduler.length, 1);
    expect(dev.state.scheduler.first['action'], 'off');

    await tester.tap(find.byKey(const Key('scheduler_back_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail_back_button')));
    await tester.pumpAndSettle();
    await dev.server.stop();
  });

  testWidgets('scene editor action picker picks device + action and adds', (
    tester,
  ) async {
    const mac = 'AA:BB:CC:DD:EE:S7';
    final dev = await addDevice(
      mac: mac,
      name: 'Scene Drop',
      typeCode: 106,
      type: 'ws2',
      model: 'WS2',
    );
    await touchLastSeen(mac);
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('scene_add_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('scene_name_field')),
      'Action scene',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Open the Add device action dialog.
    await tester.tap(find.widgetWithText(FilledButton, 'Add device action'));
    await tester.pumpAndSettle();

    // Pick the device in the dropdown.
    await tester.tap(find.byKey(const Key('scene_action_device_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scene Drop').last);
    await tester.pumpAndSettle();

    // Choose the "on" action chip.
    await tester.tap(find.byKey(const Key('scene_action_chip_on')));
    await tester.pumpAndSettle();

    // Add the action.
    await tester.tap(find.byKey(const Key('scene_action_add_button')));
    await tester.pumpAndSettle();

    // The action tile should now appear; save the scene.
    await tester.scrollUntilVisible(
      find.byKey(const Key('scene_save_fab')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const Key('scene_save_fab')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Action scene'), findsWidgets);

    await dev.server.stop();
  });

  testWidgets('final sanity: dashboard empty after suite', (tester) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('empty_state')), findsOneWidget);
  });
}
