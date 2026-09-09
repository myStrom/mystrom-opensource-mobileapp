import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mystrom_local/l10n/app_localizations.dart';
import 'package:mystrom_local/presentation/utils/number_format.dart';

void main() {
  group('de_CH AppLocalizations overrides', () {
    late AppLocalizations deCh;
    late AppLocalizations de;

    setUp(() {
      deCh = lookupAppLocalizations(const Locale('de', 'CH'));
      de = lookupAppLocalizations(const Locale('de'));
    });

    test('uses Swiss guillemets in room bulk actions', () {
      expect(
        deCh.turnAllInRoomOn('Wohnzimmer'),
        'Alle in «Wohnzimmer» einschalten',
      );
      expect(
        de.turnAllInRoomOn('Wohnzimmer'),
        'Alle in „Wohnzimmer“ einschalten',
      );
    });

    test('uses Swiss Weiss spelling without eszett in AP mode LED hint', () {
      expect(deCh.apModeLedWhite, contains('Weiss'));
      expect(deCh.apModeLedWhite, isNot(contains('ß')));
      expect(de.apModeLedWhite, contains('Weiß'));
    });

    test('sceneIconDinner override differs from standard German', () {
      expect(deCh.sceneIconDinner, 'Nachtessen');
      expect(de.sceneIconDinner, 'Abendessen');
    });

    test('softAp intro uses Swiss anschliessend spelling', () {
      expect(deCh.softApSelectApIntro, contains('anschliessend'));
    });
  });

  group('de_CH number formatting', () {
    test('uses apostrophe thousands and dot decimals', () {
      final formatted = decimalFormat(const Locale('de', 'CH'), 1).format(
        1234.5,
      );
      expect(formatted, "1'234.5");
    });

    test('differs from Germany locale formatting', () {
      final ch = decimalFormat(const Locale('de', 'CH'), 1).format(1234.5);
      final de = decimalFormat(const Locale('de'), 1).format(1234.5);
      expect(ch, isNot(de));
      expect(de, '1.234,5');
    });

    testWidgets('formatDecimal reads de_CH from widget context', (
      tester,
    ) async {
      late String formatted;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de', 'CH'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              formatted = formatDecimal(context, 1234.5, 1);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(formatted, "1'234.5");
    });
  });

  group('de_CH locale resolution smoke', () {
    testWidgets('MaterialApp resolves de_CH strings in widget tree', (
      tester,
    ) async {
      const room = 'Küche';
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de', 'CH'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(l10n.turnAllInRoomOff(room));
            },
          ),
        ),
      );

      expect(find.text('Alle in «$room» ausschalten'), findsOneWidget);
    });
  });
}
