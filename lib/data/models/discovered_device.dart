import '../../core/utils/device_type.dart';

/// Device discovered via UDP broadcast (see udp_discovery.dart).
///
/// This is a lightweight value object; the persistent record is [StoredDevice].
class DiscoveredDeviceModel {
  final String mac;
  final String ip;
  final DeviceType type;
  final bool registered;
  final bool cloudConnected;
  final DateTime lastSeen;

  const DiscoveredDeviceModel({
    required this.mac,
    required this.ip,
    required this.type,
    required this.registered,
    required this.cloudConnected,
    required this.lastSeen,
  });

  factory DiscoveredDeviceModel.fromService(DiscoveredDeviceModel d) => d;

  Map<String, dynamic> toJson() => {
    'mac': mac,
    'ip': ip,
    'type': type.name,
    'registered': registered,
    'cloudConnected': cloudConnected,
    'lastSeen': lastSeen.toIso8601String(),
  };
}
