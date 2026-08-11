import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/device_http_client.dart';
import '../../core/utils/device_type.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/device_info.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/identify_device.dart';
import '../providers/device_provider.dart';
import '../widgets/action_url_picker.dart';
import 'strip_settings_page.dart';

/// Device settings: rename, assign room, view device info, remove.
///
/// Fetches live data from `GET /info` to show firmware version, WiFi SSID,
/// connection status, etc.
class DeviceSettingsPage extends StatefulWidget {
  const DeviceSettingsPage({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<DeviceSettingsPage> createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends State<DeviceSettingsPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _roomController;
  int? _selectedColor;
  bool _favorite = false;
  bool _lockable = false;
  double _tempOffset = 0;
  DeviceInfoModel? _info;
  bool _loadingInfo = true;
  String? _infoError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.device.customName ?? '',
    );
    _roomController = TextEditingController(text: widget.device.room ?? '');
    _selectedColor = widget.device.colorValue;
    _favorite = widget.device.favorite;
    _lockable = widget.device.lockable;
    _tempOffset = widget.device.temperatureOffset;
    _fetchInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _fetchInfo() async {
    final ip = widget.device.bestIp;
    if (ip == null) {
      setState(() {
        _loadingInfo = false;
        _infoError = 'No IP address';
      });
      return;
    }
    try {
      final remote = DeviceRemoteDataSource(
        DeviceHttpClient(token: widget.device.token),
      );
      final info = await remote.getInfo(ip);
      setState(() {
        _info = info;
        _loadingInfo = false;
      });
    } catch (e) {
      setState(() {
        _infoError = e.toString();
        _loadingInfo = false;
      });
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _identify(BuildContext context) async {
    final ip = widget.device.bestIp;
    if (ip == null) {
      _snack('No IP address');
      return;
    }
    final remote = DeviceRemoteDataSource(
      DeviceHttpClient(token: widget.device.token),
    );
    await IdentifyDevice(remote)(
      ip,
      deviceType: widget.device.type,
      mac: widget.device.mac,
    );
    _snack('Identification signal sent — look for a blink.');
  }

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
  Widget build(BuildContext context) {
    final d = widget.device;
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
          leading: IconButton(
            key: const Key('settings_back_button'),
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(d.displayName),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- Name & Room ----
            const Text(
              'Device name',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('settings_name_field'),
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Custom name',
                hintText: d.name,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('settings_room_field'),
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Room',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              key: const Key('settings_favorite_switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Favorite'),
              subtitle: const Text(
                'Show this device under the "Favorite" category on the dashboard.',
                style: TextStyle(fontSize: 12),
              ),
              value: _favorite,
              onChanged: (v) => setState(() => _favorite = v),
            ),
            SwitchListTile(
              key: const Key('settings_lockable_switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Lock on/off'),
              subtitle: const Text(
                'Disable the on/off toggle (e.g. for a fridge). '
                'Timers and scheduler are still allowed.',
                style: TextStyle(fontSize: 12),
              ),
              value: _lockable,
              onChanged: (v) => setState(() => _lockable = v),
            ),

            // ---- Temperature offset (devices with temperature sensor) ----
            if (d.type.hasTemperature) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Text('Temperature offset')),
                  Text(
                    '${_tempOffset >= 0 ? '+' : ''}'
                    '${_tempOffset.toStringAsFixed(1)} °C',
                  ),
                ],
              ),
              Slider(
                key: const Key('settings_temp_offset_slider'),
                min: -30,
                max: 30,
                divisions: 600,
                value: _tempOffset,
                label: '${_tempOffset.toStringAsFixed(1)} °C',
                onChanged: (v) =>
                    setState(() => _tempOffset = (v * 10).round() / 10),
              ),
            ],

            // ---- Tile color ----
            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'Tile color',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Helps tell this device apart from others on the dashboard.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              key: const Key('settings_color_palette'),
              spacing: 10,
              runSpacing: 10,
              children: [
                // "No color" option
                GestureDetector(
                  onTap: () => setState(() => _selectedColor = null),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                        width: _selectedColor == null ? 3 : 1,
                      ),
                    ),
                    child: _selectedColor == null
                        ? const Icon(Icons.check, size: 18)
                        : const Icon(Icons.block, size: 18, color: Colors.grey),
                  ),
                ),
                for (final c in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = c.toARGB32()),
                    child: Container(
                      width: 36,
                      height: 36,
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
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),

            // ---- Strip-specific settings ----
            if (d.type.isStrip) ...[
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                key: const Key('settings_strip_settings_tile'),
                leading: const Icon(Icons.tune),
                title: const Text('Strip channel mode'),
                subtitle: const Text('Configure colors / channels / cold_warm'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StripSettingsPage(device: d),
                  ),
                ),
              ),
            ],

            // ---- LCS button action URL (LCS only) ----
            if (d.type == DeviceType.lcs) ...[
              const SizedBox(height: 24),
              const Divider(),
              const Text(
                'Button action',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose which device/action the switch triggers when its '
                'physical button is pressed.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              _LcsButtonActionTile(device: d),
            ],

            // ---- Identify (WS2, WSE, WRS, WLL, WMS, Bulb) ----
            if (d.type.identifyAvailable) ...[
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                key: const Key('settings_identify_tile'),
                leading: const Icon(Icons.bubble_chart),
                title: const Text('Identify'),
                subtitle: const Text(
                  'Blink the device so you can tell which one it is.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _identify(context),
              ),
            ],

            // ---- Device info from /info ----
            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'Device info',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_loadingInfo)
              const Center(child: CircularProgressIndicator())
            else if (_infoError != null)
              Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_infoError!),
                ),
              )
            else if (_info != null)
              _buildInfoSection(d, _info!)
            else
              const Text('No info available'),

            // ---- Static info from local DB ----
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('MAC'),
              subtitle: Text(d.mac),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Type'),
              subtitle: Text('${d.type.model} — ${d.type.displayName}'),
            ),
            ListTile(
              leading: const Icon(Icons.router),
              title: const Text('IP'),
              subtitle: Text(d.bestIp ?? 'unknown'),
            ),

            // ---- Save (name + room + color + favorite) ----
            const SizedBox(height: 24),
            const Divider(),

            // ---- Remove ----
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              key: const Key('settings_remove_button'),
              onPressed: () {
                context.read<DeviceProvider>().removeDevice(d.mac);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Remove device',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('settings_save_fab'),
          onPressed: () {
            final provider = context.read<DeviceProvider>();
            final name = _nameController.text.trim();
            provider.renameDevice(d.mac, name.isEmpty ? d.name : name);
            provider.assignRoom(d.mac, _roomController.text.trim());
            provider.setDeviceColor(d.mac, _selectedColor);
            provider.setFavorite(d.mac, _favorite);
            provider.setLockable(d.mac, _lockable);
            provider.setTemperatureOffset(d.mac, _tempOffset);
            _snack('Saved');
          },
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ),
    );
  }

  bool _hasChanges() {
    final d = widget.device;
    final name = _nameController.text.trim();
    if (name != (d.customName ?? '')) return true;
    if (_roomController.text.trim() != (d.room ?? '')) return true;
    if (_selectedColor != d.colorValue) return true;
    if (_favorite != d.favorite) return true;
    if (_lockable != d.lockable) return true;
    if ((_tempOffset - d.temperatureOffset).abs() >= 0.05) return true;
    return false;
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Quit without saving'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildInfoSection(DeviceEntity d, DeviceInfoModel info) {
    final cs = info.connectionStatus;
    return Column(
      children: [
        if (info.version.isNotEmpty)
          _infoTile(Icons.code, 'Firmware', info.version),
        if (info.ssid.isNotEmpty) _infoTile(Icons.wifi, 'WiFi SSID', info.ssid),
        if (info.ip.isNotEmpty || info.mask.isNotEmpty)
          _infoTile(Icons.router, 'IP / Mask', '${info.ip} / ${info.mask}'),
        if (info.gw.isNotEmpty || info.dns.isNotEmpty)
          _infoTile(Icons.dns, 'Gateway / DNS', '${info.gw} / ${info.dns}'),
        _infoTile(
          Icons.cloud_done,
          'Connection',
          info.connected ? 'Connected' : 'Disconnected',
        ),
        _infoTile(Icons.sync, 'Roaming', info.roaming ? 'Enabled' : 'Disabled'),
        _infoTile(Icons.network_check, 'NTP', cs.ntp ? 'OK' : 'Failed'),
        _infoTile(Icons.dns_outlined, 'DNS', cs.dns ? 'OK' : 'Failed'),
        _infoTile(Icons.handshake, 'Handshake', cs.handshake ? 'OK' : 'Failed'),
        _infoTile(Icons.login, 'Login', cs.login ? 'OK' : 'Failed'),
      ],
    );
  }

  Widget _infoTile(IconData? icon, String title, String value) {
    return ListTile(
      dense: true,
      leading: icon != null ? Icon(icon, size: 20) : null,
      title: Text(title, style: const TextStyle(fontSize: 13)),
      trailing: Text(value, style: const TextStyle(fontSize: 13)),
    );
  }
}

/// Tile showing the current LCS button action URL, with a picker to change it.
class _LcsButtonActionTile extends StatefulWidget {
  const _LcsButtonActionTile({required this.device});

  final DeviceEntity device;

  @override
  State<_LcsButtonActionTile> createState() => _LcsButtonActionTileState();
}

class _LcsButtonActionTileState extends State<_LcsButtonActionTile> {
  String? _currentUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ip = widget.device.bestIp;
    if (ip == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final remote = DeviceRemoteDataSource(
        DeviceHttpClient(token: widget.device.token),
      );
      final url = await remote.getLcsButtonAction(ip);
      if (!mounted) return;
      setState(() {
        _currentUrl = url;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pick() async {
    final devices = context.read<DeviceProvider>().devices;
    final ip = widget.device.bestIp;
    if (ip == null) return;
    final url = await showDialog<String>(
      context: context,
      builder: (_) => ActionUrlPicker(
        devices: devices,
        onUrlGenerated: (u) => Navigator.pop(context, u),
      ),
    );
    if (url == null || !mounted) return;
    try {
      final remote = DeviceRemoteDataSource(
        DeviceHttpClient(token: widget.device.token),
      );
      await remote.setLcsButtonAction(ip, url);
      if (!mounted) return;
      setState(() => _currentUrl = url);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Button action saved: $url')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const Key('lcs_action_tile'),
      leading: const Icon(Icons.touch_app),
      title: const Text('Button action'),
      subtitle: Text(
        _loading
            ? 'Loading...'
            : (_currentUrl != null && _currentUrl!.isNotEmpty
                  ? _currentUrl!
                  : 'Not configured'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _pick,
    );
  }
}
