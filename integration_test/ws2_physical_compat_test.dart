// Opt-in physical WS2 regression. The proxy forwards real responses unchanged;
// it is a request journal and a DUT identity guard, not a fake device.
// No OTA, reboot, Wi-Fi, credentials, history deletion or factory operations.
import 'dart:convert';
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
import 'package:mystrom_local/presentation/widgets/timer_controls.dart';

const _enabled = bool.fromEnvironment('RUN_WS2_LIVE_TESTS');
const _ip = String.fromEnvironment('WS2_LIVE_IP');
const _boot = String.fromEnvironment('WS2_EXPECTED_BOOT');
const _out = String.fromEnvironment('WS2_LIVE_OUTPUT');
const _mac = String.fromEnvironment('WS2_LIVE_MAC');

class _QuietDiscovery extends UdpDiscoveryService {
  @override
  Future<void> start() async {}
}

class _LiveDevice {
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);
  final List<Map<String, dynamic>> journal = [];
  HttpServer? proxy;

  Future<dynamic> direct(String path, {dynamic body}) async {
    final request = await client.openUrl(
      body == null ? 'GET' : 'POST',
      Uri.parse('http://$_ip$path'),
    );
    request.persistentConnection = false;
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close().timeout(const Duration(seconds: 8));
    final bytes = await response.fold<List<int>>([], (a, b) => a..addAll(b));
    if (response.statusCode != 200) {
      throw StateError(
        'Direct read/restore $path: HTTP ${response.statusCode}',
      );
    }
    if (bytes.isEmpty) return null;
    final text = utf8.decode(bytes);
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  Future<void> identity() async {
    if (_mac.isEmpty) {
      throw StateError('Pass WS2_LIVE_MAC to identify the DUT');
    }
    final system = await direct('/api/v1/system') as Map;
    if (system['device']['id'] != _mac ||
        system['device']['boot_id'] != _boot ||
        system['device']['firmware'] != '5.0.3') {
      throw StateError('DUT identity/boot/firmware changed');
    }
  }

  Future<void> start() async {
    await identity();
    proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    proxy!.listen((incoming) async {
      final record = <String, dynamic>{
        'utc': DateTime.now().toUtc().toIso8601String(),
        'method': incoming.method,
        'path': incoming.uri.path,
        'query': incoming.uri.queryParameters,
      };
      try {
        final path = incoming.uri.path;
        final mutation =
            incoming.method != 'GET' ||
            path == '/relay' ||
            path == '/toggle' ||
            (path == '/timer' && incoming.uri.hasQuery);
        if (mutation) {
          if (![
            '/relay',
            '/toggle',
            '/timer',
            '/api/v1/scheduler',
          ].contains(path)) {
            throw StateError('Disallowed mutation: $path');
          }
          await identity();
        }
        if (incoming.method == 'DELETE' ||
            path == '/load' ||
            path == '/power_cycle') {
          throw StateError('Disallowed operation');
        }
        final body = await incoming.fold<List<int>>([], (a, b) => a..addAll(b));
        record['request_content_length'] = incoming.contentLength;
        if (path == '/api/v1/scheduler' && body.isNotEmpty) {
          record['schedule_body'] = jsonDecode(utf8.decode(body));
        }
        final request = await client.openUrl(
          incoming.method,
          Uri.parse('http://$_ip${incoming.uri}'),
        );
        request.persistentConnection = false;
        incoming.headers.forEach((name, values) {
          if (![
            'host',
            'connection',
            'content-length',
            'transfer-encoding',
          ].contains(name.toLowerCase())) {
            request.headers.set(name, values);
          }
        });
        // Dio sends JSON with Content-Length. The journal must preserve that
        // framing rather than introducing a chunked POST unsupported by WS2.
        if (body.isNotEmpty || incoming.contentLength >= 0) {
          request.contentLength = body.length;
        }
        request.add(body);
        final response = await request.close().timeout(
          const Duration(seconds: 8),
        );
        final bytes = await response.fold<List<int>>(
          [],
          (a, b) => a..addAll(b),
        );
        record['status'] = response.statusCode;
        if (path == '/api/v1/history' && response.statusCode == 200) {
          record['history_response'] = jsonDecode(utf8.decode(bytes));
        }
        incoming.response.statusCode = response.statusCode;
        incoming.response.persistentConnection = false;
        if (response.headers.contentType != null) {
          incoming.response.headers.contentType = response.headers.contentType;
        }
        incoming.response.add(bytes);
        await incoming.response.close();
      } catch (error) {
        record['error_type'] = error.runtimeType.toString();
        record['error'] = error.toString();
        incoming.response.statusCode = 502;
        await incoming.response.close();
      } finally {
        journal.add(record);
      }
    });
  }

  List<Map<String, dynamic>> calls(String path, {String? method}) => journal
      .where(
        (r) => r['path'] == path && (method == null || r['method'] == method),
      )
      .toList();

  Future<void> close() async {
    await proxy?.close(force: true);
    client.close(force: true);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'physical WS2: controls, timer, history, scheduler save/read/execute/delete',
    (tester) async {
      expect(_ip, isNotEmpty);
      expect(_boot, isNotEmpty);
      expect(_out, isNotEmpty);
      final output = Directory(_out)..createSync(recursive: true);
      expect(
        File('${output.path}/result.json').existsSync(),
        isFalse,
        reason: 'Use a fresh output directory; no silent retry',
      );
      final device = _LiveDevice();
      final result = <String, dynamic>{
        'status': 'RUNNING',
        'started_utc': DateTime.now().toUtc().toIso8601String(),
        'platform': Platform.operatingSystem,
        'physical_device': true,
        'phone_validation': false,
        'checks': <String>[],
      };
      dynamic initialSchedule;
      var hiveStarted = false;
      final discovery = _QuietDiscovery();
      void checkpoint() => File(
        '${output.path}/result.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
      // IntegrationTest uses the live binding: propagate I/O errors immediately.
      Future<T> io<T>(Future<T> Function() operation) => operation();
      Future<void> waitFor(
        bool Function() condition, {
        int seconds = 20,
      }) async {
        final end = DateTime.now().add(Duration(seconds: seconds));
        while (!condition()) {
          expect(
            DateTime.now().isBefore(end),
            isTrue,
            reason: 'UI/request timeout',
          );
          await tester.pump();
          await io(
            () => Future<void>.delayed(const Duration(milliseconds: 150)),
          );
          expect(tester.takeException(), isNull);
        }
        await tester.pump();
      }

      Future<dynamic> read(String path) async => io(() => device.direct(path));
      Future<void> tapKey(String key) async {
        final finder = find.byKey(Key(key));
        await waitFor(() => finder.evaluate().isNotEmpty);
        await tester.ensureVisible(finder);
        await tester.pump();
        await tester.tap(finder);
        await tester.pump();
        await io(() => Future<void>.delayed(const Duration(milliseconds: 250)));
        await tester.pump();
      }

      Future<void> checkRelay(bool value, {int seconds = 12}) async {
        final end = DateTime.now().add(Duration(seconds: seconds));
        while (true) {
          final report = await read('/report') as Map;
          if (report['relay'] == value) return;
          expect(
            DateTime.now().isBefore(end),
            isTrue,
            reason: 'Physical relay state',
          );
          await tester.pump();
          await io(
            () => Future<void>.delayed(const Duration(milliseconds: 250)),
          );
        }
      }

      checkpoint();
      try {
        await io(() => device.start());
        initialSchedule = await read('/api/v1/scheduler');
        expect(
          initialSchedule,
          isEmpty,
          reason: 'Never overwrite an existing user schedule',
        );
        expect((await read('/report') as Map)['relay'], false);
        final settingsBefore = await read('/api/v1/settings');
        final mqttBefore = await read('/api/v1/mqtt/settings');
        Hive.init('${output.path}/hive');
        Hive.registerAdapter(StoredDeviceAdapter());
        Hive.registerAdapter(SceneAdapter());
        Hive.registerAdapter(SceneActionAdapter());
        final local = DeviceLocalDataSource();
        final scenes = SceneLocalDataSource();
        await io(() async {
          await local.init();
          await scenes.init();
        });
        hiveStarted = true;
        await io(
          () => local.upsert(
            StoredDevice(
              mac: _mac,
              name: 'WS2 physical release',
              typeCode: 106,
              lastKnownIp: '127.0.0.1:${device.proxy!.port}',
              lastSeen: DateTime.now(),
              addedAt: DateTime.now(),
            ),
          ),
        );
        await tester.pumpWidget(
          MyApp(
            locale: const Locale('en'),
            discoveryService: discovery,
            localDataSource: local,
            sceneDataSource: scenes,
          ),
        );
        await tapKey('device_card_$_mac');
        await waitFor(
          () =>
              find.byKey(const Key('switch_power_card')).evaluate().isNotEmpty,
        );
        var mark = device.journal.length;
        await tapKey('switch_power_card');
        await checkRelay(true);
        expect(
          device.journal
              .skip(mark)
              .any(
                (r) =>
                    r['path'] == '/relay' &&
                    r['method'] == 'GET' &&
                    (r['query'] as Map)['state'] == '1',
              ),
          true,
        );
        mark = device.journal.length;
        await tapKey('switch_power_card');
        await checkRelay(false);
        expect(
          device.journal
              .skip(mark)
              .any(
                (r) =>
                    r['path'] == '/relay' &&
                    r['method'] == 'GET' &&
                    (r['query'] as Map)['state'] == '0',
              ),
          true,
        );
        (result['checks'] as List).add(
          'UI on/off + new real HTTP + independent physical readback',
        );
        checkpoint();

        await tapKey('detail_timer_tile');
        await tester.tap(find.byKey(const Key('timer_mode_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('On').last);
        await tester.pumpAndSettle();
        final ints = find.descendant(
          of: find.byType(TimerControls),
          matching: find.byType(DropdownButton<int>),
        );
        await tester.tap(ints.at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('00').last);
        await tester.pumpAndSettle();
        await tester.tap(ints.at(2));
        await tester.pumpAndSettle();
        await tester.tap(find.text('05').last);
        await tester.pumpAndSettle();
        mark = device.journal.length;
        await tapKey('timer_set_button');
        await checkRelay(true);
        expect(
          device.journal
              .skip(mark)
              .any(
                (r) =>
                    r['path'] == '/timer' &&
                    r['method'] == 'POST' &&
                    (r['query'] as Map)['mode'] == 'on' &&
                    (r['query'] as Map)['time'] == '5',
              ),
          true,
        );
        await checkRelay(false, seconds: 12);
        (result['checks'] as List).add(
          'UI timer 5s: fresh command, ON and automatic OFF',
        );
        checkpoint();
        // Timer success closes the sheet; dismiss it if still visible.
        if (find.byType(TimerControls).evaluate().isNotEmpty) {
          await tester.tapAt(const Offset(12, 70));
          await tester.pumpAndSettle();
        }

        mark = device.calls('/api/v1/history').length;
        await tapKey('detail_history_tile');
        await waitFor(
          () =>
              find.byKey(const Key('history_date_label')).evaluate().isNotEmpty,
        );
        expect(device.calls('/api/v1/history').length, greaterThan(mark));
        expect(find.text('Total Energy'), findsOneWidget);
        expect(find.text('Intervals'), findsOneWidget);
        final rows = device
            .calls('/api/v1/history')
            .skip(mark)
            .expand((r) => ((r['history_response'] as Map)['records'] as List))
            .cast<Map>()
            .toList();
        expect(rows.length, greaterThan(2));
        rows.sort((a, b) => (a['t'] as String).compareTo(b['t'] as String));
        final newestDay = (rows.last['t'] as String).substring(0, 10);
        final dayRows = rows
            .where((r) => (r['t'] as String).startsWith(newestDay))
            .toList();
        expect(dayRows.length, greaterThan(2));
        final expectedKwh = <double>[
          for (var i = 1; i < dayRows.length; i++)
            ((dayRows[i]['e'] as num) - (dayRows[i - 1]['e'] as num)) / 3600000,
        ];
        final paints = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where(
              (w) => w.painter.runtimeType.toString() == '_EnergyChartPainter',
            )
            .toList();
        expect(paints, hasLength(1));
        final actualIntervals =
            (paints.single.painter as dynamic).intervals as List;
        expect(actualIntervals.length, expectedKwh.length);
        for (var i = 0; i < expectedKwh.length; i++) {
          expect(
            (actualIntervals[i] as dynamic).kwh as double,
            closeTo(expectedKwh[i], 1e-9),
          );
        }
        result['history_records'] = rows.length;
        result['history_day_intervals'] = actualIntervals.length;
        final dateBefore = tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const Key('history_date_label')),
                matching: find.byType(Text),
              ),
            )
            .data;
        final prev = tester.widget<IconButton>(
          find.byKey(const Key('history_prev_day')),
        );
        expect(prev.onPressed, isNotNull);
        await tapKey('history_prev_day');
        expect(
          tester
              .widget<Text>(
                find.descendant(
                  of: find.byKey(const Key('history_date_label')),
                  matching: find.byType(Text),
                ),
              )
              .data,
          isNot(dateBefore),
        );
        await tapKey('history_today');
        expect(
          tester
              .widget<Text>(
                find.descendant(
                  of: find.byKey(const Key('history_date_label')),
                  matching: find.byType(Text),
                ),
              )
              .data,
          dateBefore,
        );
        (result['checks'] as List).add(
          'UI history: fresh real pages, chart intervals/kWh and date navigation; no deletion',
        );
        await tapKey('history_back_button');
        checkpoint();

        final system = await read('/api/v1/system') as Map;
        final now = DateTime.parse(
          system['device']['date_time_utc'] as String,
        ).toUtc();
        expect(
          now.difference(DateTime.now().toUtc()).inSeconds.abs(),
          lessThanOrEqualTo(5),
        );
        final on = DateTime.utc(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute,
        ).add(const Duration(minutes: 2));
        final off = on.add(const Duration(minutes: 1));
        result['schedule_targets_utc'] = [
          on.toIso8601String(),
          off.toIso8601String(),
        ];
        result['app_timezone_offset_minutes'] =
            DateTime.now().timeZoneOffset.inMinutes;
        await tapKey('detail_scheduler_tile');
        await waitFor(
          () => find
              .byKey(const Key('scheduler_hour_field'))
              .evaluate()
              .isNotEmpty,
        );
        for (final target in [on, off]) {
          final localTime = target.toLocal();
          await tester.ensureVisible(
            find.byKey(const Key('scheduler_hour_field')),
          );
          await tester.enterText(
            find.byKey(const Key('scheduler_hour_field')),
            '${localTime.hour}',
          );
          await tester.enterText(
            find.byKey(const Key('scheduler_minute_field')),
            '${localTime.minute}',
          );
          if (target == off) {
            await tester.ensureVisible(
              find.byKey(const Key('scheduler_action_dropdown')),
            );
            await tester.tap(
              find.byKey(const Key('scheduler_action_dropdown')),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.text('off').last);
            await tester.pumpAndSettle();
          }
          await tapKey('scheduler_add_button');
        }
        mark = device.calls('/api/v1/scheduler', method: 'POST').length;
        await tapKey('scheduler_save_fab');
        await waitFor(
          () => device.calls('/api/v1/scheduler', method: 'POST').length > mark,
        );
        final posted =
            device
                    .calls('/api/v1/scheduler', method: 'POST')
                    .last['schedule_body']
                as List;
        final saved = await read('/api/v1/scheduler') as List;
        expect(saved, hasLength(2));
        expect(posted, hasLength(2));
        for (var i = 0; i < 2; i++) {
          final target = [on, off][i];
          expect((posted[i] as Map)['hour'], target.hour);
          expect((posted[i] as Map)['minute'], target.minute);
          expect((posted[i] as Map)['action'], i == 0 ? 'on' : 'off');
          expect((saved[i] as Map)['hour'], target.hour);
          expect((saved[i] as Map)['minute'], target.minute);
          expect((saved[i] as Map)['days'], hasLength(7));
        }
        await tapKey('scheduler_back_button');
        await tapKey('detail_scheduler_tile');
        await waitFor(
          () => find
              .byKey(
                ValueKey(
                  'item-1-${off.toLocal().hour}-${off.toLocal().minute}',
                ),
              )
              .evaluate()
              .isNotEmpty,
        );
        (result['checks'] as List).add(
          'UI scheduler add/save/reopen; independent UTC payload and canonical readback',
        );
        checkpoint();
        for (final target in [on, off]) {
          final end = target.add(const Duration(seconds: 10));
          while (true) {
            final s = await read('/api/v1/system') as Map;
            final time = DateTime.parse(
              s['device']['date_time_utc'] as String,
            ).toUtc();
            final value = (await read('/report') as Map)['relay'];
            if (time.isBefore(target)) {
              expect(
                value,
                target == on ? false : true,
                reason: 'No premature schedule action',
              );
            } else if (value == (target == on)) {
              result[target == on
                  ? 'on_latency_seconds'
                  : 'off_latency_seconds'] = time
                  .difference(target)
                  .inSeconds;
              break;
            }
            expect(
              time.isBefore(end),
              true,
              reason: 'Physical scheduler action deadline',
            );
            await tester.pump();
            await io(
              () => Future<void>.delayed(const Duration(milliseconds: 500)),
            );
          }
        }
        (result['checks'] as List).add(
          'Physical execution of the UI-created UTC ON/OFF pair, no early action',
        );
        checkpoint();
        for (var i = 0; i < 2; i++) {
          final trash = find.byIcon(Icons.delete_outline).last;
          await tester.ensureVisible(trash);
          await tester.tap(trash);
          await tester.pump();
        }
        mark = device.calls('/api/v1/scheduler', method: 'POST').length;
        await tapKey('scheduler_save_fab');
        await waitFor(
          () => device.calls('/api/v1/scheduler', method: 'POST').length > mark,
        );
        expect(
          device
              .calls('/api/v1/scheduler', method: 'POST')
              .last['schedule_body'],
          isEmpty,
        );
        expect(await read('/api/v1/scheduler'), isEmpty);
        expect(await read('/api/v1/settings'), settingsBefore);
        expect(await read('/api/v1/mqtt/settings'), mqttBefore);
        await io(() => device.identity());
        (result['checks'] as List).add(
          'UI schedule deletion and fresh readback; generic/MQTT settings and boot unchanged',
        );
        expect(
          device.journal.where((r) => r.containsKey('error_type')),
          isEmpty,
        );
        result['status'] = 'PASS';
      } catch (error) {
        result['status'] = 'REVIEW_REQUIRED';
        result['error_type'] = error.runtimeType.toString();
        rethrow;
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        try {
          await io(() async {
            await device.identity();
            if (initialSchedule != null) {
              final current = await device.direct('/api/v1/scheduler');
              if (jsonEncode(current) != jsonEncode(initialSchedule)) {
                await device.direct('/api/v1/scheduler', body: initialSchedule);
              }
            }
            await device.direct('/timer?mode=none&time=0');
            if ((await device.direct('/report') as Map)['relay'] != false) {
              await device.direct('/relay?state=0');
            }
            expect(await device.direct('/api/v1/scheduler'), initialSchedule);
            expect((await device.direct('/report') as Map)['relay'], false);
          });
          result['restore_ok'] = true;
        } catch (error) {
          result['restore_ok'] = false;
          result['restore_error_type'] = error.runtimeType.toString();
          result['status'] = 'CLEANUP_REVIEW_REQUIRED';
        }
        if (hiveStarted) await io(Hive.close);
        discovery.dispose();
        await io(device.close);
        result['finished_utc'] = DateTime.now().toUtc().toIso8601String();
        result['app_http_requests'] = device.journal.length;
        File('${output.path}/http.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(device.journal),
        );
        checkpoint();
        expect(result['restore_ok'], true);
      }
    },
    skip: !_enabled,
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
