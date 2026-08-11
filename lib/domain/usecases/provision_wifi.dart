import '../../core/config/app_config.dart';
import '../../data/models/device_info.dart';
import '../../data/repositories/provisioning_repository.dart';
import '../../data/models/wifi_network.dart';

/// WiFi provisioning via SoftAP or WPS.
class ProvisionWifi {
  ProvisionWifi(this._repo);

  final ProvisioningRepository _repo;

  Future<List<WifiNetworkModel>> scanNetworks([String? ip]) =>
      _repo.scanNetworks(ip ?? AppConfig.softApDefaultIp);

  /// Fetch `/api/v1/info` from the device AP to confirm type & MAC.
  /// Returns `null` if the device does not respond.
  Future<DeviceInfoModel?> fetchInfo([String? ip]) =>
      _repo.fetchInfo(ip ?? AppConfig.softApDefaultIp);

  Future<void> sendCredentials(
    String ssid,
    String? password, {
    String? ip,
    String? staticIp,
    String? mask,
    String? gw,
    String? dns,
    bool roaming = false,
  }) => _repo.sendCredentials(
    ssid,
    password,
    ip: ip ?? AppConfig.softApDefaultIp,
    staticIp: staticIp,
    mask: mask,
    gw: gw,
    dns: dns,
    roaming: roaming,
  );

  Future<void> triggerWps([String? ip]) =>
      _repo.triggerWps(ip ?? AppConfig.softApDefaultIp);
}
