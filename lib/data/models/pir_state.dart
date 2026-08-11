/// PIR sensor state (WMS). See the API docs
class PirStateModel {
  final bool motion;
  final double? lightLux;
  final double? temperature;

  const PirStateModel({required this.motion, this.lightLux, this.temperature});

  factory PirStateModel.fromSensors(Map<String, dynamic> j) {
    return PirStateModel(
      motion: j['motion'] as bool? ?? false,
      lightLux: (j['light'] as num?)?.toDouble(),
      temperature: (j['temperature'] as num?)?.toDouble(),
    );
  }
}
