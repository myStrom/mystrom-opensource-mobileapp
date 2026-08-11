/// Relay + power + temperature report for switch/plug devices
/// (WS2, WSE, WSX, LCS). See the API docs
class SwitchStateModel {
  final bool relay;
  final double? power;
  final double? consumption;
  final double? temperature;

  /// Energy accumulated since the device last booted, in watt-seconds
  /// (Ws). Sourced from the `Ws` (new firmware) or `consumption` (legacy)
  /// field of `/report`. `null` when the device does not report energy.
  final double? energySinceBoot;

  /// Identifier of the current boot cycle, when the device reports one
  /// (`boot_id` field). Used by the app to detect reboots and accumulate
  /// a long-term total energy counter across boots. `null` when absent.
  final String? bootId;

  const SwitchStateModel({
    required this.relay,
    this.power,
    this.consumption,
    this.temperature,
    this.energySinceBoot,
    this.bootId,
  });

  factory SwitchStateModel.fromReport(Map<String, dynamic> j) {
    // Energy since boot in watt-seconds (Ws). Prefer the explicit
    // `energy_since_boot` field (new firmware); fall back to legacy
    // `consumption`. Note: `Ws` on some firmware is instantaneous power,
    // NOT cumulative energy, so it is not used for the accumulator.
    final energy =
        (j['energy_since_boot'] as num?)?.toDouble() ??
        (j['consumption'] as num?)?.toDouble();
    return SwitchStateModel(
      relay: j['relay'] as bool? ?? false,
      power: (j['power'] as num?)?.toDouble(),
      consumption: energy,
      energySinceBoot: energy,
      temperature: (j['temperature'] as num?)?.toDouble(),
      bootId: j['boot_id']?.toString(),
    );
  }

  factory SwitchStateModel.fromRelay(Map<String, dynamic> j) {
    return SwitchStateModel(relay: j['relay'] as bool? ?? false);
  }

  SwitchStateModel copyWith({
    bool? relay,
    double? power,
    double? consumption,
    double? temperature,
    double? energySinceBoot,
    String? bootId,
  }) {
    return SwitchStateModel(
      relay: relay ?? this.relay,
      power: power ?? this.power,
      consumption: consumption ?? this.consumption,
      temperature: temperature ?? this.temperature,
      energySinceBoot: energySinceBoot ?? this.energySinceBoot,
      bootId: bootId ?? this.bootId,
    );
  }
}
