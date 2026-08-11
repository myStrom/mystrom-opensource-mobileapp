import '../../data/models/scheduler_item.dart';

/// Conversion between device-side UTC schedule times and local display times.
///
/// Mirrors the logic in myStrom's `scheduler.html`: the device stores every
/// schedule entry's `hour`/`minute` in UTC, while days are expressed as short
/// weekday names (`sun`, `mon`, ..., `sat`) anchored to those UTC times. The
/// UI converts entries to the user's local timezone for editing and back to
/// UTC before posting.
class SchedulerTimeConverter {
  SchedulerTimeConverter._();

  /// Short weekday names used by the scheduler API (index 0 = Sunday).
  static const dayNames = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

  /// Local timezone offset in minutes expressed as `local - UTC`.
  /// For UTC+2 this is +120. Equivalent to `-new Date().getTimezoneOffset()`
  /// from the reference scheduler UI: JS `getTimezoneOffset()` returns
  /// `UTC - local` (e.g. -120), so it is negated there. Dart's
  /// `timeZoneOffset` already follows the `local - UTC` convention, so no
  /// negation is needed here.
  static int get tzOffsetMin => DateTime.now().timeZoneOffset.inMinutes;

  /// Converts an item from UTC (device) to the user's local timezone.
  static SchedulerItem utcToLocal(SchedulerItem item) {
    final utcMin = item.hour * 60 + item.minute;
    final shifted = utcMin + tzOffsetMin;
    final wrapped = ((shifted % (7 * 1440)) + (7 * 1440)) % (7 * 1440);
    final dayShift = shifted ~/ 1440;
    return item.copyWith(
      hour: (wrapped % 1440) ~/ 60,
      minute: wrapped % 60,
      days: _shiftDays(item.days, dayShift),
    );
  }

  /// Converts an item from the user's local timezone back to UTC.
  static SchedulerItem localToUtc(SchedulerItem item) {
    final localMin = item.hour * 60 + item.minute;
    final shifted = localMin - tzOffsetMin;
    final wrapped = ((shifted % (7 * 1440)) + (7 * 1440)) % (7 * 1440);
    final dayShift = shifted ~/ 1440;
    return item.copyWith(
      hour: (wrapped % 1440) ~/ 60,
      minute: wrapped % 60,
      days: _shiftDays(item.days, dayShift),
    );
  }

  static List<String> _shiftDays(List<String> days, int dayShift) {
    if (dayShift == 0 || days.isEmpty) return List<String>.from(days);
    return days.map((d) {
      final idx = dayNames.indexOf(d);
      if (idx < 0) return d;
      return dayNames[((idx + dayShift) % 7 + 7) % 7];
    }).toList();
  }
}
