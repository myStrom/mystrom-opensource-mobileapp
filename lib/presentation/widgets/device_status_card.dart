import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/device_http_client.dart';
import '../../core/utils/device_type.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../domain/entities/device_entity.dart';
import '../providers/device_provider.dart';

/// Compact device card showing name, icon, online status, and live state.
///
/// Fetches the device state asynchronously and highlights the card when
/// the device is active (relay on, motion detected, etc.).
///
/// Exposes a [GlobalKey] so parent widgets can call [updateActiveState]
/// to immediately reflect a toggle action without waiting for the next poll.
class DeviceStatusCard extends StatefulWidget {
  const DeviceStatusCard({
    super.key,
    required this.device,
    required this.onTap,
    this.trailing,
    this.showState = true,
    this.showFavoriteToggle = false,
    this.onFavoriteChanged,
  });

  final DeviceEntity device;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Whether to fetch and display live device state.
  /// Set to false for discovered (not yet added) devices.
  final bool showState;

  /// Whether to show a star toggle in the top-right corner (used in the
  /// "Favorite" category so the user can mark/unmark favorites directly).
  final bool showFavoriteToggle;

  /// Called when the user toggles the favorite star. Ignored when
  /// [showFavoriteToggle] is false.
  final ValueChanged<bool>? onFavoriteChanged;

  @override
  State<DeviceStatusCard> createState() => _DeviceStatusCardState();
}

class _DeviceStatusCardState extends State<DeviceStatusCard> {
  late final DeviceRemoteDataSource _remote;
  bool _active = false;
  String? _statusText;
  String? _sensorText;
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _remote = DeviceRemoteDataSource(
      DeviceHttpClient(token: widget.device.token),
    );
    if (widget.showState) {
      _fetchState();
      // Poll every 10 seconds for live state.
      _pollTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _fetchState(),
      );
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Immediately update the active state and status text after a
  /// successful API action (e.g. toggle relay).  Also triggers a
  /// full state refresh shortly after to sync sensor data.
  void updateActiveState({required bool active, String? statusText}) {
    if (!mounted) return;
    setState(() {
      _active = active;
      if (statusText != null) _statusText = statusText;
    });
    // Refresh full state after a short delay to sync sensors.
    Timer(const Duration(seconds: 2), _fetchState);
  }

  /// Toggle the device on/off directly from the card.
  Future<void> _toggle() async {
    final ip = widget.device.bestIp;
    if (ip == null) {
      _snack('No IP address for this device.');
      return;
    }
    final d = widget.device;
    if (d.lockable) {
      _snack('This device is locked — on/off toggle is disabled.');
      return;
    }
    if (d.isOffline) {
      _snack('Device is offline. Make sure it is powered on and connected.');
      return;
    }
    try {
      if (d.type.isSwitch) {
        final s = await _remote.toggleRelay(ip);
        updateActiveState(active: s.relay, statusText: s.relay ? 'On' : 'Off');
      } else if (d.type.isStrip) {
        final s = await _remote.getStripState(ip);
        if (s.on) {
          await _remote.setStripState(ip, action: 'off');
          updateActiveState(active: false, statusText: 'Off');
        } else {
          await _remote.setStripState(ip, action: 'on');
          updateActiveState(active: true, statusText: 'On');
        }
      } else if (d.type.isDimmer) {
        final s = await _remote.getDimmerState(ip);
        if (s.on) {
          await _remote.setDimmerState(ip, action: 'off');
          updateActiveState(active: false, statusText: 'Off');
        } else {
          await _remote.setDimmerState(ip, action: 'on');
          updateActiveState(active: true, statusText: 'On');
        }
      } else if (d.type.isBulb) {
        final s = await _remote.getBulbState(ip);
        if (s.on) {
          await _remote.setBulbState(ip, action: 'off');
          updateActiveState(active: false, statusText: 'Off');
        } else {
          await _remote.setBulbState(ip, action: 'on');
          updateActiveState(active: true, statusText: 'On');
        }
      }
    } catch (e) {
      // Show the user why nothing happened; next poll corrects the state.
      _snack('Could not reach device: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Whether this device type supports on/off toggle from the card.
  bool get _canToggle =>
      widget.device.type.isSwitch ||
      widget.device.type.isStrip ||
      widget.device.type.isDimmer ||
      widget.device.type.isBulb;

  /// Whether the on/off toggle is allowed (not locked).
  bool get _toggleAllowed => !widget.device.lockable;

  Future<void> _fetchState() async {
    final ip = widget.device.bestIp;
    if (ip == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final d = widget.device;
      if (d.type.isSwitch) {
        final s = await _remote.getReport(ip);
        if (!mounted) return;
        setState(() {
          _active = s.relay;
          _statusText = s.relay ? 'On' : 'Off';
          // Show temperature whenever available (also when relay is off),
          // and power only when the device actually draws current.
          final parts = <String>[
            if (s.temperature != null)
              '${(s.temperature! + d.temperatureOffset).toStringAsFixed(1)}°C',
            if (s.power != null && s.power! > 0)
              '${s.power!.toStringAsFixed(1)} W',
          ];
          _sensorText = parts.isEmpty ? null : parts.join(' • ');
          _loading = false;
        });
        // Fold the fresh report's energy into the persistent accumulator.
        context.read<DeviceProvider>().accumulateEnergy(d.mac, s);
      } else if (d.type.isStrip) {
        final s = await _remote.getStripState(ip);
        if (!mounted) return;
        setState(() {
          _active = s.on;
          _statusText = s.on ? 'On' : 'Off';
          _loading = false;
        });
      } else if (d.type.isDimmer) {
        final s = await _remote.getDimmerState(ip);
        if (!mounted) return;
        setState(() {
          _active = s.on;
          _statusText = s.on ? 'On ${s.value}%' : 'Off';
          _loading = false;
        });
      } else if (d.type.isBulb) {
        final s = await _remote.getBulbState(ip);
        if (!mounted) return;
        setState(() {
          _active = s.on;
          _statusText = s.on ? 'On' : 'Off';
          _loading = false;
        });
      } else if (d.type.isPir) {
        final s = await _remote.getPirSensors(ip);
        if (!mounted) return;
        setState(() {
          _active = s.motion;
          _statusText = s.motion ? 'Motion' : 'Idle';
          _sensorText = [
            if (s.temperature != null)
              '${(s.temperature! + d.temperatureOffset).toStringAsFixed(1)}°C',
            if (s.lightLux != null) '${s.lightLux!.toStringAsFixed(0)} lx',
          ].join(' • ');
          _loading = false;
        });
      } else if (d.type.isButton) {
        if (d.type == DeviceType.bp2 ||
            d.type == DeviceType.bp1 ||
            d.type == DeviceType.bm1) {
          final s = await _remote.getButtonSeSensors(ip);
          if (!mounted) return;
          setState(() {
            _statusText = '${s.battery?.percent ?? '?'}%';
            _sensorText = [
              if (s.temperature != null)
                '${(s.temperature! + d.temperatureOffset).toStringAsFixed(1)}°C',
              if (s.humidity != null) '${s.humidity!.toStringAsFixed(0)}%',
            ].join(' • ');
            _loading = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            _statusText = 'Button';
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final offline = d.isOffline;
    final theme = Theme.of(context);

    // Card color: white/light when off, strong green when on, muted when offline,
    // yellow when on/off is locked (e.g. a fridge that must not be turned off).
    // The user-selected color only affects the icon circle, not the card.
    Color? cardColor;
    if (d.lockable) {
      cardColor = Colors.amber.withValues(alpha: 0.30);
    } else if (offline) {
      cardColor = theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.3,
      );
    } else if (_active) {
      cardColor = Colors.green.withValues(alpha: 0.35);
    } else {
      cardColor = null; // white / surface
    }

    // Icon circle color: user color when set, otherwise light surface.
    final circleColor = d.colorValue != null
        ? Color(d.colorValue!)
        : theme.colorScheme.surfaceContainerHighest;
    // Icon color: white on user-colored circle, otherwise green when
    // active and grey when off — matching the original pre-color look.
    Color iconColor;
    if (offline) {
      iconColor = theme.disabledColor;
    } else if (d.colorValue != null) {
      iconColor = Colors.white;
    } else if (_active) {
      iconColor = Colors.green;
    } else {
      iconColor = theme.colorScheme.onSurfaceVariant;
    }

    // Subtitle line: location/room + sensor data (if any).
    String subtitle;
    if (offline) {
      subtitle = 'offline';
    } else if (!widget.showState) {
      subtitle = d.type.displayName;
    } else if (_loading) {
      subtitle = '...';
    } else {
      final parts = <String>[
        if (d.room?.isNotEmpty ?? false) d.room!,
        ?_statusText,
        ?_sensorText,
      ];
      subtitle = parts.isEmpty ? d.type.displayName : parts.join(' • ');
    }

    // Whether to show the power toggle button (top-right).
    final showPower =
        _canToggle && !offline && widget.showState && _toggleAllowed;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: icon (left) + power button (right)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_iconFor(d.type), color: iconColor, size: 22),
                  ),
                  const Spacer(),
                  if (showPower)
                    _PowerButton(
                      key: const Key('card_power_button'),
                      active: _active,
                      onPressed: _toggle,
                    )
                  else if (widget.showState && !offline)
                    // Online dot indicator for non-toggle devices (sensors)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Icon(
                        Icons.circle,
                        size: 10,
                        color: offline ? Colors.grey : Colors.green,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Device name + favorite star (if enabled)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      d.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.showFavoriteToggle)
                    GestureDetector(
                      key: const Key('card_favorite_star'),
                      onTap: () {
                        final next = !d.favorite;
                        setState(() {});
                        widget.onFavoriteChanged?.call(next);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          d.favorite ? Icons.star : Icons.star_border,
                          color: d.favorite ? Colors.amber : theme.hintColor,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              // Subtitle (room + state + sensor)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: _active ? Colors.green.shade800 : theme.hintColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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

/// Round power toggle button used in the top-right of the device card.
class _PowerButton extends StatelessWidget {
  const _PowerButton({
    super.key,
    required this.active,
    required this.onPressed,
  });

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? Colors.green
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            Icons.power_settings_new,
            size: 20,
            color: active ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
