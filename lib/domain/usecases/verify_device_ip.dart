import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/device_info.dart';

/// Verify that a device's IP is still valid by calling /info and
/// comparing the returned MAC.
class VerifyDeviceIp {
  VerifyDeviceIp(this._remote);

  final DeviceRemoteDataSource _remote;

  /// Returns the verified [DeviceInfoModel] if the MAC matches,
  /// otherwise null.
  Future<DeviceInfoModel?> call(String ip, String expectedMac) async {
    try {
      final info = await _remote.getInfo(ip);
      // /info returns MAC without colons; normalise both for comparison.
      final normalised = info.mac.replaceAll(':', '').toUpperCase();
      final expected = expectedMac.replaceAll(':', '').toUpperCase();
      if (normalised == expected) return info;
      return null;
    } catch (_) {
      return null;
    }
  }
}
