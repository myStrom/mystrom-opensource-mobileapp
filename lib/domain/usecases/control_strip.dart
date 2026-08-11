import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/strip_state.dart';

/// Control LED strip (WRS).
class ControlStrip {
  ControlStrip(this._remote);

  final DeviceRemoteDataSource _remote;

  Future<StripStateModel> getState(String ip) => _remote.getStripState(ip);

  Future<void> turnOn(String ip, {int? ramp}) =>
      _remote.setStripState(ip, action: 'on', ramp: ramp);

  Future<void> turnOff(String ip, {int? ramp}) =>
      _remote.setStripState(ip, action: 'off', ramp: ramp);

  Future<void> toggle(String ip, {int? ramp}) =>
      _remote.setStripState(ip, action: 'toggle', ramp: ramp);

  Future<void> setColor(
    String ip, {
    required String color,
    String mode = 'hsv',
    int? ramp,
  }) => _remote.setStripState(
    ip,
    action: 'on',
    color: color,
    mode: mode,
    ramp: ramp,
  );

  Future<void> stop(String ip) => _remote.stopStripTransition(ip);

  /// Switch the strip's color mode (hsv | rgb) without changing color.
  Future<void> setStripMode(String ip, {required String mode}) =>
      _remote.setStripState(ip, mode: mode);

  /// Get the channel mode (colors | channels | cold_warm).
  Future<String> getChMode(String ip) => _remote.getChMode(ip);

  /// Set the channel mode (colors | channels | cold_warm).
  Future<void> setChMode(String ip, {required String chMode}) =>
      _remote.setChMode(ip, chMode: chMode);
}
