// ignore_for_file: avoid_print
//
// Integration test: reads devices from the Hive box and calls every
// API endpoint the app uses, but only for devices that are stored
// (i.e. added by the user in the app).
//
// Run with:
//   dart run test/integration_test.dart
//
// This does NOT drive the UI — it exercises the data layer directly.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

import 'package:mystrom_local/core/config/app_config.dart';
import 'package:mystrom_local/core/network/device_http_client.dart';
import 'package:mystrom_local/core/utils/device_type.dart';
import 'package:mystrom_local/data/datasources/device_remote_ds.dart';
import 'package:mystrom_local/data/models/stored_device.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use the known Hive path (same as the Windows app uses via
  // getApplicationSupportDirectory).
  final hivePath = Platform.isWindows
      ? '${Platform.environment['APPDATA']}\ch.mystrom.local'
      : '/tmp/mystrom_local';
  Hive.init(hivePath);
  Hive.registerAdapter(StoredDeviceAdapter());
  final box = await Hive.openBox<StoredDevice>(AppConfig.hiveDevicesBox);

  final devices = box.values.toList();
  if (devices.isEmpty) {
    print('No devices stored in Hive. Add devices in the app first.');
    await box.close();
    exit(0);
  }

  print('Found ${devices.length} stored device(s):');
  for (final d in devices) {
    print(
      '  ${d.displayName} (${d.type.model}) MAC=${d.mac} IP=${d.lastKnownIp}',
    );
  }
  print('');

  final results = [0, 0]; // [passed, failed]

  for (final d in devices) {
    final ip = d.lastKnownIp;
    if (ip == null) {
      print('[SKIP] ${d.displayName} — no IP');
      continue;
    }

    print('=== ${d.displayName} ($ip) — ${d.type.model} ===');
    final remote = DeviceRemoteDataSource(DeviceHttpClient(token: d.token));

    // 1. GET /info (with fallback to /api/v1/info)
    await _test('GET /info', () async {
      final info = await remote.getInfo(ip);
      print('    firmware=${info.version} type=${info.type} ssid=${info.ssid}');
    }, results);

    // 2. Type-specific endpoints
    if (d.type.isSwitch) {
      await _testSwitch(remote, ip, d, results);
    } else if (d.type.isStrip) {
      await _testStrip(remote, ip, results);
    } else if (d.type.isDimmer) {
      await _testDimmer(remote, ip, results);
    } else if (d.type.isBulb) {
      await _testBulb(remote, ip, results);
    } else if (d.type.isPir) {
      await _testPir(remote, ip, results);
    } else if (d.type.isButton) {
      await _testButton(remote, ip, d, results);
    }

    // 3. Timer (if supported) — use device-specific path for bulb.
    if (d.type.hasTimer) {
      final timerPath = d.type.isBulb ? '/api/v1/timer/self' : null;
      await _test('POST timer (mode=none)', () async {
        await remote.setTimer(ip, mode: 'none', seconds: 0, path: timerPath);
      }, results);
    }

    // 4. Turn off the device after testing.
    await _turnOffAfterTest(remote, ip, d.type, results);

    print('');
  }

  print('=========================');
  print('Results: ${results[0]} passed, ${results[1]} failed');
  await box.close();
  exit(results[1] > 0 ? 1 : 0);
}

Future<void> _test(
  String label,
  Future<void> Function() fn,
  List<int> results,
) async {
  try {
    await fn();
    print('  [OK] $label');
    results[0] += 1;
  } catch (e) {
    print('  [FAIL] $label: $e');
    results[1] += 1;
  }
}

Future<void> _testSwitch(
  DeviceRemoteDataSource remote,
  String ip,
  StoredDevice d,
  List<int> results,
) async {
  await _test('GET /report', () async {
    final s = await remote.getReport(ip);
    print('    relay=${s.relay} power=${s.power}W temp=${s.temperature}°C');
  }, results);

  await _test('GET /toggle', () async {
    final s = await remote.toggleRelay(ip);
    print('    relay=${s.relay}');
  }, results);

  // Toggle back to restore state
  await _test('GET /toggle (restore)', () async {
    await remote.toggleRelay(ip);
  }, results);

  // LCS button action URL
  if (d.type == DeviceType.lcs) {
    await _test('GET /api/v1/action/button', () async {
      final url = await remote.getLcsButtonAction(ip);
      print('    buttonUrl=$url');
    }, results);
  }
}

Future<void> _testStrip(
  DeviceRemoteDataSource remote,
  String ip,
  List<int> results,
) async {
  await _test('GET /api/v1/device', () async {
    final s = await remote.getStripState(ip);
    print('    on=${s.on} color=${s.color} mode=${s.mode} chMode=${s.chMode}');
  }, results);

  await _test('GET /api/v1/ch_mode', () async {
    final mode = await remote.getChMode(ip);
    print('    chMode=$mode');
  }, results);

  await _test('POST /device (HSV color)', () async {
    await remote.setStripState(
      ip,
      action: 'on',
      color: '120;100;50',
      mode: 'hsv',
      ramp: 500,
    );
  }, results);

  await _test('POST /device (WRGB color)', () async {
    await remote.setStripState(
      ip,
      action: 'on',
      color: 'FF00FF00',
      mode: 'rgb',
      ramp: 500,
    );
  }, results);
}

Future<void> _testDimmer(
  DeviceRemoteDataSource remote,
  String ip,
  List<int> results,
) async {
  await _test('GET /api/v1/device', () async {
    final s = await remote.getDimmerState(ip);
    print('    on=${s.on} value=${s.value} ramp=${s.ramp}');
  }, results);

  await _test('POST /device (value=50)', () async {
    await remote.setDimmerState(ip, action: 'on', value: 50, ramp: 500);
  }, results);
}

Future<void> _testBulb(
  DeviceRemoteDataSource remote,
  String ip,
  List<int> results,
) async {
  await _test('GET /api/v1/device/self', () async {
    final s = await remote.getBulbState(ip);
    print('    on=${s.on} color=${s.color} mode=${s.mode}');
  }, results);

  await _test('POST /api/v1/device/self (HSV)', () async {
    await remote.setBulbState(
      ip,
      action: 'on',
      color: '240;100;100',
      mode: 'hsv',
      ramp: 500,
    );
  }, results);

  await _test('POST /api/v1/device/self (mode only)', () async {
    await remote.setBulbState(ip, mode: 'rgb');
  }, results);
}

Future<void> _testPir(
  DeviceRemoteDataSource remote,
  String ip,
  List<int> results,
) async {
  await _test('GET /api/v1/sensors', () async {
    final s = await remote.getPirSensors(ip);
    print('    motion=${s.motion} lux=${s.lightLux} temp=${s.temperature}');
  }, results);

  await _test('GET /api/v1/action (PIR actions)', () async {
    final actions = await remote.getPirActions(ip);
    print('    actions=$actions');
  }, results);
}

Future<void> _testButton(
  DeviceRemoteDataSource remote,
  String ip,
  StoredDevice d,
  List<int> results,
) async {
  if (d.type == DeviceType.bp2 ||
      d.type == DeviceType.bm1 ||
      d.type == DeviceType.bp1) {
    await _test('GET /api/v1/sensors', () async {
      final s = await remote.getButtonSeSensors(ip);
      print(
        '    temp=${s.temperature} humi=${s.humidity} battery=${s.battery?.percent}%',
      );
    }, results);

    await _test('GET /api/v1/actions/generic', () async {
      final actions = await remote.getButtonSeActions(ip, referer: 'generic');
      print('    actions=$actions');
    }, results);
  } else {
    // Single-button device
    await _test('GET /api/v1/actions', () async {
      final cfg = await remote.getButtonActions(ip);
      print('    actions=${cfg.actions.length}');
    }, results);
  }
}

/// Turn off the device after testing so we leave it in a clean state.
Future<void> _turnOffAfterTest(
  DeviceRemoteDataSource remote,
  String ip,
  DeviceType type,
  List<int> results,
) async {
  try {
    if (type.isSwitch) {
      await remote.setRelay(ip, on: false);
      print('  [OK] Turned off relay');
    } else if (type.isStrip) {
      await remote.setStripState(ip, action: 'off');
      print('  [OK] Turned off strip');
    } else if (type.isDimmer) {
      await remote.setDimmerState(ip, action: 'off');
      print('  [OK] Turned off dimmer');
    } else if (type.isBulb) {
      await remote.setBulbState(ip, action: 'off');
      print('  [OK] Turned off bulb');
    }
    // PIR and buttons have no on/off state.
  } catch (e) {
    print('  [WARN] Could not turn off: $e');
  }
}
