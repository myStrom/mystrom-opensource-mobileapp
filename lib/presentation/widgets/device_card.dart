import 'package:flutter/material.dart';

import '../../core/utils/device_type.dart';
import '../../domain/entities/device_entity.dart';
import '../../l10n/app_localizations.dart';
import '../utils/device_type_l10n.dart';

/// Card showing a device summary. Tappable to open the detail page.
class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    this.trailing,
  });

  final DeviceEntity device;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final offline = device.isOffline;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          _iconFor(device.type),
          color: offline ? theme.disabledColor : theme.colorScheme.primary,
        ),
        title: Text(device.displayName),
        subtitle: Text(
          '${device.type.localizedName(l10n)} • ${device.mac}\n'
          '${device.bestIp ?? l10n.noIp} • ${offline ? l10n.offline : l10n.online}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing:
            trailing ??
            (offline
                ? const Icon(Icons.cloud_off, color: Colors.grey)
                : const Icon(Icons.circle, color: Colors.green, size: 12)),
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
