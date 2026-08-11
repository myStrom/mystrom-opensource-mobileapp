import '../datasources/device_local_ds.dart';
import '../models/stored_device.dart';

/// CRUD repository wrapping the local Hive data source.
class DeviceRepository {
  DeviceRepository(this._local);

  final DeviceLocalDataSource _local;

  List<StoredDevice> getAll() => _local.getAll();

  StoredDevice? getByMac(String mac) => _local.getByMac(mac);

  Future<void> add(StoredDevice device) => _local.upsert(device);

  Future<void> update(StoredDevice device) => _local.upsert(device);

  Future<void> remove(String mac) => _local.delete(mac);

  Future<void> updateDiscoveryInfo(String mac, String ip, DateTime seen) async {
    await _local.updateIpAndSeen(mac, ip, seen);
  }
}
