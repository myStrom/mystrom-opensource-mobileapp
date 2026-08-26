import 'package:flutter/material.dart';

import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/configure_button_action.dart';
import '../../l10n/app_localizations.dart';
import '../utils/action_l10n.dart';

/// Dialog/widget that lets the user pick a target device and an action,
/// then generates the action URL automatically.
class ActionUrlPicker extends StatefulWidget {
  const ActionUrlPicker({
    super.key,
    required this.devices,
    required this.onUrlGenerated,
  });

  final List<DeviceEntity> devices;
  final ValueChanged<String> onUrlGenerated;

  @override
  State<ActionUrlPicker> createState() => _ActionUrlPickerState();
}

class _ActionUrlPickerState extends State<ActionUrlPicker> {
  DeviceEntity? _target;
  String _action = 'toggle';
  String _color = '120;100;100';
  int _ramp = 500;

  static const _actions = ['toggle', 'on', 'off', 'color'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controllable = widget.devices
        .where(
          (d) =>
              d.type.isSwitch ||
              d.type.isStrip ||
              d.type.isDimmer ||
              d.type.isBulb,
        )
        .toList();

    return AlertDialog(
      title: Text(l10n.assignAction),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<DeviceEntity>(
              decoration: InputDecoration(labelText: l10n.targetDevice),
              initialValue: _target,
              items: controllable
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(
                        l10n.deviceWithModel(d.displayName, d.type.model),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _target = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: l10n.action),
              initialValue: _action,
              items: _actions
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(localizedActionLabel(l10n, a)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _action = v ?? 'toggle'),
            ),
            if (_action == 'color') ...[
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.colorHsvShort,
                  hintText: '120;100;100',
                ),
                onChanged: (v) => _color = v,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.rampMs,
                  hintText: '500',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => _ramp = int.tryParse(v) ?? 500,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _generate, child: Text(l10n.assign)),
      ],
    );
  }

  void _generate() {
    if (_target == null || _target!.bestIp == null) return;
    final url = ConfigureButtonAction.buildUrl(
      targetIp: _target!.bestIp!,
      targetType: _target!.type,
      action: _action,
      color: _action == 'color' ? _color : null,
      ramp: _ramp,
    );
    widget.onUrlGenerated(url);
  }
}
