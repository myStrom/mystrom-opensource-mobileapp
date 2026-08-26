import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/device_type.dart';
import '../../data/models/scene.dart';
import '../../domain/entities/device_entity.dart';
import '../../l10n/app_localizations.dart';
import '../providers/device_provider.dart';
import '../providers/scene_provider.dart';
import '../utils/action_l10n.dart';
import '../utils/scene_icons.dart';

/// Edit or create a scene: name, icon, color, and a list of device actions.
///
/// Pass an existing [Scene] to edit, or omit to create a new one.
class SceneEditorPage extends StatefulWidget {
  const SceneEditorPage({super.key, this.scene});

  /// If non-null, edit this scene. If null, create a new scene.
  final Scene? scene;

  @override
  State<SceneEditorPage> createState() => _SceneEditorPageState();
}

class _SceneEditorPageState extends State<SceneEditorPage> {
  late final TextEditingController _nameController;
  late int _iconCode;
  late int _colorValue;
  late List<SceneAction> _actions;
  bool _defaultNameApplied = false;

  static const List<SceneIcon> _icons = kSceneIcons;

  static const List<Color> _palette = [
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.deepPurple,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.teal,
    Colors.green,
    Colors.brown,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.scene;
    _nameController = TextEditingController(text: s?.name ?? '');
    _iconCode = s?.iconCode ?? Icons.home.codePoint;
    _colorValue = s?.colorValue ?? Colors.blue.toARGB32();
    _actions =
        s?.actions
            .map(
              (a) => SceneAction(
                deviceMac: a.deviceMac,
                deviceName: a.deviceName,
                deviceTypeCode: a.deviceTypeCode,
                action: a.action,
              ),
            )
            .toList() ??
        [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_defaultNameApplied && widget.scene == null) {
      _nameController.text = AppLocalizations.of(context).newScene;
      _defaultNameApplied = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isNew = widget.scene == null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_hasChanges()) {
          Navigator.pop(context);
          return;
        }
        final discard = await _confirmDiscard(context);
        if (discard && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isNew ? l10n.newScene : l10n.editScene),
          actions: [
            if (!isNew)
              IconButton(
                key: const Key('scene_delete_button'),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: l10n.delete,
                onPressed: _delete,
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- Name ----
            TextField(
              key: const Key('scene_name_field'),
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.sceneName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // ---- Icon ----
            Text(l10n.icon, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _icons.map((ic) {
                final sel = ic.icon.codePoint == _iconCode;
                return GestureDetector(
                  onTap: () => setState(() => _iconCode = ic.icon.codePoint),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: sel ? Color(_colorValue) : null,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? Color(_colorValue) : Colors.grey.shade400,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      ic.icon,
                      color: sel ? Colors.white : null,
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ---- Color ----
            Text(l10n.color, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _palette.map((c) {
                final sel = c.toARGB32() == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = c.toARGB32()),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: sel
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(),

            // ---- Actions ----
            Row(
              children: [
                Text(
                  l10n.actions,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_actions.length}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_actions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    l10n.noActionsYet,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            for (var i = 0; i < _actions.length; i++)
              _ActionTile(
                action: _actions[i],
                onActionChanged: (v) => setState(() => _actions[i] = v),
                onRemove: () => setState(() => _actions.removeAt(i)),
              ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _addAction,
              icon: const Icon(Icons.add),
              label: Text(l10n.addDeviceAction),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: const Key('scene_add_timer_action'),
              onPressed: _addTimerAction,
              icon: const Icon(Icons.timer),
              label: Text(l10n.addTimerAction),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('scene_save_fab'),
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: Text(l10n.save),
        ),
      ),
    );
  }

  bool _hasChanges() {
    final l10n = AppLocalizations.of(context);
    final s = widget.scene;
    if (s == null) {
      // New scene: any non-default state counts as a change.
      return _nameController.text.trim() != l10n.newScene ||
          _iconCode != Icons.home.codePoint ||
          _colorValue != Colors.blue.toARGB32() ||
          _actions.isNotEmpty;
    }
    return _nameController.text.trim() != s.name ||
        _iconCode != s.iconCode ||
        _colorValue != s.colorValue ||
        !_actionsEqual(_actions, s.actions);
  }

  bool _actionsEqual(List<SceneAction> a, List<SceneAction> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].deviceMac != b[i].deviceMac || a[i].action != b[i].action) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.discardChangesTitle),
            content: Text(l10n.discardChangesMessage),
            actions: [
              TextButton(
                key: const Key('scene_discard_cancel'),
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                key: const Key('scene_discard_confirm'),
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text(l10n.quitWithoutSaving),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Opens a dialog to pick a known device + action type.
  Future<void> _addAction() async {
    final l10n = AppLocalizations.of(context);
    final devices = context.read<DeviceProvider>().devices;
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noDevicesAddedYet)),
      );
      return;
    }
    final result = await showDialog<SceneAction>(
      context: context,
      builder: (_) => _AddActionDialog(devices: devices),
    );
    if (result != null) {
      setState(() => _actions.add(result));
    }
  }

  /// Opens a dialog to pick a device + timer mode + duration.
  Future<void> _addTimerAction() async {
    final l10n = AppLocalizations.of(context);
    final devices = context.read<DeviceProvider>().devices;
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noDevicesAddedYet)),
      );
      return;
    }
    final result = await showDialog<SceneAction>(
      context: context,
      builder: (_) => _AddTimerActionDialog(devices: devices),
    );
    if (result != null) {
      setState(() => _actions.add(result));
    }
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final provider = context.read<SceneProvider>();
    final name = _nameController.text.trim();
    // For a brand-new scene, generate a unique UUID id so each scene
    // gets its own Hive key (an empty id would overwrite the previous one).
    final scene =
        widget.scene ??
        Scene(
          id: const Uuid().v4(),
          name: name.isEmpty ? l10n.sceneDefaultName : name,
          iconCode: _iconCode,
          colorValue: _colorValue,
        );
    scene.name = name.isEmpty ? scene.name : name;
    scene.iconCode = _iconCode;
    scene.colorValue = _colorValue;
    scene.actions = _actions;
    provider.saveScene(scene);
    Navigator.pop(context);
  }

  void _delete() {
    final s = widget.scene;
    if (s == null) return;
    context.read<SceneProvider>().deleteScene(s.id);
    Navigator.pop(context);
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    required this.onActionChanged,
    required this.onRemove,
  });

  final SceneAction action;
  final ValueChanged<SceneAction> onActionChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = DeviceType.fromCode(action.deviceTypeCode);
    final canToggle =
        type.isSwitch || type.isStrip || type.isDimmer || type.isBulb;
    final isTimer = action.action == 'timer';
    return ListTile(
      leading: Icon(isTimer ? Icons.timer : _iconFor(type)),
      title: Text(action.deviceName),
      subtitle: canToggle
          ? Wrap(
              spacing: 6,
              children: ['on', 'off', 'toggle', 'timer'].map((a) {
                final sel = action.action == a;
                return ChoiceChip(
                  key: Key('scene_action_chip_$a'),
                  label: Text(localizedActionLabel(l10n, a)),
                  selected: sel,
                  onSelected: (_) => onActionChanged(
                    SceneAction(
                      deviceMac: action.deviceMac,
                      deviceName: action.deviceName,
                      deviceTypeCode: action.deviceTypeCode,
                      action: a,
                      timerMode: a == 'timer'
                          ? (action.timerMode ?? 'toggle')
                          : null,
                      timerSeconds: a == 'timer' ? action.timerSeconds : null,
                    ),
                  ),
                );
              }).toList(),
            )
          : Text(l10n.sensorNoAction),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: onRemove,
      ),
    );
  }

  IconData _iconFor(DeviceType type) {
    if (type.isSwitch) return Icons.power;
    if (type.isStrip) return Icons.lightbulb_outline;
    if (type.isDimmer) return Icons.tune;
    if (type.isBulb) return Icons.lightbulb;
    if (type.isPir) return Icons.sensors;
    if (type.isButton) return Icons.touch_app;
    return Icons.device_unknown;
  }
}

class _AddActionDialog extends StatefulWidget {
  const _AddActionDialog({required this.devices});
  final List<DeviceEntity> devices;

  @override
  State<_AddActionDialog> createState() => _AddActionDialogState();
}

class _AddActionDialogState extends State<_AddActionDialog> {
  String? _selectedMac;
  String _action = 'toggle';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addDeviceAction),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.device),
            const SizedBox(height: 8),
            DropdownButton<String>(
              key: const Key('scene_action_device_dropdown'),
              value: _selectedMac,
              hint: Text(l10n.selectDevice),
              isExpanded: true,
              items: widget.devices.map((d) {
                return DropdownMenuItem(
                  value: d.mac,
                  child: Text(d.displayName),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedMac = v),
            ),
            const SizedBox(height: 16),
            Text(l10n.action),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: ['on', 'off', 'toggle'].map((a) {
                return ChoiceChip(
                  key: Key('scene_action_chip_$a'),
                  label: Text(localizedActionLabel(l10n, a)),
                  selected: _action == a,
                  onSelected: (_) => setState(() => _action = a),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('scene_action_cancel'),
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('scene_action_add_button'),
          onPressed: () {
            if (_selectedMac == null) return;
            final d = widget.devices.firstWhere((e) => e.mac == _selectedMac);
            Navigator.pop(
              context,
              SceneAction(
                deviceMac: d.mac,
                deviceName: d.displayName,
                deviceTypeCode: d.type.code,
                action: _action,
              ),
            );
          },
          child: Text(l10n.add),
        ),
      ],
    );
  }
}

/// Dialog for adding a timer action: pick a device + timer mode + duration.
class _AddTimerActionDialog extends StatefulWidget {
  const _AddTimerActionDialog({required this.devices});
  final List<DeviceEntity> devices;

  @override
  State<_AddTimerActionDialog> createState() => _AddTimerActionDialogState();
}

class _AddTimerActionDialogState extends State<_AddTimerActionDialog> {
  String? _selectedMac;
  String _mode = 'toggle';
  int _hours = 0;
  int _minutes = 5;
  int _seconds = 0;

  int get _totalSeconds => _hours * 3600 + _minutes * 60 + _seconds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addTimerAction),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.device),
            const SizedBox(height: 8),
            DropdownButton<String>(
              key: const Key('scene_timer_device_dropdown'),
              value: _selectedMac,
              hint: Text(l10n.selectDevice),
              isExpanded: true,
              items: widget.devices.map((d) {
                return DropdownMenuItem(
                  value: d.mac,
                  child: Text(d.displayName),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedMac = v),
            ),
            const SizedBox(height: 16),
            Text(l10n.timerMode),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: ['on', 'off', 'toggle'].map((m) {
                return ChoiceChip(
                  key: Key('scene_timer_mode_chip_$m'),
                  label: Text(localizedActionLabel(l10n, m)),
                  selected: _mode == m,
                  onSelected: (_) => setState(() => _mode = m),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.durationHms(
                _hours.toString().padLeft(2, '0'),
                _minutes.toString().padLeft(2, '0'),
                _seconds.toString().padLeft(2, '0'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _timeField(
                    label: l10n.hourShort,
                    value: _hours,
                    max: 23,
                    onChanged: (v) => setState(() => _hours = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _timeField(
                    label: l10n.minuteShort,
                    value: _minutes,
                    max: 59,
                    onChanged: (v) => setState(() => _minutes = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _timeField(
                    label: l10n.secondShort,
                    value: _seconds,
                    max: 59,
                    onChanged: (v) => setState(() => _seconds = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('scene_timer_cancel'),
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('scene_timer_add_button'),
          onPressed: () {
            if (_selectedMac == null || _totalSeconds <= 0) return;
            final d = widget.devices.firstWhere((e) => e.mac == _selectedMac);
            Navigator.pop(
              context,
              SceneAction(
                deviceMac: d.mac,
                deviceName: d.displayName,
                deviceTypeCode: d.type.code,
                action: 'timer',
                timerMode: _mode,
                timerSeconds: _totalSeconds,
              ),
            );
          },
          child: Text(l10n.add),
        ),
      ],
    );
  }

  Widget _timeField({
    required String label,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        DropdownButton<int>(
          isExpanded: true,
          value: value,
          items: [
            for (var i = 0; i <= max; i++)
              DropdownMenuItem(
                value: i,
                child: Text(i.toString().padLeft(2, '0')),
              ),
          ],
          onChanged: (v) => onChanged(v ?? 0),
        ),
      ],
    );
  }
}
