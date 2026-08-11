import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/switch_state.dart';

/// Control switch/plug relay (WS2, WSE, WSX, LCS).
class ControlSwitch {
  ControlSwitch(this._remote);

  final DeviceRemoteDataSource _remote;

  Future<SwitchStateModel> getState(String ip) => _remote.getRelay(ip);

  Future<SwitchStateModel> turnOn(String ip) => _remote.setRelay(ip, on: true);

  Future<SwitchStateModel> turnOff(String ip) =>
      _remote.setRelay(ip, on: false);

  Future<SwitchStateModel> toggle(String ip) => _remote.toggleRelay(ip);

  Future<SwitchStateModel> getReport(String ip) => _remote.getReport(ip);
}
