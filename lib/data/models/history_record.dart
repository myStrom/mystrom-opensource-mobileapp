/// A single hourly report record from `GET /api/v1/history`.
///
/// Firmware >= 5.0.0 on WS2, WSE, WSX stores one record per hour. Each
/// record contains an ISO-8601 UTC timestamp `t` and a cumulative energy
/// counter `e` expressed in watt-seconds (Ws). Per-interval energy (the
/// amount consumed between two consecutive records) is computed by the
/// caller as `e[i] - e[i-1]`.
class HistoryRecord {
  /// ISO-8601 UTC timestamp as returned by the device (e.g.
  /// `2026-08-13T12:00:25Z`). Older firmware may omit the trailing `Z`;
  /// callers normalize it before parsing.
  final String timestamp;

  /// Cumulative energy counter in watt-seconds (Ws) at [timestamp].
  final double energyWs;

  const HistoryRecord({required this.timestamp, required this.energyWs});

  factory HistoryRecord.fromJson(Map<String, dynamic> j) {
    return HistoryRecord(
      timestamp: j['t'] as String? ?? '',
      energyWs: (j['e'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// One page of history records returned by `GET /api/v1/history?page=<n>`.
///
/// Records come newest-first. The page size is 64 records on current
/// firmware; [count] reflects the number of records in this page, which
/// is `< 64` for the last (oldest) page.
class HistoryPage {
  final List<HistoryRecord> records;
  final int count;
  final int offset;
  final int page;

  const HistoryPage({
    required this.records,
    required this.count,
    required this.offset,
    required this.page,
  });

  factory HistoryPage.fromJson(Map<String, dynamic> j) {
    final rawRecords = j['records'];
    return HistoryPage(
      records: rawRecords is List
          ? rawRecords
              .map((r) => HistoryRecord.fromJson(r as Map<String, dynamic>))
              .toList()
          : const [],
      count: (j['count'] as num?)?.toInt() ?? 0,
      offset: (j['offset'] as num?)?.toInt() ?? 0,
      page: (j['page'] as num?)?.toInt() ?? 0,
    );
  }
}