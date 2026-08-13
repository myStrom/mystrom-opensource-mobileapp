import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/history_record.dart';

/// Report history use case (firmware >= 5.0.0; WS2, WSE, WSX).
///
/// Fetches hourly energy records stored on the device. Records come
/// newest-first; the presentation layer groups them by day and computes
/// per-interval energy deltas.
class GetHistory {
  GetHistory(this._remote);

  final DeviceRemoteDataSource _remote;

  /// Returns all stored records (newest-first). An empty list means the
  /// device has no history yet.
  Future<List<HistoryRecord>> call(String ip) => _remote.getAllHistory(ip);
}