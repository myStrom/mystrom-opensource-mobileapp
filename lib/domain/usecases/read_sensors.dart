import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/button_sensor_state.dart';
import '../../data/models/pir_state.dart';

/// Read sensor data from PIR (WMS) or button-se (BP2, BM1).
class ReadSensors {
  ReadSensors(this._remote);

  final DeviceRemoteDataSource _remote;

  Future<PirStateModel> getPir(String ip) => _remote.getPirSensors(ip);

  Future<ButtonSensorStateModel> getButtonSe(String ip) =>
      _remote.getButtonSeSensors(ip);
}
