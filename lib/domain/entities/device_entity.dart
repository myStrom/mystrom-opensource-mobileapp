import '../../core/utils/device_type.dart';

/// Domain entity representing a device known to the app.
///
/// Combines persisted info (name, room, token) with live discovery data
/// (current IP, online status).
class DeviceEntity {
  final String mac;
  final String name;
  final DeviceType type;
  final String? lastKnownIp;
  final DateTime? lastSeen;
  final String? customName;
  final String? room;
  final String? token;
  final DateTime addedAt;

  /// Live IP from UDP discovery (null if not currently seen).
  final String? discoveryIp;
  final bool registered;
  final bool cloudConnected;
  final bool httpReachable;

  /// Optional custom color (ARGB value) assigned by the user.
  final int? colorValue;

  /// Whether the user marked this device as favorite.
  final bool favorite;

  /// When true, the on/off state of this device cannot be toggled from
  /// the app (e.g. a fridge). Timers and scheduler are still allowed.
  final bool lockable;

  /// Long-term accumulated energy across reboots, in watt-seconds (Ws).
  final double totalEnergyWs;

  /// The device boot identifier last seen by the app.
  final String? bootId;

  /// Energy accumulated for the current boot cycle, in Ws.
  final double bootEnergyWs;

  /// User-adjusted temperature offset in °C (range -30..+30).
  /// Applied to the raw temperature before display.
  final double temperatureOffset;

  const DeviceEntity({
    required this.mac,
    required this.name,
    required this.type,
    this.lastKnownIp,
    this.lastSeen,
    this.customName,
    this.room,
    this.token,
    required this.addedAt,
    this.discoveryIp,
    this.registered = false,
    this.cloudConnected = false,
    this.httpReachable = false,
    this.colorValue,
    this.favorite = false,
    this.lockable = false,
    this.totalEnergyWs = 0,
    this.bootId,
    this.bootEnergyWs = 0,
    this.temperatureOffset = 0,
  });

  /// Best IP to use for communication: prefer live discovery IP,
  /// fall back to last known IP from DB.
  String? get bestIp => discoveryIp ?? lastKnownIp;

  bool get isOffline =>
      lastSeen == null ||
      DateTime.now().difference(lastSeen!) > const Duration(seconds: 30);

  String get displayName =>
      (customName != null && customName!.isNotEmpty) ? customName! : name;

  DeviceEntity copyWith({
    String? mac,
    String? name,
    DeviceType? type,
    String? lastKnownIp,
    DateTime? lastSeen,
    String? customName,
    String? room,
    String? token,
    DateTime? addedAt,
    String? discoveryIp,
    bool? registered,
    bool? cloudConnected,
    bool? httpReachable,
    int? colorValue,
    bool? favorite,
    bool? lockable,
    double? totalEnergyWs,
    String? bootId,
    double? bootEnergyWs,
    double? temperatureOffset,
  }) {
    return DeviceEntity(
      mac: mac ?? this.mac,
      name: name ?? this.name,
      type: type ?? this.type,
      lastKnownIp: lastKnownIp ?? this.lastKnownIp,
      lastSeen: lastSeen ?? this.lastSeen,
      customName: customName ?? this.customName,
      room: room ?? this.room,
      token: token ?? this.token,
      addedAt: addedAt ?? this.addedAt,
      discoveryIp: discoveryIp ?? this.discoveryIp,
      registered: registered ?? this.registered,
      cloudConnected: cloudConnected ?? this.cloudConnected,
      httpReachable: httpReachable ?? this.httpReachable,
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
