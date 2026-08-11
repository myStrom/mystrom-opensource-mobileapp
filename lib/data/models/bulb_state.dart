/// Bulb state. Same shape as strip but via /self path.
class BulbStateModel {
  final String mac;
  final bool on;
  final String color;
  final String mode;
  final int ramp;

  const BulbStateModel({
    required this.mac,
    required this.on,
    required this.color,
    required this.mode,
    required this.ramp,
  });

  factory BulbStateModel.fromJson(Map<String, dynamic> j) {
    final mac = j.keys.first;
    final inner = j[mac] as Map<String, dynamic>;
    return BulbStateModel(
      mac: mac,
      on: inner['on'] as bool? ?? false,
      color: inner['color'] as String? ?? '',
      mode: inner['mode'] as String? ?? 'hsv',
      ramp: (inner['ramp'] as num?)?.toInt() ?? 0,
    );
  }

  BulbStateModel copyWith({
    String? mac,
    bool? on,
    String? color,
    String? mode,
    int? ramp,
  }) {
    return BulbStateModel(
      mac: mac ?? this.mac,
      on: on ?? this.on,
      color: color ?? this.color,
      mode: mode ?? this.mode,
      ramp: ramp ?? this.ramp,
    );
  }
}
