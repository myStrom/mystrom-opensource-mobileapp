import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/scheduler_item.dart';

/// Scheduler use case (firmware >= 5.0.0; WS2, WSE, WRS, WMS, WSX, WLL).
///
/// Times are kept in UTC by the device; the presentation layer is responsible
/// for converting to/from local time for display.
class ControlScheduler {
  ControlScheduler(this._remote);

  final DeviceRemoteDataSource _remote;

  Future<List<SchedulerItem>> get(String ip) => _remote.getScheduler(ip);

  Future<List<SchedulerItem>> set(String ip, List<SchedulerItem> items) =>
      _remote.setScheduler(ip, items);
}
