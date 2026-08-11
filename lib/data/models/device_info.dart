/// Parsed response of `GET /info`.
class DeviceInfoModel {
  final String version;
  final String mac;
  final String ssid;
  final String ip;
  final String mask;
  final String gw;
  final String dns;
  final bool static;
  final bool connected;
  final bool roaming;
  final String type;
  final String name;
  final ConnectionStatus connectionStatus;

  const DeviceInfoModel({
    required this.version,
    required this.mac,
    required this.ssid,
    required this.ip,
    required this.mask,
    required this.gw,
    required this.dns,
    required this.static,
    required this.connected,
    required this.roaming,
    required this.type,
    required this.name,
    required this.connectionStatus,
  });

  factory DeviceInfoModel.fromJson(Map<String, dynamic> j) {
    final cs = (j['connectionStatus'] as Map<String, dynamic>?) ?? {};
    // `type` can be a String ("wse", "bulb") or an int (102, 118).
    final rawType = j['type'];
    final typeStr = rawType is int
        ? rawType.toString()
        : rawType as String? ?? '';
    return DeviceInfoModel(
      version: j['version'] as String? ?? '',
      mac: j['mac'] as String? ?? '',
      ssid: j['ssid'] as String? ?? '',
      ip: j['ip'] as String? ?? '',
      mask: j['mask'] as String? ?? '',
      gw: j['gw'] as String? ?? '',
      dns: j['dns'] as String? ?? '',
      static: j['static'] as bool? ?? false,
      connected: j['connected'] as bool? ?? false,
      roaming: j['roaming'] as bool? ?? false,
      type: typeStr,
      name: j['name'] as String? ?? '',
      connectionStatus: ConnectionStatus.fromJson(cs),
    );
  }
}

class ConnectionStatus {
  final bool ntp;
  final bool dns;
  final bool connection;
  final bool handshake;
  final bool login;

  const ConnectionStatus({
    required this.ntp,
    required this.dns,
    required this.connection,
    required this.handshake,
    required this.login,
  });

  factory ConnectionStatus.fromJson(Map<String, dynamic> j) {
    return ConnectionStatus(
      ntp: j['ntp'] as bool? ?? false,
      dns: j['dns'] as bool? ?? false,
      connection: j['connection'] as bool? ?? false,
      handshake: j['handshake'] as bool? ?? false,
      login: j['login'] as bool? ?? false,
    );
  }
}
