import 'package:hive/hive.dart';

import '../../core/config/app_config.dart';
import '../models/stored_device.dart';

/// Local Hive-backed data source for persisted devices.
class DeviceLocalDataSource {
  late Box<StoredDevice> _box;

  Future<void> init() async {
    _box = await Hive.openBox<StoredDevice>(AppConfig.hiveDevicesBox);
  }

  List<StoredDevice> getAll() => _box.values.toList();

  StoredDevice? getByMac(String mac) => _box.get(mac);

  Future<void> upsert(StoredDevice device) => _box.put(device.mac, device);

  Future<void> delete(String mac) => _box.delete(mac);

  Future<void> updateIpAndSeen(String mac, String ip, DateTime seen) async {
    final d = _box.get(mac);
    if (d == null) return;
    d.lastKnownIp = ip;
    d.lastSeen = seen;
    await d.save();
  }
}
