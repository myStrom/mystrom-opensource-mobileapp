import 'package:flutter/material.dart';

import '../../domain/entities/device_entity.dart';

/// Dialog shown when adding a device. Lets the user override the default
/// name and pick a custom color for the device card.
class AddDeviceDialog extends StatefulWidget {
  const AddDeviceDialog({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  late final TextEditingController _nameController;
  int? _selectedColor;

  static const List<Color> _palette = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.displayName);
    _selectedColor = widget.device.colorValue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add device'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Living room lamp',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('Color', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = c.toARGB32()),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == c.toARGB32()
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: _selectedColor == c.toARGB32()
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            Navigator.pop(
              context,
              AddDeviceResult(
                customName: name.isEmpty ? null : name,
                colorValue: _selectedColor,
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Result returned by [AddDeviceDialog].
class AddDeviceResult {
  final String? customName;
  final int? colorValue;

  const AddDeviceResult({this.customName, this.colorValue});
}
