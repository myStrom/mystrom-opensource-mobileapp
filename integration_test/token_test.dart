import 'dart:async';
import 'dart:convert';
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
import 'package:mystrom_local/presentation/widgets/discovered_device_card.dart';

import 'fake_mystrom_server.dart';

class _Discovery extends UdpDiscoveryService {
  final events = StreamController<List<DiscoveredDevice>>.broadcast();
  @override
  Stream<List<DiscoveredDevice>> get devices => events.stream;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late DeviceLocalDataSource devices;
  late SceneLocalDataSource scenes;
  late _Discovery discovery;
  late FakeMystromServer server;
  late FakeDeviceState state;
  late String host;
  const mac = 'AA:BB:CC:DD:EE:01';

  setUpAll(() {
    Hive.registerAdapter(StoredDeviceAdapter());
    Hive.registerAdapter(SceneAdapter());
    Hive.registerAdapter(SceneActionAdapter());
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('device_token_test_');
    Hive.init(directory.path);
    devices = DeviceLocalDataSource();
    await devices.init();
    scenes = SceneLocalDataSource();
    await scenes.init();
    discovery = _Discovery();
    server = FakeMystromServer();
    await server.start();
    host = '${server.host}:${server.port}';
    state = server.register(
      FakeDeviceState(mac: mac, type: 'ws2', model: 'WS2', version: 'test'),
    );
    await devices.upsert(
      StoredDevice(
        mac: mac,
        name: 'Token fixture',
        typeCode: 106,
        lastKnownIp: host,
        lastSeen: DateTime.now(),
        addedAt: DateTime(2026),
      ),
    );
  });
  tearDown(() async {
    await server.stop();
    await discovery.events.close();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        locale: const Locale('en'),
        discoveryService: discovery,
        localDataSource: devices,
        sceneDataSource: scenes,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> waitFor(WidgetTester tester, bool Function() condition) async {
    for (var i = 0; i < 100 && !condition(); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(condition(), isTrue);
  }

  Future<void> until(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsOneWidget);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tap(tester, 'device_card_$mac');
    await until(tester, find.byKey(const Key('switch_power_card')));
    await tap(tester, 'detail_settings_button');
    await tester.pumpAndSettle();
  }

  Future<void> typeIn(WidgetTester tester, Finder finder, String value) async {
    tester.binding.focusedEditable = null;
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
    await tester.enterText(finder, value);
    await tester.pump();
    expect(tester.widget<TextField>(finder).controller!.text, value);
  }

  Future<void> setToken(WidgetTester tester, String token) async {
    final field = find.byKey(const Key('settings_token_field'));
    await tester.scrollUntilVisible(
      field,
      -150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(field);
    final controller = tester.widget<TextField>(field).controller!;
    await typeIn(tester, field, token);
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, token);
    await tap(tester, 'settings_token_apply');
    await waitFor(
      tester,
      () =>
          controller.text.isEmpty ||
          find
              .text(
                'Token change could not be confirmed. Check device access before trying again.',
              )
              .evaluate()
              .isNotEmpty,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await waitFor(
      tester,
      () =>
          tester
              .widget<FilledButton>(
                find.byKey(const Key('settings_token_apply')),
              )
              .onPressed !=
          null,
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterAuth(
    WidgetTester tester,
    String token, {
    bool remember = false,
  }) async {
    await until(tester, find.byKey(const Key('auth_token_field')));
    await typeIn(tester, find.byKey(const Key('auth_token_field')), token);
    if (remember) await tap(tester, 'auth_remember_token');
    await tap(tester, 'auth_token_submit');
  }

  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  void tokenTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        await disposeApp(tester);
      }
    });
  }

  tokenTest('settings change, rotation, removal and cold persisted read', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSettings(tester);
    await setToken(tester, 'first&+fixture');
    expect(state.token, 'first&+fixture');
    expect(devices.getByMac(mac)!.token, state.token);
    var request = server.requests.lastWhere(
      (r) => r.path == '/api/v1/settings',
    );
    expect(request.method, 'POST');
    expect(jsonDecode(request.body!), {'token': 'first&+fixture'});
    expect(request.token, isNull);
    await setToken(tester, 'rotated-fixture');
    expect(state.token, 'rotated-fixture');
    expect(devices.getByMac(mac)!.token, state.token);
    request = server.requests.lastWhere((r) => r.path == '/api/v1/settings');
    expect(request.token, 'first&+fixture');
    await disposeApp(tester);
    await Hive.close();
    await devices.init();
    await scenes.init();
    expect(devices.getByMac(mac)!.token, 'rotated-fixture');
    await pumpApp(tester);
    await openSettings(tester);
    await setToken(tester, '');
    expect(state.token, isEmpty);
    expect(devices.getByMac(mac)!.token, isNull);
    await tap(tester, 'settings_back_button');
    await tap(tester, 'switch_power_card');
    await waitFor(tester, () => state.relay);
    await tester.pumpAndSettle();
    expect(state.relay, isTrue);
    expect(server.requests.lastWhere((r) => r.path == '/relay').token, isNull);
    await disposeApp(tester);
  });

  tokenTest(
    'saved token changed externally: wrong input fails, correct input retries command',
    (tester) async {
      state.token = 'saved-before-change';
      await devices.upsert(devices.getByMac(mac)!..token = state.token);
      await pumpApp(tester);
      await tap(tester, 'device_card_$mac');
      await until(tester, find.byKey(const Key('switch_power_card')));
      state.token = 'external-new-token';
      final before = server.requests.length;
      await tap(tester, 'switch_power_card');
      await enterAuth(tester, 'saved-before-change');
      await until(
        tester,
        find.text('Token rejected or device API unavailable.'),
      );
      expect(state.relay, isFalse);
      expect(devices.getByMac(mac)!.token, 'saved-before-change');
      await enterAuth(tester, 'external-new-token', remember: true);
      await waitFor(tester, () => state.relay);
      await tester.pumpAndSettle();
      expect(state.relay, isTrue);
      expect(devices.getByMac(mac)!.token, state.token);
      final commands = server.requests
          .skip(before)
          .where((r) => r.path == '/relay')
          .toList();
      expect(commands, hasLength(2));
      expect(commands.first.token, 'saved-before-change');
      expect(commands.last.token, 'external-new-token');
      expect(commands.last.method, 'GET');
      expect(commands.last.query, {'state': '1'});
      await disposeApp(tester);
    },
  );

  tokenTest(
    'wrong saved token can be corrected for this session without saving',
    (tester) async {
      state.token = 'correct-token';
      await devices.upsert(devices.getByMac(mac)!..token = 'wrong-saved-token');
      await pumpApp(tester);
      await tap(tester, 'device_card_$mac');
      await enterAuth(tester, 'wrong-input');
      await until(
        tester,
        find.text('Token rejected or device API unavailable.'),
      );
      await enterAuth(tester, 'correct-token');
      await waitFor(
        tester,
        () => find.byKey(const Key('auth_token_field')).evaluate().isEmpty,
      );
      await tester.pumpAndSettle();
      await tap(tester, 'switch_power_card');
      await waitFor(tester, () => state.relay);
      await tester.pumpAndSettle();
      expect(state.relay, isTrue);
      expect(devices.getByMac(mac)!.token, 'wrong-saved-token');
      await disposeApp(tester);
      await pumpApp(tester);
      await tap(tester, 'device_card_$mac');
      await until(tester, find.byKey(const Key('auth_token_field')));
      await tester.tap(find.text('Cancel'));
      await waitFor(tester, () => state.relay);
      await tester.pumpAndSettle();
      expect(state.relay, isTrue);
      await disposeApp(tester);
    },
  );

  tokenTest('settings rejection or ignored write never reports success', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSettings(tester);
    state.rejectTokenChange = true;
    await setToken(tester, 'rejected-token');
    expect(find.text('Device token updated and saved'), findsNothing);
    expect(state.token, isEmpty);
    expect(devices.getByMac(mac)!.token, isNull);
    state.rejectTokenChange = false;
    state.ignoreTokenChange = true;
    await setToken(tester, 'ignored-token');
    expect(find.text('Device token updated and saved'), findsNothing);
    expect(state.token, isEmpty);
    expect(devices.getByMac(mac)!.token, isNull);
    await disposeApp(tester);
  });

  tokenTest('device rejection shows a short error and leaves relay unchanged', (
    tester,
  ) async {
    await pumpApp(tester);
    await tap(tester, 'device_card_$mac');
    await until(tester, find.byKey(const Key('switch_power_card')));
    server.responseStatuses['/relay'] = 503;
    final before = server.requests.length;
    await tap(tester, 'switch_power_card');
    await until(
      tester,
      find.text('The device is temporarily unavailable. Try again.'),
    );
    expect(state.relay, isFalse);
    final commands = server.requests
        .skip(before)
        .where((r) => r.path == '/relay')
        .toList();
    expect(commands, hasLength(1));
    expect(commands.single.method, 'GET');
    expect(commands.single.query, {'state': '1'});
    expect(find.textContaining('DioException'), findsNothing);
    expect(find.textContaining('validateStatus'), findsNothing);
    expect(find.textContaining('status code'), findsNothing);
  });

  tokenTest(
    'adding without a token prompts, rejects wrong input and remembers consent',
    (tester) async {
      await devices.delete(mac);
      state.token = 'protected-fixture';
      await pumpApp(tester);
      discovery.events.add([
        DiscoveredDevice(
          mac: mac,
          ip: host,
          type: DeviceType.ws2,
          registered: false,
          cloudConnected: false,
          lastSeen: DateTime.now(),
        ),
      ]);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(DiscoveredDeviceCard),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_device_submit')));
      await enterAuth(tester, 'incorrect');
      await until(
        tester,
        find.text('Token rejected or device API unavailable.'),
      );
      expect(devices.getByMac(mac), isNull);
      await enterAuth(tester, state.token, remember: true);
      await waitFor(tester, () => devices.getByMac(mac) != null);
      expect(devices.getByMac(mac)!.token, state.token);
      await tester.pumpAndSettle();
      await tap(tester, 'device_card_$mac');
      await until(tester, find.byKey(const Key('switch_power_card')));
      await tap(tester, 'switch_power_card');
      await waitFor(tester, () => state.relay);
      expect(
        server.requests.lastWhere((r) => r.path == '/relay').token,
        state.token,
      );
    },
  );

  for (final remember in [false, true]) {
    tokenTest('adding protected device verifies token; remember=$remember', (
      tester,
    ) async {
      await devices.delete(mac);
      state.token = 'add-fixture-token';
      await pumpApp(tester);
      discovery.events.add([
        DiscoveredDevice(
          mac: mac,
          ip: host,
          type: DeviceType.ws2,
          registered: false,
          cloudConnected: false,
          lastSeen: DateTime.now(),
        ),
      ]);
      await tester.pumpAndSettle();
      final card = find.byType(DiscoveredDeviceCard);
      await tester.tap(
        find.descendant(of: card, matching: find.byType(FilledButton)),
      );
      await tester.pumpAndSettle();
      await typeIn(
        tester,
        find.byKey(const Key('add_token_field')),
        'incorrect',
      );
      await tester.tap(find.byKey(const Key('add_device_submit')));
      await until(
        tester,
        find.text('Token rejected or device API unavailable.'),
      );
      await tester.pumpAndSettle();
      expect(devices.getByMac(mac), isNull);
      expect(
        find.text('Token rejected or device API unavailable.'),
        findsOneWidget,
      );
      await typeIn(
        tester,
        find.byKey(const Key('add_token_field')),
        state.token,
      );
      if (remember) await tap(tester, 'add_remember_token');
      await tester.tap(find.byKey(const Key('add_device_submit')));
      await waitFor(tester, () => devices.getByMac(mac) != null);
      await tester.pumpAndSettle();
      expect(devices.getByMac(mac), isNotNull);
      expect(devices.getByMac(mac)!.token, remember ? state.token : null);
      await tap(tester, 'device_card_$mac');
      await until(tester, find.byKey(const Key('switch_power_card')));
      await tap(tester, 'switch_power_card');
      await waitFor(tester, () => state.relay);
      await tester.pumpAndSettle();
      expect(state.relay, isTrue);
      expect(
        server.requests.lastWhere((r) => r.path == '/relay').token,
        state.token,
      );
      await disposeApp(tester);
    });
  }
}
