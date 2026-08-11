import '../../data/datasources/device_remote_ds.dart';

/// Set a timer action on switch/plug/strip/bulb devices.
class SetTimer {
  SetTimer(this._remote);

  final DeviceRemoteDataSource _remote;

  /// mode: none | on | off | toggle
  ///
  /// [path] overrides the timer endpoint (e.g. the bulb uses
  /// `/api/v1/timer/self`). Defaults to the switch/strip `/timer`.
  Future<void> call(
    String ip, {
    required String mode,
    required int seconds,
    String? path,
  }) => _remote.setTimer(ip, mode: mode, seconds: seconds, path: path);
}
