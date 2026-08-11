import 'package:hive/hive.dart';

import '../../core/utils/device_type.dart';

part 'stored_device.g.dart';

/// Persistent device record stored in Hive.
@HiveType(typeId: 0)
class StoredDevice extends HiveObject {
  @HiveField(0)
  String mac;

  @HiveField(1)
  String name;

  @HiveField(2)
  int typeCode;

  @HiveField(3)
  String? lastKnownIp;

  @HiveField(4)
  DateTime? lastSeen;

  @HiveField(5)
  String? customName;

  @HiveField(6)
  DateTime addedAt;

  @HiveField(7)
  String? room;

  @HiveField(8)
  String? token;

  @HiveField(9)
  int? colorValue;

  @HiveField(10)
  bool favorite;

  /// When true, the on/off state of this device cannot be toggled from
  /// the app (e.g. a fridge). Timers and scheduler are still allowed.
  /// HiveField 11 — defaults to false for older entries.
  @HiveField(11)
  bool lockable;

  /// Long-term accumulated energy across reboots, in watt-seconds (Ws).
  /// HiveField 12. Defaults to 0 for older entries.
  @HiveField(12)
  double totalEnergyWs;

  /// The device boot identifier last seen by the app. When a /report
  /// returns a different `boot_id`, the previous boot's energy
  /// ([bootEnergyWs]) is folded into [totalEnergyWs] before resetting.
  /// HiveField 13.
  @HiveField(13)
  String? bootId;

  /// Energy accumulated for the current boot cycle ([bootId]), in Ws.
  /// HiveField 14. Defaults to 0 for older entries.
  @HiveField(14)
  double bootEnergyWs;

  /// User-adjusted temperature offset in °C (range -30..+30, one decimal).
  /// Applied to the raw temperature reported by the device before display.
  /// HiveField 15. Defaults to 0 for older entries.
  @HiveField(15)
  double temperatureOffset;

  StoredDevice({
    required this.mac,
    required this.name,
    required this.typeCode,
    this.lastKnownIp,
    this.lastSeen,
    this.customName,
    required this.addedAt,
    this.room,
    this.token,
    this.colorValue,
    this.favorite = false,
    this.lockable = false,
    this.totalEnergyWs = 0,
    this.bootId,
    this.bootEnergyWs = 0,
    this.temperatureOffset = 0,
  });

  DeviceType get type => DeviceType.fromCode(typeCode);

  String get displayName => customName?.isNotEmpty == true ? customName! : name;

  StoredDevice copyWith({
    String? mac,
    String? name,
    int? typeCode,
    String? lastKnownIp,
    DateTime? lastSeen,
    String? customName,
    DateTime? addedAt,
    String? room,
    String? token,
    int? colorValue,
    bool? favorite,
    bool? lockable,
    double? totalEnergyWs,
    String? bootId,
    double? bootEnergyWs,
    double? temperatureOffset,
  }) {
    return StoredDevice(
      mac: mac ?? this.mac,
      name: name ?? this.name,
      typeCode: typeCode ?? this.typeCode,
      lastKnownIp: lastKnownIp ?? this.lastKnownIp,
      lastSeen: lastSeen ?? this.lastSeen,
      customName: customName ?? this.customName,
      addedAt: addedAt ?? this.addedAt,
      room: room ?? this.room,
      token: token ?? this.token,
      colorValue: colorValue ?? this.colorValue,
      favorite: favorite ?? this.favorite,
      lockable: lockable ?? this.lockable,
      totalEnergyWs: totalEnergyWs ?? this.totalEnergyWs,
      bootId: bootId ?? this.bootId,
      bootEnergyWs: bootEnergyWs ?? this.bootEnergyWs,
      temperatureOffset: temperatureOffset ?? this.temperatureOffset,
    );
  }
}
