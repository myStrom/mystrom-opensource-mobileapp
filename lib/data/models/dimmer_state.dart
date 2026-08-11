/// Dimmer state (WLL). See the API docs
class DimmerStateModel {
  final String mac;
  final bool on;
  final int value; // 0-100
  final int ramp; // ms
  final double? power;

  const DimmerStateModel({
    required this.mac,
    required this.on,
    required this.value,
    required this.ramp,
    this.power,
  });

  factory DimmerStateModel.fromJson(Map<String, dynamic> j) {
    final mac = j.keys.first;
    final inner = j[mac] as Map<String, dynamic>;
    return DimmerStateModel(
      mac: mac,
      on: inner['on'] as bool? ?? false,
      value: (inner['value'] as num?)?.toInt() ?? 0,
      ramp: (inner['ramp'] as num?)?.toInt() ?? 0,
      power: (inner['power'] as num?)?.toDouble(),
    );
  }

  DimmerStateModel copyWith({
    String? mac,
    bool? on,
    int? value,
    int? ramp,
    double? power,
  }) {
    return DimmerStateModel(
      mac: mac ?? this.mac,
      on: on ?? this.on,
      value: value ?? this.value,
      ramp: ramp ?? this.ramp,
      power: power ?? this.power,
    );
  }
}
