import '../../l10n/app_localizations.dart';

/// Display label for a device/scene action code (API values stay English).
String localizedActionLabel(AppLocalizations l10n, String action) {
  return switch (action) {
    'on' => l10n.actionOn,
    'off' => l10n.actionOff,
    'toggle' => l10n.actionToggle,
    'timer' => l10n.actionTimer,
    'set' => l10n.setColorOnly,
    'color' => l10n.actionColor,
    _ => action,
  };
}

/// Short weekday label for scheduler UI (index 0 = Sun … 6 = Sat).
String localizedDayLabel(AppLocalizations l10n, int index) {
  return switch (index) {
    0 => l10n.daySun,
    1 => l10n.dayMon,
    2 => l10n.dayTue,
    3 => l10n.dayWed,
    4 => l10n.dayThu,
    5 => l10n.dayFri,
    6 => l10n.daySat,
    _ => '',
  };
}

/// Display label for a PIR action slot id.
String localizedPirSlotLabel(AppLocalizations l10n, String slot) {
  return switch (slot) {
    'generic' => l10n.pirActionGeneric,
    'night' => l10n.pirActionNight,
    'twilight' => l10n.pirActionTwilight,
    'day' => l10n.pirActionDay,
    'rise' => l10n.pirActionRise,
    'fall' => l10n.pirActionFall,
    _ => slot,
  };
}
