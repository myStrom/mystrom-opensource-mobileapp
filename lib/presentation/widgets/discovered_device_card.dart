import 'package:flutter/material.dart';

import '../../core/network/device_http_client.dart';
import '../../core/utils/device_type.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/identify_device.dart';

class DiscoveredDeviceCard extends StatelessWidget {
  const DiscoveredDeviceCard({
    super.key,
    required this.device,
    required this.onAdd,
    this.onTap,
  });

  final DeviceEntity device;
  final VoidCallback onAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = !device.httpReachable;
    final statusColor = locked ? Colors.orange : Colors.green;
    final subtitleLines = <String>[
      if (locked) 'Locked',
      'MAC: ${device.mac}',
      'IP: ${device.discoveryIp ?? "—"}',
    ];

    return Card(
      child: ListTile(
        onTap: onTap ?? onAdd,
        leading: Icon(_iconFor(device.type), color: statusColor),
        title: Text(
          device.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitleLines.join('\n'),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Identify button — only for unlocked devices that support it
            // and when identification is globally enabled.
            if (!locked && device.type.identifyAvailable)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  key: Key('identify_${device.mac}'),
                  tooltip: 'Identify',
                  icon: const Icon(Icons.bubble_chart),
                  onPressed: () => _identify(context),
                ),
              ),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _identify(BuildContext context) async {
    final ip = device.discoveryIp ?? device.lastKnownIp;
    if (ip == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final remote = DeviceRemoteDataSource(
      DeviceHttpClient(token: device.token),
    );
    final identify = IdentifyDevice(remote);
    await identify(ip, deviceType: device.type, mac: device.mac);
    if (!messenger.context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Identification signal sent — look for a blink.'),
        duration: Duration(seconds: 2),
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
