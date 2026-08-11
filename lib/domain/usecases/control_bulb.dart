import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/bulb_state.dart';

/// Control bulb.
class ControlBulb {
  ControlBulb(this._remote);

  final DeviceRemoteDataSource _remote;

  Future<BulbStateModel> getState(String ip) => _remote.getBulbState(ip);

  Future<void> turnOn(String ip, {int? ramp}) =>
      _remote.setBulbState(ip, action: 'on', ramp: ramp);

  Future<void> turnOff(String ip, {int? ramp}) =>
      _remote.setBulbState(ip, action: 'off', ramp: ramp);

  Future<void> toggle(String ip, {int? ramp}) =>
      _remote.setBulbState(ip, action: 'toggle', ramp: ramp);

  Future<void> setColor(
    String ip, {
    required String color,
    String mode = 'hsv',
    int? ramp,
  }) => _remote.setBulbState(
    ip,
    action: 'on',
    color: color,
    mode: mode,
    ramp: ramp,
  );

  /// Switch the device to a different color mode without changing color.
  /// Only the `mode` parameter is sent — every parameter in the POST
  /// /api/v1/device/self request is optional.
  Future<void> setMode(String ip, {required String mode}) =>
      _remote.setBulbState(ip, mode: mode);
}
