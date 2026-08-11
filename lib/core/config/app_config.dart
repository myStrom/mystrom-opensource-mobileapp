/// Central configuration: ports, timeouts, constants.
class AppConfig {
  AppConfig._();

  // UDP discovery
  static const int udpDiscoveryPort = 7979;
  static const int udpPacketMinSize = 8; // MAC(6) + type(1) + flags(1)

  // HTTP
  static const int deviceHttpPort = 80;
  static const Duration httpTimeout = Duration(seconds: 10);
  static const Duration provisioningTimeout = Duration(seconds: 30);
  static const String softApDefaultIp = '192.168.254.1';

  // Discovery staleness
  static const Duration offlineThreshold = Duration(seconds: 30);

  // Hive box name
  static const String hiveDevicesBox = 'devices';
  static const String hiveScenesBox = 'scenes';
}
