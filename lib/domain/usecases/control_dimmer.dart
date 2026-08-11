import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/dimmer_state.dart';

/// Control dimmer (WLL).
class ControlDimmer {
  ControlDimmer(this._remote);

  final DeviceRemoteDataSource _remote;

  Future<DimmerStateModel> getState(String ip) => _remote.getDimmerState(ip);

  Future<void> turnOn(String ip, {int? ramp}) =>
      _remote.setDimmerState(ip, action: 'on', ramp: ramp);

  Future<void> turnOff(String ip, {int? ramp}) =>
      _remote.setDimmerState(ip, action: 'off', ramp: ramp);

  Future<void> toggle(String ip, {int? ramp}) =>
      _remote.setDimmerState(ip, action: 'toggle', ramp: ramp);

  Future<void> setValue(String ip, {required int value, int? ramp}) =>
      _remote.setDimmerState(ip, action: 'on', value: value, ramp: ramp);
}
