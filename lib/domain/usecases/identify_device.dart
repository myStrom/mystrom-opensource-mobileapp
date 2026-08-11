import '../../core/utils/device_type.dart';
import '../../data/datasources/device_remote_ds.dart';

/// Identify a device so the user can tell which physical device they are
/// adding or configuring.
///
/// - WS2, WSE, WRS, WLL, WMS (PIR): `POST /identify` — blink/confirm.
///   The endpoint returns 204 on success or 400 when the device is paired
///   with HomeKit (it is part of the HomeKit API). Any error or timeout is
///   silently ignored — identification is best-effort.
///
/// - Bulb: identification goes through the bulb timer API:
///   `POST /api/v1/timer/<mac>?mode=toggle&time=3&color=120;100;100`
///   which blinks the bulb for 3 seconds. Errors are also swallowed.
///
/// Other device types (WSX, LCS, buttons) do not support identification and
/// the call is a no-op.
class IdentifyDevice {
  IdentifyDevice(this._remote);

  final DeviceRemoteDataSource _remote;

  /// Triggers identification on [deviceType] reachable at [ip].
  ///
  /// [mac] is only required for the bulb (timer path uses the device MAC).
  /// Never throws.
  Future<void> call(
    String ip, {
    required DeviceType deviceType,
    String? mac,
  }) async {
    if (!deviceType.identifyAvailable) return;
    if (deviceType.identifyViaTimer) {
      assert(
        mac != null && mac.isNotEmpty,
        'Bulb identification requires the device MAC',
      );
      await _remote.identifyBulb(ip, mac!);
    } else {
      await _remote.identify(ip);
    }
  }
}
