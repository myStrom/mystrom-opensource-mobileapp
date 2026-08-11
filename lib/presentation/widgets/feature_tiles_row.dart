import 'package:flutter/material.dart';

import '../../domain/entities/device_entity.dart';

/// A row of large, round feature tiles shown on device detail pages.
///
/// Renders a **Timer** tile (always, when the device supports timers) and a
/// **Scheduler** tile (when the device supports the scheduler). Both are
/// big colored circles with an icon + label, mirroring the pre-redesign
/// look. Settings stays in the AppBar as a small icon.
class FeatureTilesRow extends StatelessWidget {
  const FeatureTilesRow({
    super.key,
    required this.device,
    required this.onTimer,
    this.onScheduler,
  });

  final DeviceEntity device;
  final VoidCallback onTimer;
  final VoidCallback? onScheduler;

  @override
  Widget build(BuildContext context) {
    final tiles = <_FeatureTileData>[
      if (device.type.hasTimer)
        _FeatureTileData(
          key: const Key('detail_timer_tile'),
          icon: Icons.timer,
          label: 'Timer',
          color: Colors.orange,
          onTap: onTimer,
        ),
      if (device.type.hasScheduler && onScheduler != null)
        _FeatureTileData(
          key: const Key('detail_scheduler_tile'),
          icon: Icons.schedule,
          label: 'Scheduler',
          color: Colors.purple,
          onTap: onScheduler!,
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: _FeatureTile(key: tiles[i].key, data: tiles[i]),
          ),
        ],
      ],
    );
  }
}

class _FeatureTileData {
  const _FeatureTileData({
    required this.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final Key key;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({super.key, required this.data});

  final _FeatureTileData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: data.color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: data.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                data.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
