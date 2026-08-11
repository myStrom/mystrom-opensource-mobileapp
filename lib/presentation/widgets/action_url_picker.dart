import 'package:flutter/material.dart';

import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/configure_button_action.dart';

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
      title: const Text('Pick target action'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<DeviceEntity>(
              decoration: const InputDecoration(labelText: 'Target device'),
              initialValue: _target,
              items: controllable
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text('${d.displayName} (${d.type.model})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _target = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Action'),
              initialValue: _action,
              items: _actions
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _action = v ?? 'toggle'),
            ),
            if (_action == 'color') ...[
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Color (H;S;V)',
                  hintText: '120;100;100',
                ),
                onChanged: (v) => _color = v,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Ramp (ms)',
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
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _generate, child: const Text('Generate URL')),
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
    Navigator.pop(context);
  }
}
