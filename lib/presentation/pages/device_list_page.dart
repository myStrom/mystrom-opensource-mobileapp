import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/device_http_client.dart';
import '../../core/utils/device_type.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/scene.dart';
import '../../domain/entities/device_entity.dart';
import '../providers/device_provider.dart';
import '../providers/scene_provider.dart';
import '../widgets/add_device_dialog.dart';
import '../widgets/device_status_card.dart';
import '../widgets/discovered_device_card.dart';
import 'add_device_page.dart';
import 'bulb_detail_page.dart';
import 'button_detail_page.dart';
import 'button_sensor_page.dart';
import 'dimmer_detail_page.dart';
import 'pir_detail_page.dart';
import 'scene_editor_page.dart';
import 'strip_detail_page.dart';
import 'switch_detail_page.dart';

/// Main dashboard: shows known + newly discovered devices.
///
/// Features a category bar (All / Favorite / rooms) for filtering the
/// device list and two quick-action scene buttons at the top.
class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  /// Currently selected category. 'All' shows everything, 'Favorite'
  /// shows only favorites, any other string is a room name.
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('myStrom Local'),
        actions: [
          Consumer<DeviceProvider>(
            builder: (context, provider, _) {
              final active = provider.discoveryActive;
              final count = provider.discoveredCount;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? Icons.wifi : Icons.wifi_off,
                        size: 16,
                        color: active ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        active ? '$count found' : 'listening...',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('appbar_notifications'),
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            key: const Key('appbar_add_device'),
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddDevicePage()),
            ),
          ),
        ],
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, provider, _) {
          final known = provider.devices;
          final fresh = provider.newDevices;

          if (known.isEmpty && fresh.isEmpty) {
            return _EmptyState(
              key: const Key('empty_state'),
              provider: provider,
            );
          }

          // Available rooms (non-empty, deduped, sorted).
          final rooms =
              known
                  .map((d) => d.room)
                  .whereType<String>()
                  .where((r) => r.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

          final categories = ['All', 'Favorite', ...rooms];

          // Filter known devices by selected category.
          final filtered = known.where((d) {
            switch (_category) {
              case 'All':
                return true;
              case 'Favorite':
                // Strict filter: only already-favorited devices.
                return d.favorite;
              default:
                return d.room == _category;
            }
          }).toList();

          return CustomScrollView(
            slivers: [
              // Scenes section
              const SliverToBoxAdapter(child: _SectionHeader('Scenes')),
              SliverToBoxAdapter(
                child: _ScenesRow(
                  onAddScene: () => _addScene(context),
                  onRunScene: (s) => _runScene(context, s),
                  onEditScene: (s) => _editScene(context, s),
                ),
              ),
              // Category bar
              SliverToBoxAdapter(
                child: _CategoryBar(
                  categories: categories,
                  selected: _category,
                  onSelect: (c) => setState(() => _category = c),
                  onRoomLongPress: (room) => _roomActionSheet(context, room),
                ),
              ),
              // Total power for the current category
              if (filtered.isNotEmpty)
                SliverToBoxAdapter(
                  child: _PowerSummaryCard(
                    key: ValueKey('power_summary_$_category'),
                    devices: filtered,
                  ),
                ),
              // Known devices section
              if (filtered.isNotEmpty) ...[
                const SliverToBoxAdapter(child: _SectionHeader('My devices')),
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.45,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => DeviceStatusCard(
                      key: ValueKey('device_card_${filtered[i].mac}'),
                      device: filtered[i],
                      onTap: () => _openDetail(context, filtered[i]),
                      showFavoriteToggle: true,
                      onFavoriteChanged: (v) => context
                          .read<DeviceProvider>()
                          .setFavorite(filtered[i].mac, v),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ],
              // Newly discovered section — only under "All" so it does
              // not leak into Favorite / room filters.
              if (fresh.isNotEmpty && _category == 'All') ...[
                const SliverToBoxAdapter(
                  child: _SectionHeader('Newly discovered'),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => DiscoveredDeviceCard(
                      device: fresh[i],
                      onAdd: () => _addDevice(context, fresh[i]),
                      onTap: () => _addDevice(context, fresh[i]),
                    ),
                    childCount: fresh.length,
                  ),
                ),
              ],
              if (filtered.isEmpty && fresh.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No devices in this category')),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _addDevice(BuildContext context, DeviceEntity d) async {
    final result = await showDialog<AddDeviceResult>(
      context: context,
      builder: (_) => AddDeviceDialog(device: d),
    );
    if (result != null && context.mounted) {
      context.read<DeviceProvider>().addDevice(
        d,
        customName: result.customName,
        colorValue: result.colorValue,
      );
    }
  }

  void _addScene(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SceneEditorPage()),
    );
  }

  void _editScene(BuildContext context, Scene scene) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SceneEditorPage(scene: scene)),
    );
  }

  /// Long-press on a room chip: turn all toggleable, non-locked devices in
  /// the room on or off. Locked devices are skipped.
  Future<void> _roomActionSheet(BuildContext context, String room) async {
    final provider = context.read<DeviceProvider>();
    final devices = provider.devices
        .where((d) => d.room == room)
        .where(
          (d) =>
              d.type.isSwitch ||
              d.type.isStrip ||
              d.type.isDimmer ||
              d.type.isBulb,
        )
        .where((d) => !d.lockable)
        .toList();
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No toggleable devices in "$room"')),
      );
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.power_settings_new),
              title: Text('Turn all in "$room" on'),
              onTap: () => Navigator.pop(context, 'on'),
            ),
            ListTile(
              leading: const Icon(Icons.power_off),
              title: Text('Turn all in "$room" off'),
              onTap: () => Navigator.pop(context, 'off'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    await _bulkToggle(devices, action);
  }

  Future<void> _bulkToggle(List<DeviceEntity> devices, String action) async {
    final remote = DeviceRemoteDataSource(DeviceHttpClient());
    final messenger = ScaffoldMessenger.of(context);
    var ok = 0;
    await Future.wait(
      devices.map((d) async {
        final ip = d.bestIp;
        if (ip == null) return;
        try {
          if (d.type.isSwitch) {
            await remote.setRelay(ip, on: action == 'on');
          } else if (d.type.isStrip) {
            await remote.setStripState(ip, action: action);
          } else if (d.type.isDimmer) {
            await remote.setDimmerState(ip, action: action);
          } else if (d.type.isBulb) {
            await remote.setBulbState(ip, action: action);
          }
          ok++;
        } catch (_) {}
      }),
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('$ok/${devices.length} devices $action')),
    );
  }

  Future<void> _runScene(BuildContext context, Scene scene) async {
    final provider = context.read<SceneProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final failed = await provider.runScene(scene);
    if (!context.mounted) return;
    if (failed.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text('Scene "${scene.name}" executed')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed: ${failed.join(", ")}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _openDetail(BuildContext context, DeviceEntity d) {
    final page = _detailPageFor(d);
    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }

  Widget? _detailPageFor(DeviceEntity d) {
    if (d.type.isSwitch) return SwitchDetailPage(device: d);
    if (d.type.isStrip) return StripDetailPage(device: d);
    if (d.type.isDimmer) return DimmerDetailPage(device: d);
    if (d.type.isBulb) return BulbDetailPage(device: d);
    if (d.type.isPir) return PirDetailPage(device: d);
    if (d.type.isButton) {
      if (d.type == DeviceType.bp2 ||
          d.type == DeviceType.bp1 ||
          d.type == DeviceType.bm1) {
        return ButtonSensorPage(device: d);
      }
      return ButtonDetailPage(device: d);
    }
    return null;
  }
}

/// Scenes row: user-defined quick actions above the device grid.
/// Reads scenes from [SceneProvider]. Each scene is a rounded button with
/// icon + name; tap runs the scene, long-press opens a menu (Run / Edit).
/// A trailing "+" button adds a new scene.
class _ScenesRow extends StatelessWidget {
  const _ScenesRow({
    required this.onAddScene,
    required this.onRunScene,
    required this.onEditScene,
  });

  final VoidCallback onAddScene;
  final ValueChanged<Scene> onRunScene;
  final ValueChanged<Scene> onEditScene;

  @override
  Widget build(BuildContext context) {
    final scenes = context.watch<SceneProvider>().scenes;
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: scenes.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == scenes.length) {
            return _AddSceneButton(
              key: const Key('scene_add_button'),
              onTap: onAddScene,
            );
          }
          final s = scenes[i];
          return _SceneChip(
            key: ValueKey('scene_chip_${s.id}'),
            scene: s,
            onTap: () => onRunScene(s),
            onLongPress: () => onEditScene(s),
          );
        },
      ),
    );
  }
}

class _SceneChip extends StatelessWidget {
  const _SceneChip({
    super.key,
    required this.scene,
    required this.onTap,
    required this.onLongPress,
  });

  final Scene scene;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = Color(scene.colorValue);
    // ignore: non_const_argument_for_const_parameter
    final icon = IconData(scene.iconCode, fontFamily: 'MaterialIcons');
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(minWidth: 110),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scene.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              // Discoverable edit affordance (top-right).
              Positioned(
                top: -2,
                right: -2,
                child: GestureDetector(
                  key: const Key('scene_edit_button'),
                  onTap: onLongPress,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.edit_outlined, size: 14, color: color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSceneButton extends StatelessWidget {
  const _AddSceneButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(minWidth: 70),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 18),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrollable category selector.
class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelect,
    this.onRoomLongPress,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  /// Called when the user long-presses a room chip (not All/Favorite).
  /// Used to offer a "turn all in this room on/off" action.
  final ValueChanged<String>? onRoomLongPress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = categories[i];
          final isSel = c == selected;
          final theme = Theme.of(context);
          final isRoom = c != 'All' && c != 'Favorite';
          final chip = ChoiceChip(
            label: isRoom
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home_outlined, size: 14),
                      const SizedBox(width: 4),
                      Text(c),
                    ],
                  )
                : Text(c),
            selected: isSel,
            onSelected: (_) => onSelect(c),
            labelStyle: TextStyle(
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              color: isSel ? theme.colorScheme.onPrimary : theme.hintColor,
            ),
          );
          if (!isRoom || onRoomLongPress == null) return chip;
          return Tooltip(
            message: 'Long-press to turn all in "$c" on/off',
            child: GestureDetector(
              onLongPress: () => onRoomLongPress!(c),
              child: chip,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key, required this.provider});
  final DeviceProvider provider;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            provider.discoveryActive ? Icons.wifi_find : Icons.wifi_off,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            provider.discoveryActive
                ? 'Listening for devices...\n'
                      'No devices found yet.\n'
                      'Make sure myStrom devices are on the same WiFi.'
                : 'Starting UDP discovery...\n'
                      'If Windows asked for network access,\n'
                      'make sure you allowed it.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add device manually'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddDevicePage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Shows the total current power draw (W) for a set of devices.
///
/// Polls each device's `/report` (or equivalent) once on build and
/// aggregates the `power` field. Devices that don't report power or are
/// unreachable are skipped. Resilient to missing fields / exceptions.
class _PowerSummaryCard extends StatefulWidget {
  const _PowerSummaryCard({super.key, required this.devices});

  final List<DeviceEntity> devices;

  @override
  State<_PowerSummaryCard> createState() => _PowerSummaryCardState();
}

class _PowerSummaryCardState extends State<_PowerSummaryCard> {
  double? _total;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _aggregate();
  }

  @override
  void didUpdateWidget(_PowerSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-aggregate when the device list identity changes.
    if (!_listEqual(oldWidget.devices, widget.devices)) {
      _aggregate();
    }
  }

  bool _listEqual(List<DeviceEntity> a, List<DeviceEntity> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].mac != b[i].mac) return false;
    }
    return true;
  }

  Future<void> _aggregate() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _total = null;
    });
    final remote = DeviceRemoteDataSource(DeviceHttpClient());
    var sum = 0.0;
    await Future.wait(
      widget.devices.map((d) async {
        final ip = d.bestIp;
        if (ip == null) return;
        final p = await remote.getPower(ip, d.type);
        if (p != null) sum += p;
      }),
    );
    if (!mounted) return;
    setState(() {
      _total = sum;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String label;
    if (_loading) {
      label = '...';
    } else if (_total == null) {
      label = '--';
    } else {
      label = '${_total!.toStringAsFixed(1)} W';
    }
    // Total energy from the persisted accumulator (no HTTP needed).
    final totalEnergyWs = widget.devices.fold<double>(
      0,
      (sum, d) => sum + d.totalEnergyWs + d.bootEnergyWs,
    );
    final energyLabel = totalEnergyWs > 0
        ? '${(totalEnergyWs / 3600000).toStringAsFixed(3)} kWh'
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Card(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Total power',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (energyLabel != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart,
                      color: theme.colorScheme.tertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total energy',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      energyLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
