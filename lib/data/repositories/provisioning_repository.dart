import '../../core/config/app_config.dart';
import '../datasources/device_remote_ds.dart';
import '../models/device_info.dart';
import '../models/wifi_network.dart';

/// WiFi provisioning via SoftAP or WPS.
class ProvisioningRepository {
  ProvisioningRepository(this._remote, {DeviceRemoteDataSource? infoRemote})
    : _infoRemote = infoRemote ?? _remote;

  final DeviceRemoteDataSource _remote;
  final DeviceRemoteDataSource _infoRemote;

  /// Scan for WiFi networks via a device in AP mode (default 192.168.254.1).
  ///
  /// Retries internally for up to 15s because the device scan takes ~5s.
  Future<List<WifiNetworkModel>> scanNetworks([
    String ip = AppConfig.softApDefaultIp,
  ]) {
    return _remote.scanWifiWithRetry(ip);
  }

  /// Fetch `/api/v1/info` from a device in AP mode to confirm the device
  /// type and MAC before sending credentials. Returns `null` if the
  /// device does not respond (older firmware may not expose /info in AP).
  Future<DeviceInfoModel?> fetchInfo([String ip = AppConfig.softApDefaultIp]) =>
      _infoRemote.probeInfo(ip);

  /// Send WiFi credentials to a device in AP mode.
  ///
  /// Handles both new firmware (with `roaming`) and legacy
  /// firmware (Bulb/Button) which rejects `roaming` with 400.
  Future<void> sendCredentials(
    String ssid,
    String? password, {
    String ip = AppConfig.softApDefaultIp,
    String? staticIp,
    String? mask,
    String? gw,
    String? dns,
    bool roaming = false,
  }) {
    return _remote.connectWifi(
      ip,
      ssid: ssid,
      password: password,
      staticIp: staticIp,
      mask: mask,
      gw: gw,
      dns: dns,
      roaming: roaming,
    );
  }

  /// Trigger WPS on a device (AP mode or already on network).
  Future<void> triggerWps([String ip = AppConfig.softApDefaultIp]) {
    return _remote.triggerWps(ip);
  }
}
