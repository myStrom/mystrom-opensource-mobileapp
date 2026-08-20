import 'package:flutter_test/flutter_test.dart';
import 'package:mystrom_local/presentation/pages/history_page.dart';

void main() {
  group('parseHistoryTimestamp', () {
    test('parses a timestamp with trailing Z as local time (not UTC)', () {
      // The myStrom device emits local time with a fake 'Z' suffix.
      // '2026-08-18T23:00:10Z' should be parsed as 23:00:10 local,
      // NOT as 23:00:10 UTC (which would become 01:00 next day in CEST).
      final dt = parseHistoryTimestamp('2026-08-18T23:00:10Z');
      expect(dt.year, 2026);
      expect(dt.month, 8);
      expect(dt.day, 18);
      expect(dt.hour, 23);
      expect(dt.minute, 0);
      expect(dt.second, 10);
      // isUtc must be false — we parsed it as local (naive) time.
      expect(dt.isUtc, isFalse);
    });

    test('parses a timestamp without trailing Z', () {
      final dt = parseHistoryTimestamp('2026-08-18T08:00:06');
      expect(dt.hour, 8);
      expect(dt.minute, 0);
      expect(dt.second, 6);
      expect(dt.day, 18);
    });

    test('does NOT shift by timezone offset', () {
      // If we wrongly treated 'Z' as UTC and called toLocal(), the hour
      // would change by the local UTC offset (e.g. +2 in CEST). We
      // verify the hour stays exactly as written.
      for (final hour in [0, 6, 12, 18, 22, 23]) {
        final padded = hour.toString().padLeft(2, '0');
        final dt = parseHistoryTimestamp('2026-08-18T$padded:00:00Z');
        expect(dt.hour, hour, reason: 'hour $hour was shifted');
      }
    });

    test('handles empty string gracefully', () {
      final dt = parseHistoryTimestamp('');
      expect(dt.millisecondsSinceEpoch, 0);
    });

    test('handles midnight boundary correctly', () {
      // A record at 00:00 local should stay on the same day, not shift
      // to the previous day.
      final dt = parseHistoryTimestamp('2026-08-18T00:00:04Z');
      expect(dt.day, 18);
      expect(dt.hour, 0);
    });

    test('preserves seconds field', () {
      // Real device data has non-zero seconds (NTP drift).
      final dt = parseHistoryTimestamp('2026-08-17T04:00:29Z');
      expect(dt.second, 29);
    });
  });
}
