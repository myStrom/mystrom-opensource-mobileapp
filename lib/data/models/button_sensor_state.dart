/// Temperature / humidity / battery sensor state for button-se devices
/// (BP2, BM1). See the API docs
class ButtonSensorStateModel {
  final double? temperature;
  final double? humidity;
  final BatteryInfo? battery;
  final ChargerInfo? charger;

  const ButtonSensorStateModel({
    this.temperature,
    this.humidity,
    this.battery,
    this.charger,
  });

  factory ButtonSensorStateModel.fromJson(Map<String, dynamic> j) {
    return ButtonSensorStateModel(
      temperature: (j['temperature'] as num?)?.toDouble(),
      humidity: (j['humidity'] as num?)?.toDouble(),
      battery: j['battery'] == null
          ? null
          : BatteryInfo.fromJson(j['battery'] as Map<String, dynamic>),
      charger: j['charger'] == null
          ? null
          : ChargerInfo.fromJson(j['charger'] as Map<String, dynamic>),
    );
  }
}

class BatteryInfo {
  final double voltage;
  final int percent;
  final bool charging;

  const BatteryInfo({
    required this.voltage,
    required this.percent,
    required this.charging,
  });

  factory BatteryInfo.fromJson(Map<String, dynamic> j) => BatteryInfo(
    voltage: (j['voltage'] as num?)?.toDouble() ?? 0,
    percent: (j['percent'] as num?)?.toInt() ?? 0,
    charging: j['charging'] as bool? ?? false,
  );
}

class ChargerInfo {
  final double voltage;
  final bool connected;

  const ChargerInfo({required this.voltage, required this.connected});

  factory ChargerInfo.fromJson(Map<String, dynamic> j) => ChargerInfo(
    voltage: (j['voltage'] as num?)?.toDouble() ?? 0,
    connected: j['connected'] as bool? ?? false,
  );
}
