/// LED strip state (WRS). See the API docs
class StripStateModel {
  final String mac;
  final bool on;
  final String color; // e.g. "120;100;50" (HSV) or hex "WWRRGGBB"
  final String mode; // hsv | rgb | mono | color
  final int ramp; // ms
  final bool reachable;
  final String chMode; // colors | channels | cold_warm

  const StripStateModel({
    required this.mac,
    required this.on,
    required this.color,
    required this.mode,
    required this.ramp,
    this.reachable = true,
    this.chMode = 'colors',
  });

  factory StripStateModel.fromJson(Map<String, dynamic> j) {
    // Response is keyed by MAC: { "A1B2...": { ... } }
    final mac = j.keys.first;
    final inner = j[mac] as Map<String, dynamic>;
    return StripStateModel(
      mac: mac,
      on: inner['on'] as bool? ?? false,
      color: inner['color'] as String? ?? '',
      mode: inner['mode'] as String? ?? 'hsv',
      ramp: (inner['ramp'] as num?)?.toInt() ?? 0,
      reachable: inner['reachable'] as bool? ?? true,
    );
  }

  StripStateModel copyWith({
    String? mac,
    bool? on,
    String? color,
    String? mode,
    int? ramp,
    bool? reachable,
    String? chMode,
  }) {
    return StripStateModel(
      mac: mac ?? this.mac,
      on: on ?? this.on,
      color: color ?? this.color,
      mode: mode ?? this.mode,
      ramp: ramp ?? this.ramp,
      reachable: reachable ?? this.reachable,
      chMode: chMode ?? this.chMode,
    );
  }
}
