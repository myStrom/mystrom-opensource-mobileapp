import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mystrom_local/core/utils/device_type.dart';
import 'package:mystrom_local/domain/entities/device_entity.dart';
import 'package:mystrom_local/l10n/app_localizations.dart';
import 'package:mystrom_local/presentation/pages/strip_detail_page.dart';
import 'package:mystrom_local/presentation/pages/strip_settings_page.dart';

import 'fake_mystrom_server.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final mode in ['colors', 'channels', 'cold_warm']) {
    testWidgets('detail and settings read $mode from text/plain', (
      tester,
    ) async {
      final server = FakeMystromServer();
      await server.start();
      final state =
          server.register(
              FakeDeviceState(
                mac: '020000000105',
                type: 'strip',
                model: 'WRS',
                version: '5.0.4',
              ),
            )
            ..chMode = mode
            ..mode = 'rgb'
            ..color = 'FF00FF00';
      final device = DeviceEntity(
        mac: state.mac,
        name: 'Strip channel mode',
        type: DeviceType.wrs,
        lastKnownIp: '${server.host}:${server.port}',
        lastSeen: DateTime.now(),
        addedAt: DateTime.now(),
      );

      Future<void> show(Widget page) async {
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: page,
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      try {
        await show(StripDetailPage(device: device));
        expect(find.text('Mode: $mode'), findsOneWidget);
        expect(
          find.byKey(const Key('strip_channel_1')),
          mode == 'channels' ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(const Key('strip_tab_color')),
          mode == 'colors' ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(const Key('strip_warm')),
          mode == 'cold_warm' ? findsOneWidget : findsNothing,
        );

        if (mode == 'channels') {
          final slider = find.byKey(const Key('strip_channel_2'));
          await tester.ensureVisible(slider);
          await tester.drag(slider, const Offset(1000, 0));
          await tester.pumpAndSettle(const Duration(milliseconds: 600));
          final writes = server.requests.where((r) => r.method == 'POST');
          expect(writes, hasLength(1));
          expect(writes.single.path, '/device');
          expect(Uri.splitQueryString(writes.single.body!), {
            'action': 'on',
            'color': 'FFFFFF00',
            'ramp': '500',
            'mode': 'rgb',
          });
          expect(state.color, 'FFFFFF00');
          expect(state.on, isTrue);
          expect(find.text('Mode: channels'), findsOneWidget);
        }

        await show(StripSettingsPage(device: device));
        final selected = find.byKey(Key('strip_chmode_$mode'));
        expect(
          find.descendant(
            of: selected,
            matching: find.byIcon(Icons.check_circle),
          ),
          findsOneWidget,
        );
        expect(
          server.requests.where((r) => r.path == '/api/v1/ch_mode'),
          hasLength(2),
        );
        expect(
          server.requests.where((r) => r.method != 'GET'),
          mode == 'channels' ? hasLength(1) : isEmpty,
        );
        expect(state.chMode, mode);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await server.stop();
      }
    });
  }
}
