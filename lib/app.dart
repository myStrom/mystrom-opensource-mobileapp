import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/udp_discovery.dart';
import 'data/datasources/device_local_ds.dart';
import 'data/datasources/scene_local_ds.dart';
import 'data/repositories/device_repository.dart';
import 'data/repositories/discovery_repository.dart';
import 'data/repositories/scene_repository.dart';
import 'domain/usecases/run_scene.dart';
import 'data/datasources/device_remote_ds.dart';
import 'core/network/device_http_client.dart';
import 'presentation/pages/device_list_page.dart';
import 'presentation/providers/device_provider.dart';
import 'presentation/providers/discovery_provider.dart';
import 'presentation/providers/scene_provider.dart';

/// Root widget — sets up providers and starts UDP discovery.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.discoveryService,
    required this.localDataSource,
    required this.sceneDataSource,
  });

  final UdpDiscoveryService discoveryService;
  final DeviceLocalDataSource localDataSource;
  final SceneLocalDataSource sceneDataSource;

  @override
  Widget build(BuildContext context) {
    final discoveryRepo = DiscoveryRepository(discoveryService);
    final deviceRepo = DeviceRepository(localDataSource);
    final sceneRepo = SceneRepository(sceneDataSource);
    final runScene = RunScene(DeviceRemoteDataSource(DeviceHttpClient()));

    return MultiProvider(
      providers: [
        Provider<DiscoveryRepository>.value(value: discoveryRepo),
        Provider<DeviceRepository>.value(value: deviceRepo),
        ChangeNotifierProvider(
          create: (_) => DeviceProvider(
            deviceRepo: deviceRepo,
            discoveryStream: discoveryRepo.devices,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DiscoveryProvider(discoveryRepo.devices),
        ),
        ChangeNotifierProvider(
          create: (_) => SceneProvider(
            sceneRepo: sceneRepo,
            deviceRepo: deviceRepo,
            runScene: runScene,
          )..refresh(),
        ),
      ],
      child: MaterialApp(
        title: 'myStrom Local',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5EB342),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5EB342),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const DeviceListPage(),
      ),
    );
  }
}
