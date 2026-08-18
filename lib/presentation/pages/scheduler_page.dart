import 'package:flutter/material.dart';

import '../../core/network/device_http_client.dart';
import '../../core/utils/device_type.dart';
import '../../core/utils/scheduler_time.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/device_info.dart';
import '../../data/models/scheduler_item.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/control_scheduler.dart';

/// Scheduler page — firmware >= 5.0.0 on WS2, WSE, WRS, WMS, WSX, WLL only.
///
/// Mirrors myStrom's `scheduler.html`: GET/POST `/api/v1/scheduler` with the
/// full schedule list. Times are stored as UTC on the device; this page
/// converts to the device's reported local time for editing and back to UTC
/// before saving. Optional color (WRS), ramp (WRS + WLL) and value (WLL)
/// fields are revealed per device variant.
class SchedulerPage extends StatefulWidget {
  const SchedulerPage({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<SchedulerPage> createState() => _SchedulerPageState();
}

class _SchedulerPageState extends State<SchedulerPage> {
  static const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  late final ControlScheduler _control;
  late final DeviceRemoteDataSource _remote;

  List<SchedulerItem> _items = [];
  bool _loading = true;
  String? _error;
  bool _dirty = false;

  // Variant capabilities discovered from /info.
  bool _hasColor = false; // WRS
  bool _hasRamp = false; // WRS + WLL
  bool _hasValue = false; // WLL
  bool _schedulerSupported = false;
  String? _unsupportedReason;

  @override
  void initState() {
    super.initState();
    _remote = DeviceRemoteDataSource(
      DeviceHttpClient(token: widget.device.token),
    );
    _control = ControlScheduler(_remote);
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
      // 1. Discover variant + firmware so we can decide capability flags.
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
      _resolveCapabilities(info);

      if (!_schedulerSupported) {
        setState(() {
          _loading = false;
          _error =
              _unsupportedReason ?? 'Scheduler not supported on this device';
        });
        return;
      }

      // 2. Load the schedule list and convert UTC -> local for display.
      final raw = await _control.get(ip);
      final local = raw
          .map<SchedulerItem>(SchedulerTimeConverter.utcToLocal)
          .toList();
      local.sort(_compareItems);
      setState(() {
        _items = local;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _resolveCapabilities(DeviceInfoModel info) {
    final type = widget.device.type;
    final fw = info.version;
    if (!DeviceType.schedulerAvailable(type, fw)) {
      _schedulerSupported = false;
      if (!type.hasScheduler) {
        _unsupportedReason =
            'Scheduler is only available on WS2, WSE, WRS, WMS, WSX and WLL.';
      } else if (fw.isEmpty) {
        _unsupportedReason =
            'Could not read firmware version. Requires firmware >= 5.0.0.';
      } else {
        _unsupportedReason = 'Requires firmware >= 5.0.0 (current: $fw).';
      }
      return;
    }
    _schedulerSupported = true;
    // The /info `type` field is a string variant reported by the device.
    final variant = info.type.toLowerCase();
    if (type == DeviceType.wrs || variant == 'strip' || variant == 'wrs') {
      _hasColor = true;
      _hasRamp = true;
    } else if (type == DeviceType.wll || variant == 'wll') {
      _hasRamp = true;
      _hasValue = true;
    }
  }

  int _compareItems(SchedulerItem a, SchedulerItem b) {
    final ad = a.days.isEmpty
        ? 7
        : SchedulerTimeConverter.dayNames.indexOf(a.days.first);
    final bd = b.days.isEmpty
        ? 7
        : SchedulerTimeConverter.dayNames.indexOf(b.days.first);
    final c = ad.compareTo(bd);
    if (c != 0) return c;
    return (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
  }

  Future<void> _save() async {
    final ip = widget.device.bestIp;
    if (ip == null) return;
    try {
      final utc = _items
          .map<SchedulerItem>(SchedulerTimeConverter.localToUtc)
          .toList();
      final saved = await _control.set(ip, utc);
      final local = saved
          .map<SchedulerItem>(SchedulerTimeConverter.utcToLocal)
          .toList();
      local.sort(_compareItems);
      setState(() {
        _items = local;
        _dirty = false;
      });
      _snack('Schedule saved');
    } catch (e) {
      _snack('Save failed: $e');
    }
  }

  void _addItem(SchedulerItem item) {
    setState(() {
      _items = [..._items, item]..sort(_compareItems);
      _dirty = true;
    });
  }

  void _removeAt(int index) {
    setState(() {
      _items = List<SchedulerItem>.from(_items)..removeAt(index);
      _dirty = true;
    });
  }

  void _updateAt(int index, SchedulerItem item) {
    setState(() {
      _items = List<SchedulerItem>.from(_items)..[index] = item;
      _items.sort(_compareItems);
      _dirty = true;
    });
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to quit without saving?',
            ),
            actions: [
              TextButton(
                key: const Key('scheduler_discard_cancel'),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('scheduler_discard_confirm'),
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Quit without saving'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_dirty) {
          Navigator.pop(context);
          return;
        }
        final discard = await _confirmDiscard(context);
        if (discard && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('scheduler_back_button'),
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text('${widget.device.displayName} — Scheduler'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload',
              onPressed: _load,
            ),
          ],
        ),
        body: _buildBody(context),
        floatingActionButton: _schedulerSupported && !_loading
            ? FloatingActionButton.extended(
                key: const Key('scheduler_save_fab'),
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save All'),
              )
            : null,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.red.shade100,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!),
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _AddForm(
          hasColor: _hasColor,
          hasRamp: _hasRamp,
          hasValue: _hasValue,
          onAdd: _addItem,
        ),
        const SizedBox(height: 16),
        if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No schedules yet')),
          )
        else
          for (var i = 0; i < _items.length; i++)
            _SchedulerCard(
              key: ValueKey('item-$i-${_items[i].hour}-${_items[i].minute}'),
              index: i,
              item: _items[i],
              hasColor: _hasColor,
              hasRamp: _hasRamp,
              hasValue: _hasValue,
              onChanged: (item) => _updateAt(i, item),
              onDelete: () => _removeAt(i),
            ),
      ],
    );
  }
}

/// Form for adding a new schedule entry. Emits a fully populated [SchedulerItem]
/// via [onAdd]; the parent is responsible for converting to UTC on save.
class _AddForm extends StatefulWidget {
  const _AddForm({
    required this.hasColor,
    required this.hasRamp,
    required this.hasValue,
    required this.onAdd,
  });

  final bool hasColor;
  final bool hasRamp;
  final bool hasValue;
  final void Function(SchedulerItem) onAdd;

  @override
  State<_AddForm> createState() => _AddFormState();
}

class _AddFormState extends State<_AddForm> {
  final _hourCtrl = TextEditingController(text: '8');
  final _minuteCtrl = TextEditingController(text: '0');
  final _colorCtrl = TextEditingController();
  final _rampCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  String _action = 'on';
  late Set<String> _days; // short names: sun..sat

  @override
  void initState() {
    super.initState();
    _days = SchedulerTimeConverter.dayNames.toSet();
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _colorCtrl.dispose();
    _rampCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final hour = int.tryParse(_hourCtrl.text) ?? 0;
    final minute = int.tryParse(_minuteCtrl.text) ?? 0;
    // Parse HSV string "H;S;V" into a map for the new scheduler API.
    String? mode;
    Map<String, dynamic>? hsv;
    if (widget.hasColor && _colorCtrl.text.isNotEmpty) {
      final parts = _colorCtrl.text.split(';');
      if (parts.length == 3) {
        mode = 'hsv';
        hsv = {
          'hue': int.tryParse(parts[0]) ?? 0,
          'saturation': int.tryParse(parts[1]) ?? 100,
          'value': int.tryParse(parts[2]) ?? 100,
        };
      }
    }
    final item = SchedulerItem(
      enable: true,
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
      action: _action,
      days: SchedulerTimeConverter.dayNames.where(_days.contains).toList(),
      mode: mode,
      hsv: hsv,
      ramp: widget.hasRamp && _rampCtrl.text.isNotEmpty
          ? int.tryParse(_rampCtrl.text)
          : null,
      value: widget.hasValue && _valueCtrl.text.isNotEmpty
          ? int.tryParse(_valueCtrl.text)
          : null,
    );
    widget.onAdd(item);
    _colorCtrl.clear();
    _rampCtrl.clear();
    _valueCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add new schedule',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 64,
                  child: TextField(
                    key: const Key('scheduler_hour_field'),
                    controller: _hourCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hour',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: TextField(
                    key: const Key('scheduler_minute_field'),
                    controller: _minuteCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minute',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                DropdownButton<String>(
                  key: const Key('scheduler_action_dropdown'),
                  value: _action,
                  items: [
                    const DropdownMenuItem(value: 'on', child: Text('on')),
                    const DropdownMenuItem(value: 'off', child: Text('off')),
                    const DropdownMenuItem(
                      value: 'toggle',
                      child: Text('toggle'),
                    ),
                    if (widget.hasColor)
                      const DropdownMenuItem(
                        value: 'set',
                        child: Text('set (color only)'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _action = v ?? 'on'),
                ),
                if (widget.hasColor)
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _colorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Color (HSV)',
                        hintText: '360;100;100',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                if (widget.hasRamp)
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _rampCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ramp (ms)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                if (widget.hasValue)
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _valueCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Value %',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _DaysPicker(
              selected: _days,
              onChanged: (s) => setState(() => _days = s),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('scheduler_add_button'),
              onPressed: _submit,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toggle chips for the seven weekdays.
class _DaysPicker extends StatelessWidget {
  const _DaysPicker({required this.selected, required this.onChanged});

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        for (var i = 0; i < 7; i++)
          FilterChip(
            label: Text(_SchedulerPageState._dayLabels[i]),
            selected: selected.contains(SchedulerTimeConverter.dayNames[i]),
            onSelected: (v) {
              final next = Set<String>.from(selected);
              if (v) {
                next.add(SchedulerTimeConverter.dayNames[i]);
              } else {
                next.remove(SchedulerTimeConverter.dayNames[i]);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

/// A single existing schedule entry card.
class _SchedulerCard extends StatefulWidget {
  const _SchedulerCard({
    super.key,
    required this.index,
    required this.item,
    required this.hasColor,
    required this.hasRamp,
    required this.hasValue,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final SchedulerItem item;
  final bool hasColor;
  final bool hasRamp;
  final bool hasValue;
  final ValueChanged<SchedulerItem> onChanged;
  final VoidCallback onDelete;

  @override
  State<_SchedulerCard> createState() => _SchedulerCardState();
}

class _SchedulerCardState extends State<_SchedulerCard> {
  late final TextEditingController _hourCtrl;
  late final TextEditingController _minuteCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _rampCtrl;
  late final TextEditingController _valueCtrl;
  late String _action;
  late Set<String> _days;

  @override
  void initState() {
    super.initState();
    _hourCtrl = TextEditingController(text: widget.item.hour.toString());
    _minuteCtrl = TextEditingController(text: widget.item.minute.toString());
    // Reconstruct HSV string from the color map for the text field.
    _colorCtrl = TextEditingController(
      text: widget.item.hsv != null
          ? '${widget.item.hsv!['hue'] ?? 0};'
                '${widget.item.hsv!['saturation'] ?? 100};'
                '${widget.item.hsv!['value'] ?? 100}'
          : '',
    );
    _rampCtrl = TextEditingController(text: widget.item.ramp?.toString() ?? '');
    _valueCtrl = TextEditingController(
      text: widget.item.value?.toString() ?? '',
    );
    _action = widget.item.action;
    _days = widget.item.days.toSet();
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _colorCtrl.dispose();
    _rampCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    // Parse HSV string into a map for the new scheduler API.
    String? mode;
    Map<String, dynamic>? hsv;
    if (widget.hasColor && _colorCtrl.text.isNotEmpty) {
      final parts = _colorCtrl.text.split(';');
      if (parts.length == 3) {
        mode = 'hsv';
        hsv = {
          'hue': int.tryParse(parts[0]) ?? 0,
          'saturation': int.tryParse(parts[1]) ?? 100,
          'value': int.tryParse(parts[2]) ?? 100,
        };
      }
    }
    widget.onChanged(
      widget.item.copyWith(
        hour: (int.tryParse(_hourCtrl.text) ?? 0).clamp(0, 23),
        minute: (int.tryParse(_minuteCtrl.text) ?? 0).clamp(0, 59),
        action: _action,
        days: SchedulerTimeConverter.dayNames.where(_days.contains).toList(),
        mode: mode,
        hsv: hsv,
        ramp: widget.hasRamp && _rampCtrl.text.isNotEmpty
            ? int.tryParse(_rampCtrl.text)
            : null,
        value: widget.hasValue && _valueCtrl.text.isNotEmpty
            ? int.tryParse(_valueCtrl.text)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Switch(
                  value: widget.item.enable,
                  onChanged: (v) =>
                      widget.onChanged(widget.item.copyWith(enable: v)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enable',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: _hourCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hour',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: _minuteCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minute',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                DropdownButton<String>(
                  value: _action,
                  items: [
                    const DropdownMenuItem(value: 'on', child: Text('on')),
                    const DropdownMenuItem(value: 'off', child: Text('off')),
                    const DropdownMenuItem(
                      value: 'toggle',
                      child: Text('toggle'),
                    ),
                    if (widget.hasColor)
                      const DropdownMenuItem(
                        value: 'set',
                        child: Text('set (color only)'),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _action = v);
                    _emit();
                  },
                ),
                if (widget.hasColor)
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _colorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Color (HSV)',
                        hintText: '360;100;100',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _emit(),
                    ),
                  ),
                if (widget.hasRamp)
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _rampCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ramp (ms)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _emit(),
                    ),
                  ),
                if (widget.hasValue)
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _valueCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Value %',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _emit(),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _DaysPicker(
              selected: _days,
              onChanged: (s) {
                setState(() => _days = s);
                _emit();
              },
            ),
          ],
        ),
      ),
    );
  }
}
