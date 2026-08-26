import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'l10n/app_localizations.dart';
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
    this.locale,
  });

  final UdpDiscoveryService discoveryService;
  final DeviceLocalDataSource localDataSource;
  final SceneLocalDataSource sceneDataSource;

  /// When set (e.g. in tests), overrides the device/system locale.
  final Locale? locale;

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
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        locale: locale,
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
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (locale, supported) {
          if (locale == null) return const Locale('en');
          for (final s in supported) {
            if (s.languageCode == locale.languageCode &&
                s.countryCode == locale.countryCode) {
              return s;
            }
          }
          for (final s in supported) {
            if (s.languageCode == locale.languageCode) {
              return s;
            }
          }
          return const Locale('en');
        },
        home: const DeviceListPage(),
      ),
    );
  }
}
