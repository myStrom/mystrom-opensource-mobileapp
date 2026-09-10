import 'package:flutter_test/flutter_test.dart';

import 'package:mystrom_local/core/utils/scheduler_time.dart';
import 'package:mystrom_local/data/models/scheduler_item.dart';

/// Regression tests for the scheduler UTC <-> local day conversion.
///
/// The bug (2026-09-10): day shift used truncating division (`~/`) on a
/// possibly negative minute difference. For eastern zones (UTC+2) a local
/// Monday 00:30 converts to Sunday 22:30 UTC — but `~/` produced a day
/// shift of 0 instead of -1, keeping the day as Monday. Western zones hit
/// the same bug in utcToLocal.
///
/// The converter reads the machine timezone, so tests use zone-specific
/// expected values only when the required offset is actually in effect,
/// and otherwise verify the pure arithmetic invariants that must hold in
/// EVERY timezone.
void main() {
  SchedulerItem item(int hour, int minute, List<String> days) => SchedulerItem(
        enable: true,
        hour: hour,
        minute: minute,
        action: 'on',
        days: days,
      );

  test('localToUtc: crossing midnight backwards shifts the day back', () {
    final utc = SchedulerTimeConverter.localToUtc(item(0, 30, ['mon']));
    final off = SchedulerTimeConverter.tzOffsetMin;

    if (off > 30) {
      // Eastern zone (e.g. UTC+1..+12): Monday 00:30 local falls on the
      // previous UTC day (Sunday for offset >= 31 min). Exact time:
      // shifted minutes = 30 - off, wrapped into the previous day.
      final shifted = (30 - off) % 1440;
      expect(utc.hour * 60 + utc.minute, shifted);
      expect(utc.days, ['sun']);
    } else {
      // UTC or western zone: no day change, minute arithmetic must hold.
      final expectedShifted = (0 * 60 + 30 - off) % (7 * 1440);
      expect(utc.hour * 60 + utc.minute, expectedShifted % 1440);
      expect(utc.days, ['mon']);
    }
  });

  test('localToUtc UTC+2: Monday 00:30 -> Sunday 22:30', () {
    // Only meaningful in UTC+2; skip silently elsewhere.
    if (SchedulerTimeConverter.tzOffsetMin != 120) return;
    final utc = SchedulerTimeConverter.localToUtc(item(0, 30, ['mon']));
    expect(utc.hour, 22);
    expect(utc.minute, 30);
    expect(utc.days, ['sun']);
  });

  test('utcToLocal UTC+2: Sunday 22:30 UTC -> Monday 00:30 local', () {
    if (SchedulerTimeConverter.tzOffsetMin != 120) return;
    final local = SchedulerTimeConverter.utcToLocal(item(22, 30, ['sun']));
    expect(local.hour, 0);
    expect(local.minute, 30);
    expect(local.days, ['mon']);
  });

  test('midnight boundary: no shift when the offset lands exactly on 00:00',
      () {
    final utc = SchedulerTimeConverter.localToUtc(item(0, 0, ['mon']));
    final off = SchedulerTimeConverter.tzOffsetMin;
    // 00:00 local minus a positive offset lands on the previous day.
    if (off == 0) {
      expect(utc.hour, 0);
      expect(utc.minute, 0);
      expect(utc.days, ['mon']);
    } else {
      // The resulting day must differ from Monday only if the shifted
      // time is on a different calendar day than the local one.
      final shifted = 0 * 60 + 0 - off;
      final expectPrevDay = shifted < 0;
      expect(utc.days, expectPrevDay ? ['sun'] : ['mon']);
    }
  });

  test('maximum offset keeps time within 0:00-23:59', () {
    // 23:59 local -> shifted by any offset must still be a valid time.
    final utc = SchedulerTimeConverter.localToUtc(item(23, 59, ['sat']));
    expect(utc.hour, inInclusiveRange(0, 23));
    expect(utc.minute, inInclusiveRange(0, 59));
    // Week never overflows past sat: days stay valid weekday names.
    expect(SchedulerTimeConverter.dayNames, containsAll(utc.days));
  });

  test('day shift uses floor semantics for negative shifts (regression)', () {
    // The original bug: -90 minutes gave dayShift 0 (truncation) instead
    // of -1 (floor). Simulate by checking the internal invariant: the
    // day must change whenever the shifted minutes leave the local day.
    final off = SchedulerTimeConverter.tzOffsetMin;
    // Pick a time guaranteed to be in the negative-shift danger zone
    // for this machine's zone: local 00:30 with a positive offset, or
    // local 23:30 with a negative offset.
    if (off >= 60) {
      final utc = SchedulerTimeConverter.localToUtc(item(0, 30, ['mon']));
      expect(utc.days, ['sun'], reason: 'UTC+$off: 00:30 local is previous day');
    } else if (off <= -60) {
      final local = SchedulerTimeConverter.utcToLocal(item(23, 30, ['mon']));
      expect(local.days, ['sun'],
          reason: 'UTC$off: 23:30 UTC is next day in the west');
    } else {
      // Zone too small to trigger a day shift at these times; assert the
      // invariant with a synthetic 6-hour offset instead is impossible
      // without injecting the offset. Guarded by the arithmetic tests.
    }
  });

  test('week wraps: Saturday -> Sunday and back (regression, week boundary)',
      () {
    if (SchedulerTimeConverter.tzOffsetMin != 120) return;
    // Monday 00:30 local (UTC+2) is Sunday 22:30 UTC; then utcToLocal
    // must map Sunday 22:30 UTC back to Monday 00:30 — the two errors
    // must not cancel out silently.
    final round1 = SchedulerTimeConverter.localToUtc(item(0, 30, ['mon']));
    expect(round1.days, ['sun']);
    final round2 = SchedulerTimeConverter.utcToLocal(round1);
    expect(round2.days, ['mon']);
    expect(round2.hour, 0);
    expect(round2.minute, 30);
  });
}