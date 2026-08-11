/// A single schedule entry of the myStrom scheduler API
/// (`GET/POST /api/v1/scheduler`).
///
/// Times are stored in **UTC** on the device side; the UI converts to local
/// time for display and back to UTC before posting.
///
/// Fields per device variant:
/// - `ramp` + `color` (mode hsv/wrgb/temp): WRS (LED strip).
/// - `ramp` + `value`: WLL (dimmer).
/// - Other devices: only `action` matters.
///
/// `action: "set"` is a WRS special that changes color without toggling
/// on/off.
class SchedulerItem {
  final bool enable;
  final int hour;
  final int minute;

  /// `set`, `on`, `off`, `toggle`. Always sent as `action` (never `on: bool`).
  final String action;

  /// Weekday names in short form: `sun`, `mon`, ..., `sat`.
  final List<String> days;

  /// Color mode: `none`, `hsv`, `wrgb`, `temp` (WRS only). `null` when unset.
  final String? mode;

  /// Ramp duration in ms (WRS + WLL). `null` if not set.
  final int? ramp;

  /// Brightness value 0-255 (WLL only). `null` if not set.
  final int? value;

  /// HSV color: `{hue, saturation, value}` (WRS, mode=hsv). `null` if not set.
  final Map<String, dynamic>? hsv;

  /// WRGB color: `{w, r, g, b}` (WRS, mode=wrgb). `null` if not set.
  final Map<String, dynamic>? wrgb;

  /// Temp color: `{kelvin, brightness}` (WRS, mode=temp). `null` if not set.
  final Map<String, dynamic>? temp;

  const SchedulerItem({
    required this.enable,
    required this.hour,
    required this.minute,
    required this.action,
    required this.days,
    this.mode,
    this.ramp,
    this.value,
    this.hsv,
    this.wrgb,
    this.temp,
  });

  factory SchedulerItem.fromJson(Map<String, dynamic> j) {
    final rawDays = j['days'];
    final days = rawDays is List
        ? rawDays.map((d) => d.toString()).toList()
        : <String>[];
    // Parse color object: { mode: ..., hsv/wrgb/temp: {...} }
    final rawColor = j['color'];
    String? mode;
    Map<String, dynamic>? hsv, wrgb, temp;
    if (rawColor is Map<String, dynamic>) {
      mode = (rawColor['mode'] as String?)?.toLowerCase();
      if (rawColor['hsv'] is Map) {
        hsv = Map<String, dynamic>.from(rawColor['hsv'] as Map);
      }
      if (rawColor['wrgb'] is Map) {
        wrgb = Map<String, dynamic>.from(rawColor['wrgb'] as Map);
      }
      if (rawColor['temp'] is Map) {
        temp = Map<String, dynamic>.from(rawColor['temp'] as Map);
      }
    } else {
      // Legacy: top-level "mode" may exist without nested color object.
      mode = (j['mode'] as String?)?.toLowerCase();
    }
    return SchedulerItem(
      enable: j['enable'] as bool? ?? true,
      hour: (j['hour'] as num?)?.toInt() ?? 0,
      minute: (j['minute'] as num?)?.toInt() ?? 0,
      action: j['action'] as String? ?? 'on',
      days: days,
      mode: mode,
      ramp: (j['ramp'] as num?)?.toInt(),
      value: (j['value'] as num?)?.toInt(),
      hsv: hsv,
      wrgb: wrgb,
      temp: temp,
    );
  }

  Map<String, dynamic> toJson() {
    final j = <String, dynamic>{
      'enable': enable,
      'hour': hour,
      'minute': minute,
      'action': action,
      'days': days,
    };
    if (ramp != null) j['ramp'] = ramp;
    if (value != null) j['value'] = value;
    // Build the nested color object when any color sub-object is set.
    if (mode != null || hsv != null || wrgb != null || temp != null) {
      final color = <String, dynamic>{};
      if (mode != null) color['mode'] = mode;
      if (hsv != null) color['hsv'] = hsv;
      if (wrgb != null) color['wrgb'] = wrgb;
      if (temp != null) color['temp'] = temp;
      j['color'] = color;
    }
    return j;
  }

  SchedulerItem copyWith({
    bool? enable,
    int? hour,
    int? minute,
    String? action,
    List<String>? days,
    String? mode,
    int? ramp,
    int? value,
    Map<String, dynamic>? hsv,
    Map<String, dynamic>? wrgb,
    Map<String, dynamic>? temp,
  }) {
    return SchedulerItem(
      enable: enable ?? this.enable,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      action: action ?? this.action,
      days: days ?? this.days,
      mode: mode ?? this.mode,
      ramp: ramp ?? this.ramp,
      value: value ?? this.value,
      hsv: hsv ?? this.hsv,
      wrgb: wrgb ?? this.wrgb,
      temp: temp ?? this.temp,
    );
  }
}
