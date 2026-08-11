import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/network/udp_discovery.dart';
import 'data/datasources/device_local_ds.dart';
import 'data/datasources/scene_local_ds.dart';
import 'data/models/scene.dart';
import 'data/models/stored_device.dart';

/// Top-level zone guard: any unhandled async exception (e.g. a
/// SocketException from an offline device that slips past Dio's
/// DioException wrapping when a connect timeout fires first) is logged
/// quietly to the debug console instead of crashing the app with an
/// "Unhandled Exception" banner. Device HTTP probes are best-effort.
///
/// MUST wrap [runApp] so the entire app (including periodic timers and
/// HTTP pollers) runs inside the guarded zone. A zone ends as soon as its
/// body returns, so calling `runZonedGuarded(() {}, ...)` without runApp
/// inside would leave the app unprotected.
void _runGuardedApp(Widget app) {
  runZonedGuarded(() => runApp(app), (error, stack) {
    debugPrint('[zone-guard] swallowed async error: $error');
  });
}

Future<void> main() async {
  // Ensure the binding is initialised BEFORE we enter the guarded zone —
  // some plugins/bindings expect to run in the root zone.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Hive in the app support directory (writable on all platforms).
  final dir = await getApplicationSupportDirectory();
  Hive.init(dir.path);
  Hive.registerAdapter(StoredDeviceAdapter());
  Hive.registerAdapter(SceneAdapter());
  Hive.registerAdapter(SceneActionAdapter());

  // Open the devices box before the app starts so DeviceLocalDataSource
  // is ready to use immediately (avoids LateInitializationError).
  final localDs = DeviceLocalDataSource();
  await localDs.init();
  final sceneDs = SceneLocalDataSource();
  await sceneDs.init();

  // Start the persistent UDP discovery listener.
  final discovery = UdpDiscoveryService();
  await discovery.start();

  _runGuardedApp(
    MyApp(
      discoveryService: discovery,
      localDataSource: localDs,
      sceneDataSource: sceneDs,
    ),
  );
}
