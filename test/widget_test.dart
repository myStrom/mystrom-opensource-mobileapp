// Real widget tests for the presentation layer that run without Hive or
// UDP: the shared ColorPickerWidget (HSV emission + hue clamp) and the
// ActionUrlPicker dialog (action URL generation + HSV sanitization).
//
// These replace the former `expect(true, isTrue)` placeholder: every test
// here fails if the widget stops emitting the expected values.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mystrom_local/core/utils/device_type.dart';
import 'package:mystrom_local/domain/entities/device_entity.dart';
import 'package:mystrom_local/l10n/app_localizations.dart';
import 'package:mystrom_local/presentation/utils/hsv_utils.dart';
import 'package:mystrom_local/presentation/widgets/action_url_picker.dart';
import 'package:mystrom_local/presentation/widgets/color_picker_widget.dart';

/// Minimal app shell providing the l10n delegates (en) around [child].
Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

DeviceEntity _bulb(String ip) => DeviceEntity(
      mac: 'AA:BB:CC:DD:EE:FF',
      name: 'Test Bulb',
      type: DeviceType.bulb,
      lastKnownIp: ip,
      addedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('ColorPickerWidget', () {
    testWidgets('emits nothing without interaction', (tester) async {
      String? emitted;
      await tester.pumpWidget(
        _wrap(
          ColorPickerWidget(
            initialHue: 120,
            initialSaturation: 80,
            initialValue: 60,
            onColorChanged: (c) => emitted = c,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(emitted, isNull,
          reason: 'no interaction happened — nothing should be emitted');
    });

    testWidgets('emits clamped H;S;V when the hue slider moves to max',
        (tester) async {
      String? emitted;
      await tester.pumpWidget(
        _wrap(
          ColorPickerWidget(
            initialHue: 10,
            initialSaturation: 50,
            initialValue: 50,
            onColorChanged: (c) => emitted = c,
          ),
        ),
      );

      // Baseline: nothing emitted yet — the initial state must NOT
      // already satisfy the final assertion (hue 359).
      expect(emitted, isNull);

      // Drag the hue slider (first Slider in the widget) to the far right.
      final hueSlider = find.byType(Slider).first;
      await tester.drag(hueSlider, const Offset(1000, 0));
      await tester.pump(const Duration(milliseconds: 600));

      // The emitted value must be the slider maximum: hue exactly 359,
      // never 360, with saturation/value unchanged by the drag.
      expect(emitted, isNotNull, reason: 'a drag must trigger an emission');
      final parts = emitted!.split(';');
      expect(parts.length, 3, reason: 'H;S;V format expected: $emitted');
      expect(parts[0], '359',
          reason: 'hue at slider max must be 359, got: $emitted');
      expect(parts[1], '50');
      expect(parts[2], '50');

      // The visible label must match the emitted hue.
      expect(find.text('Hue: 359°'), findsOneWidget);
    });

    testWidgets('clamps a device hue of 360 down to 359 on init',
        (tester) async {
      // A device reporting hue 360 (wrap-around value) must render the
      // slider at 359, not out of range.
      await tester.pumpWidget(
        _wrap(
          ColorPickerWidget(
            initialHue: 360,
            onColorChanged: (_) {},
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider).first);
      expect(slider.value, 359);
      expect(slider.max, maxHue.toDouble());
      expect(find.text('Hue: 359°'), findsOneWidget);
    });
  });

  group('ActionUrlPicker', () {
    testWidgets('generates a color action URL with sanitized HSV',
        (tester) async {
      String? generated;
      final bulb = _bulb('192.168.1.50');

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  generated = await showDialog<String>(
                    context: context,
                    builder: (_) => ActionUrlPicker(
                      devices: [bulb],
                      onUrlGenerated: (u) => Navigator.pop(context, u),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Pick the target device (dropdown shows name + model).
      final deviceField = find.byType(DropdownButtonFormField<DeviceEntity>);
      expect(deviceField, findsOneWidget);
      await tester.tap(deviceField);
      await tester.pumpAndSettle();
      // The menu overlay renders exactly one entry per controllable device.
      final bulbItem = find.text('Test Bulb (Bulb)');
      expect(bulbItem, findsOneWidget);
      await tester.tap(bulbItem);
      await tester.pumpAndSettle();

      // Switch the action to color (label is l10n.actionColor = "color").
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('color').last);
      await tester.pumpAndSettle();

      // Enter an out-of-range hue: 400 must clamp to 359 in the URL.
      await tester.enterText(
        find.byKey(const Key('action_url_color_field')),
        '400;100;100',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();

      expect(generated, isNotNull,
          reason: 'Assign must close the dialog with a URL');
      expect(generated, contains('color=359;100;100'),
          reason: 'hue 400 must be sanitized to 359 in the URL, '
              'got: $generated');
      expect(generated, contains('post://192.168.1.50/api/v1/device/self'));
      expect(generated, contains('action=color'));
    });

    testWidgets('rejects a malformed HSV color instead of inventing one',
        (tester) async {
      String? generated;
      final bulb = _bulb('192.168.1.50');

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  generated = await showDialog<String>(
                    context: context,
                    builder: (_) => ActionUrlPicker(
                      devices: [bulb],
                      onUrlGenerated: (u) => Navigator.pop(context, u),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final deviceField = find.byType(DropdownButtonFormField<DeviceEntity>);
      await tester.tap(deviceField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Bulb (Bulb)'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('color').last);
      await tester.pumpAndSettle();

      // Enter garbage: no URL may be generated and no arbitrary color
      // substituted — the dialog must show a validation error instead.
      await tester.enterText(
        find.byKey(const Key('action_url_color_field')),
        'not-a-color',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();

      expect(generated, isNull,
          reason: 'malformed HSV must NOT produce a URL');
      expect(find.text('Invalid color. Use H;S;V (e.g. 120;100;100).'),
          findsOneWidget);
      expect(find.text('open'), findsOneWidget,
          reason: 'the dialog must still be open showing the error');

      // Fixing the input clears the error and generates the URL.
      await tester.enterText(
        find.byKey(const Key('action_url_color_field')),
        '30;50;60',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();

      expect(generated, contains('color=30;50;60'));
      expect(generated, contains('post://192.168.1.50/api/v1/device/self'));
    });
  });
}
