import 'package:flutter/material.dart';

import '../../core/network/device_http_client.dart';
import '../../core/utils/device_type.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/device_info.dart';
import '../../data/models/history_record.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/get_history.dart';

/// Energy history page — firmware >= 5.0.0 on WS2, WSE, WSX.
///
/// Mirrors myStrom's `history.html`: fetches all hourly report records from
/// `/api/v1/history`, groups them by day, and shows a bar chart of per-hour
/// energy (kWh) for the selected date with a date selector and summary
/// (total energy, avg/peak power, interval count). Handles the common edge
/// cases: device unreachable, unsupported firmware, no history yet, and days
/// with fewer than two records (cannot compute deltas).
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const _pageSize = 64;

  late final GetHistory _getHistory;
  late final DeviceRemoteDataSource _remote;

  List<HistoryRecord> _allRecords = [];
  bool _loading = true;
  String? _error;
  bool _supported = true;
  String? _unsupportedReason;

  /// Available date range (local), derived from records.
  DateTime? _newestDate;
  DateTime? _oldestDate;

  /// Selected day (local), normalized to midnight.
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _remote = DeviceRemoteDataSource(
      DeviceHttpClient(token: widget.device.token),
    );
    _getHistory = GetHistory(_remote);
    _load();
  }

  Future<void> _load() async {
    final ip = widget.device.bestIp;
    if (ip == null) {
      setState(() {
        _loading = false;
        _error = 'No IP address';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 1. Verify firmware supports the history API.
      DeviceInfoModel info;
      try {
        info = await _remote.getInfo(ip);
      } catch (_) {
        info = const DeviceInfoModel(
          version: '',
          mac: '',
          ssid: '',
          ip: '',
          mask: '',
          gw: '',
          dns: '',
          static: false,
          connected: false,
          roaming: false,
          type: '',
          name: '',
          connectionStatus: ConnectionStatus(
            ntp: false,
            dns: false,
            connection: false,
            handshake: false,
            login: false,
          ),
        );
      }
      final fw = info.version;
      if (!DeviceType.historyAvailable(widget.device.type, fw)) {
        setState(() {
          _loading = false;
          _supported = false;
          _unsupportedReason = _unsupportedMessage(fw);
        });
        return;
      }

      // 2. Fetch all records.
      final records = await _getHistory(ip);
      if (!mounted) return;
      _allRecords = records;

      if (_allRecords.isEmpty) {
        setState(() {
          _loading = false;
          // Not an error — the device simply has no stored reports yet.
        });
        return;
      }

      // Records are newest-first. Compute local date range.
      final newestTs = _parseTimestamp(_allRecords.first.timestamp);
      final oldestTs = _parseTimestamp(_allRecords.last.timestamp);
      _newestDate = _dayOnly(newestTs);
      _oldestDate = _dayOnly(oldestTs);
      _selectedDate = _newestDate!;

      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _unsupportedMessage(String fw) {
    final type = widget.device.type;
    if (!type.hasHistory) {
      return 'Report history is only available on WS2, WSE and WSX.';
    }
    if (fw.isEmpty) {
      return 'Could not read firmware version. History requires firmware >= 5.0.0.';
    }
    return 'History requires firmware >= 5.0.0 (current: $fw).';
  }

  // ---- Date helpers ----

  /// Parse an ISO-8601 timestamp into a local [DateTime]. The device emits
  /// UTC times with a trailing `Z`; if the suffix is missing, we append it
  /// so the string is interpreted as UTC.
  DateTime _parseTimestamp(String isoStr) {
    if (isoStr.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    final s = isoStr.endsWith('Z') ? isoStr : '${isoStr}Z';
    return DateTime.parse(s).toLocal();
  }

  /// Normalize a [DateTime] to local midnight.
  DateTime _dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  String _formatHour(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _formatFull(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Records for the selected day, sorted oldest-first.
  List<HistoryRecord> _dayRecords(DateTime day) {
    final out = <HistoryRecord>[];
    for (final r in _allRecords) {
      if (_dayOnly(_parseTimestamp(r.timestamp)) == day) {
        out.add(r);
      }
    }
    out.sort((a, b) =>
        _parseTimestamp(a.timestamp).compareTo(_parseTimestamp(b.timestamp)));
    return out;
  }

  void _changeDay(int delta) {
    final next = _selectedDate.add(Duration(days: delta));
    if (_oldestDate != null && next.isBefore(_oldestDate!)) return;
    if (_newestDate != null && next.isAfter(_newestDate!)) return;
    setState(() => _selectedDate = _dayOnly(next));
  }

  void _goToNewest() {
    if (_newestDate != null) setState(() => _selectedDate = _newestDate!);
  }

  Future<void> _pickDate() async {
    if (_oldestDate == null || _newestDate == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _oldestDate!,
      lastDate: _newestDate!,
    );
    if (picked != null) setState(() => _selectedDate = _dayOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Energy History';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('history_back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_supported) {
      return _CenterMessage(
        icon: Icons.history_toggle_off,
        text: _unsupportedReason ?? 'History not supported.',
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_allRecords.isEmpty) {
      return _CenterMessage(
        icon: Icons.inbox,
        text: 'No history data available yet.\n'
            'Reports are stored hourly once the device is on firmware >= 5.0.0.',
      );
    }
    return _HistoryContent(
      records: _dayRecords(_selectedDate),
      selectedDate: _selectedDate,
      oldestDate: _oldestDate,
      newestDate: _newestDate,
      parseTimestamp: _parseTimestamp,
      formatDate: _formatDate,
      formatHour: _formatHour,
      formatFull: _formatFull,
      onPrev: () => _changeDay(-1),
      onNext: () => _changeDay(1),
      onToday: _goToNewest,
      onPick: _pickDate,
    );
  }
}

/// Centered informational message (no data / unsupported).
class _CenterMessage extends StatelessWidget {
  const _CenterMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).hintColor),
            const SizedBox(height: 20),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// All parsed records for the selected day (oldest-first).
class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.records,
    required this.selectedDate,
    required this.oldestDate,
    required this.newestDate,
    required this.parseTimestamp,
    required this.formatDate,
    required this.formatHour,
    required this.formatFull,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onPick,
  });

  final List<HistoryRecord> records;
  final DateTime selectedDate;
  final DateTime? oldestDate;
  final DateTime? newestDate;
  final DateTime Function(String) parseTimestamp;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatHour;
  final String Function(DateTime) formatFull;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final Future<void> Function() onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DateBar(
          selectedDate: selectedDate,
          oldestDate: oldestDate,
          newestDate: newestDate,
          formatDate: formatDate,
          onPrev: onPrev,
          onNext: onNext,
          onToday: onToday,
          onPick: onPick,
        ),
        const SizedBox(height: 16),
        _SummaryGrid(intervals: _computeIntervals()),
        const SizedBox(height: 16),
        _EnergyChart(
          intervals: _computeIntervals(),
          selectedDate: selectedDate,
          formatDate: formatDate,
        ),
        const SizedBox(height: 8),
        _Legend(),
      ],
    );
  }

  /// Compute per-interval energy (kWh) and power (W) from consecutive
  /// records. Requires at least two records for the day; a single record
  /// yields no deltas (energy is cumulative, not instantaneous).
  List<_Interval> _computeIntervals() {
    if (records.length < 2) return const [];
    final out = <_Interval>[];
    for (var i = 1; i < records.length; i++) {
      final t0 = parseTimestamp(records[i - 1].timestamp);
      final t1 = parseTimestamp(records[i].timestamp);
      final dt = t1.difference(t0).inSeconds;
      final dWs = records[i].energyWs - records[i - 1].energyWs;
      final kwh = dWs / 3600000;
      final watts = dt > 0 ? dWs / dt : 0.0;
      out.add(_Interval(
        kwh: kwh,
        watts: watts,
        hour: formatHour(t1),
        fullTime: formatFull(t1),
      ));
    }
    return out;
  }
}

/// One computed interval between two consecutive records.
class _Interval {
  final double kwh;
  final double watts;
  final String hour;
  final String fullTime;

  const _Interval({
    required this.kwh,
    required this.watts,
    required this.hour,
    required this.fullTime,
  });
}

/// Date navigation bar: prev / date label (tap to pick) / next, plus Today.
class _DateBar extends StatelessWidget {
  const _DateBar({
    required this.selectedDate,
    required this.oldestDate,
    required this.newestDate,
    required this.formatDate,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onPick,
  });

  final DateTime selectedDate;
  final DateTime? oldestDate;
  final DateTime? newestDate;
  final String Function(DateTime) formatDate;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final Future<void> Function() onPick;

  @override
  Widget build(BuildContext context) {
    final canPrev =
        oldestDate == null || selectedDate.isAfter(oldestDate!);
    final canNext =
        newestDate == null || selectedDate.isBefore(newestDate!);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton.outlined(
          key: const Key('history_prev_day'),
          icon: const Icon(Icons.chevron_left),
          onPressed: canPrev ? onPrev : null,
          tooltip: 'Previous day',
        ),
        InkWell(
          key: const Key('history_date_label'),
          borderRadius: BorderRadius.circular(8),
          onTap: onPick,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(
                  formatDate(selectedDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
        IconButton.outlined(
          key: const Key('history_next_day'),
          icon: const Icon(Icons.chevron_right),
          onPressed: canNext ? onNext : null,
          tooltip: 'Next day',
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          key: const Key('history_today'),
          onPressed: onToday,
          icon: const Icon(Icons.today, size: 18),
          label: const Text('Latest'),
        ),
      ],
    );
  }
}

/// Summary cards: total energy, avg power, peak power, interval count.
class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.intervals});
  final List<_Interval> intervals;

  @override
  Widget build(BuildContext context) {
    if (intervals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No data for the selected day')),
        ),
      );
    }
    var totalKwh = 0.0, sumPwr = 0.0, maxPwr = -double.infinity;
    for (final i in intervals) {
      totalKwh += i.kwh;
      sumPwr += i.watts;
      if (i.watts > maxPwr) maxPwr = i.watts;
    }
    final avgPwr = sumPwr / intervals.length;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: _summaryWidth(context),
          height: 64,
          child: _SummaryCard('Total Energy', '${totalKwh.toStringAsFixed(4)} kWh'),
        ),
        SizedBox(
          width: _summaryWidth(context),
          height: 64,
          child: _SummaryCard('Avg Power', '${avgPwr.toStringAsFixed(1)} W'),
        ),
        SizedBox(
          width: _summaryWidth(context),
          height: 64,
          child: _SummaryCard('Peak Power', '${maxPwr.toStringAsFixed(1)} W'),
        ),
        SizedBox(
          width: _summaryWidth(context),
          height: 64,
          child: _SummaryCard('Intervals', '${intervals.length}'),
        ),
      ],
    );
  }
}

double _summaryWidth(BuildContext context) {
  final screenW = MediaQuery.of(context).size.width;
  // Two columns with a 12px gap: (W - 32 padding - 12 gap) / 2.
  return (screenW - 32 - 12) / 2;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// SVG-like bar chart drawn with [CustomPaint], mirroring history.html.
class _EnergyChart extends StatelessWidget {
  const _EnergyChart({
    required this.intervals,
    required this.selectedDate,
    required this.formatDate,
  });

  final List<_Interval> intervals;
  final DateTime selectedDate;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    if (intervals.isEmpty) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Text(
            'No data for ${formatDate(selectedDate)}',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 15),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
        child: SizedBox(
          height: 260,
          child: CustomPaint(
            size: Size.infinite,
            painter: _EnergyChartPainter(intervals: intervals),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _EnergyChartPainter extends CustomPainter {
  _EnergyChartPainter({required this.intervals});
  final List<_Interval> intervals;

  static const _margin = EdgeInsets.only(left: 48, top: 16, right: 12, bottom: 36);
  static const _gridLines = 5;
  static const _barColor = Color(0xFF45b40a);

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - _margin.left - _margin.right;
    final plotH = size.height - _margin.top - _margin.bottom;

    var maxKwh = 0.0;
    for (final i in intervals) {
      if (i.kwh > maxKwh) maxKwh = i.kwh;
    }
    if (maxKwh <= 0) maxKwh = 0.001;
    maxKwh *= 1.15;

    final gridPaint = Paint()..color = const Color(0xFFEEEEEE);
    final axisPaint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 1;
    final barPaint = Paint()..color = _barColor;

    // Grid + Y labels.
    for (var g = 0; g <= _gridLines; g++) {
      final y = _margin.top + plotH * g / _gridLines;
      canvas.drawLine(
        Offset(_margin.left, y),
        Offset(size.width - _margin.right, y),
        gridPaint,
      );
      final yVal = maxKwh - maxKwh * g / _gridLines;
      _drawText(
        canvas,
        yVal.toStringAsFixed(3),
        Offset(_margin.left - 6, y - 7),
        anchor: TextAnchor.end,
        style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
      );
    }

    // Axes.
    canvas.drawLine(
      Offset(_margin.left, _margin.top),
      Offset(_margin.left, size.height - _margin.bottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(_margin.left, size.height - _margin.bottom),
      Offset(size.width - _margin.right, size.height - _margin.bottom),
      axisPaint,
    );

    // X labels (~8 evenly spaced).
    final xStep = (intervals.length / 8).ceil().clamp(1, intervals.length);
    for (var i = 0; i < intervals.length; i += xStep) {
      final x = _margin.left + (i + 0.5) / intervals.length * plotW;
      _drawText(
        canvas,
        intervals[i].hour,
        Offset(x, size.height - _margin.bottom + 6),
        anchor: TextAnchor.middle,
        style: const TextStyle(fontSize: 9, color: Color(0xFF888888)),
      );
    }

    // Bars.
    const barGap = 2.0;
    final barW = (plotW / intervals.length - barGap).clamp(1.0, double.infinity);
    for (var i = 0; i < intervals.length; i++) {
      final barH = intervals[i].kwh / maxKwh * plotH;
      final drawn = barH < 0.5 ? 0.5 : barH;
      final bx = _margin.left + i / intervals.length * plotW + barGap / 2;
      final by = _margin.top + plotH - drawn;
      canvas.drawRect(Rect.fromLTWH(bx, by, barW, drawn), barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyChartPainter old) =>
      old.intervals != intervals;
}

enum TextAnchor { start, middle, end }

void _drawText(
  Canvas canvas,
  String text,
  Offset pos, {
  TextAnchor anchor = TextAnchor.start,
  TextStyle style = const TextStyle(),
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: anchor == TextAnchor.middle
        ? TextAlign.center
        : (anchor == TextAnchor.end ? TextAlign.right : TextAlign.left),
  )..layout();
  var dx = pos.dx;
  if (anchor == TextAnchor.middle) dx -= tp.width / 2;
  if (anchor == TextAnchor.end) dx -= tp.width;
  tp.paint(canvas, Offset(dx, pos.dy));
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 14, height: 14, color: const Color(0xFF45b40a)),
        const SizedBox(width: 6),
        Text(
          'Energy per interval (kWh)',
          style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}