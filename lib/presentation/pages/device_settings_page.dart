import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/device_http_client.dart';
import '../../core/utils/device_type.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/device_info.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/identify_device.dart';
import '../../l10n/app_localizations.dart';
import '../providers/device_provider.dart';
import '../utils/action_l10n.dart';
import '../utils/device_type_l10n.dart';
import '../utils/number_format.dart';
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
  bool _noIp = false;
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
        _noIp = true;
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
    final l10n = AppLocalizations.of(context);
    final ip = widget.device.bestIp;
    if (ip == null) {
      _snack(l10n.noIpAddress);
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
    _snack(l10n.identifySignalSent);
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
    final l10n = AppLocalizations.of(context);
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
            Text(
              l10n.deviceNameSection,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('settings_name_field'),
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.customName,
                hintText: d.name,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('settings_room_field'),
              controller: _roomController,
              decoration: InputDecoration(
                labelText: l10n.room,
                border: const OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              key: const Key('settings_favorite_switch'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.favorite),
              subtitle: Text(
                l10n.favoriteSubtitle,
                style: const TextStyle(fontSize: 12),
              ),
              value: _favorite,
              onChanged: (v) => setState(() => _favorite = v),
            ),
            // Lock on/off is only meaningful for devices with a power toggle.
            // PIR (WMS) and buttons (BP1/BP2/BM1/Button) have no on/off
            // state, so the option is hidden there.
            if (!d.type.isPir && !d.type.isButton)
              SwitchListTile(
                key: const Key('settings_lockable_switch'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.lockOnOff),
                subtitle: Text(
                  l10n.lockOnOffSubtitle,
                  style: const TextStyle(fontSize: 12),
                ),
                value: _lockable,
                onChanged: (v) => setState(() => _lockable = v),
              ),

            // ---- Temperature offset (devices with temperature sensor) ----
            if (d.type.hasTemperature) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text(l10n.temperatureOffset)),
                  Text(
                    l10n.temperatureOffsetValue(
                      _tempOffset >= 0 ? '+' : '',
                      formatDecimal(context, _tempOffset, 1),
                    ),
                  ),
                ],
              ),
              Slider(
                key: const Key('settings_temp_offset_slider'),
                min: -30,
                max: 30,
                divisions: 600,
                value: _tempOffset,
                label: l10n.temperatureCelsius(
                  formatDecimal(context, _tempOffset, 1),
                ),
                onChanged: (v) =>
                    setState(() => _tempOffset = (v * 10).round() / 10),
              ),
            ],

            // ---- Tile color ----
            const SizedBox(height: 24),
            const Divider(),
            Text(
              l10n.tileColor,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tileColorSubtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                title: Text(l10n.stripChannelMode),
                subtitle: Text(l10n.stripChannelModeSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StripSettingsPage(device: d),
                  ),
                ),
              ),
            ],

            // ---- Button action URL (LCS + WS2/WSE/WSX switches) ----
            if (d.type == DeviceType.lcs ||
                d.type == DeviceType.ws2 ||
                d.type == DeviceType.wse ||
                d.type == DeviceType.wsx) ...[
              const SizedBox(height: 24),
              const Divider(),
              Text(
                l10n.buttonAction,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.buttonActionSubtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              _ButtonActionSection(device: d),
            ],

            // ---- PIR action URLs (WMS) ----
            // The PIR can trigger a URL for each motion/light condition:
            // generic, night, twilight, day, rise, fall.
            if (d.type == DeviceType.wms) ...[
              const SizedBox(height: 24),
              const Divider(),
              Text(
                l10n.pirActions,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.pirActionsSubtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              _PirActionSection(device: d),
            ],

            // ---- PIR light thresholds (WMS) ----
            // Night/day thresholds classify motion events by ambient light.
            if (d.type == DeviceType.wms) ...[
              const SizedBox(height: 24),
              const Divider(),
              _PirThresholdsSection(device: d),
            ],

            // ---- PIR general settings (WMS) ----
            // Backoff time (cooldown after motion) and LED enable toggle.
            if (d.type == DeviceType.wms) ...[
              const SizedBox(height: 24),
              const Divider(),
              _PirSettingsSection(device: d),
            ],

            // ---- Identify (WS2, WSE, WRS, WLL, WMS, Bulb) ----
            if (d.type.identifyAvailable) ...[
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                key: const Key('settings_identify_tile'),
                leading: const Icon(Icons.bubble_chart),
                title: Text(l10n.identify),
                subtitle: Text(l10n.identifySubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _identify(context),
              ),
            ],

            // ---- Device info from /info ----
            const SizedBox(height: 24),
            const Divider(),
            Text(
              l10n.deviceInfo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_loadingInfo)
              const Center(child: CircularProgressIndicator())
            else if (_noIp)
              Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l10n.noIpAddress),
                ),
              )
            else if (_infoError != null)
              Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_infoError!),
                ),
              )
            else if (_info != null)
              _buildInfoSection(l10n, d, _info!)
            else
              Text(l10n.noInfoAvailable),

            // ---- Static info from local DB ----
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(l10n.mac),
              subtitle: Text(d.mac),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: Text(l10n.type),
              subtitle: Text(
                l10n.typeSubtitle(d.type.model, d.type.localizedName(l10n)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.router),
              title: Text(l10n.ip),
              subtitle: Text(d.bestIp ?? l10n.unknown),
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
              label: Text(
                l10n.removeDevice,
                style: const TextStyle(color: Colors.red),
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
            _snack(l10n.saved);
          },
          icon: const Icon(Icons.save),
          label: Text(l10n.save),
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
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.discardChangesTitle),
            content: Text(l10n.discardChangesMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text(l10n.quitWithoutSaving),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildInfoSection(
    AppLocalizations l10n,
    DeviceEntity d,
    DeviceInfoModel info,
  ) {
    final cs = info.connectionStatus;
    return Column(
      children: [
        if (info.version.isNotEmpty)
          _infoTile(Icons.code, l10n.firmware, info.version),
        if (info.ssid.isNotEmpty)
          _infoTile(Icons.wifi, l10n.wifiSsid, info.ssid),
        if (info.ip.isNotEmpty || info.mask.isNotEmpty)
          _infoTile(
            Icons.router,
            l10n.ipMask,
            l10n.ipMaskValue(info.ip, info.mask),
          ),
        if (info.gw.isNotEmpty || info.dns.isNotEmpty)
          _infoTile(
            Icons.dns,
            l10n.gatewayDns,
            l10n.gatewayDnsValue(info.gw, info.dns),
          ),
        _infoTile(
          Icons.cloud_done,
          l10n.connection,
          info.connected ? l10n.connected : l10n.disconnected,
        ),
        _infoTile(
          Icons.sync,
          l10n.roaming,
          info.roaming ? l10n.enabled : l10n.disabled,
        ),
        _infoTile(
          Icons.network_check,
          l10n.ntp,
          cs.ntp ? l10n.ok : l10n.failed,
        ),
        _infoTile(
          Icons.dns_outlined,
          l10n.dns,
          cs.dns ? l10n.ok : l10n.failed,
        ),
        _infoTile(
          Icons.handshake,
          l10n.handshake,
          cs.handshake ? l10n.ok : l10n.failed,
        ),
        _infoTile(
          Icons.login,
          l10n.login,
          cs.login ? l10n.ok : l10n.failed,
        ),
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

/// Button action section — renders the appropriate tile(s) based on type.
///
/// LCS devices have a single button action slot (`/api/v1/action/button`).
/// WS2/WSE/WSX switches have two slots: ON and OFF
/// (`/api/v1/action/relay/on` and `/api/v1/action/relay/off`).
class _ButtonActionSection extends StatefulWidget {
  const _ButtonActionSection({required this.device});

  final DeviceEntity device;

  @override
  State<_ButtonActionSection> createState() => _ButtonActionSectionState();
}

class _ButtonActionSectionState extends State<_ButtonActionSection> {
  bool get _isLcs => widget.device.type == DeviceType.lcs;

  @override
  Widget build(BuildContext context) {
    if (_isLcs) {
      return _SingleButtonActionTile(
        device: widget.device,
        key: const Key('lcs_action_tile'),
      );
    }
    return Column(
      children: [
        _SwitchSlotActionTile(
          device: widget.device,
          slot: 'on',
          key: const Key('switch_action_on_tile'),
        ),
        _SwitchSlotActionTile(
          device: widget.device,
          slot: 'off',
          key: const Key('switch_action_off_tile'),
        ),
      ],
    );
  }
}

/// Single button-action tile for LCS devices (one URL slot).
class _SingleButtonActionTile extends StatefulWidget {
  const _SingleButtonActionTile({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<_SingleButtonActionTile> createState() =>
      _SingleButtonActionTileState();
}

class _SingleButtonActionTileState extends State<_SingleButtonActionTile> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).buttonActionSaved(url),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).saveFailed(e.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.touch_app),
      title: Text(l10n.buttonAction),
      subtitle: Text(
        _loading
            ? l10n.loading
            : (_currentUrl != null && _currentUrl!.isNotEmpty
                  ? _currentUrl!
                  : l10n.notConfigured),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _pick,
    );
  }
}

/// Switch slot action tile — one of "on" or "off" for WS2/WSE/WSX.
class _SwitchSlotActionTile extends StatefulWidget {
  const _SwitchSlotActionTile({
    super.key,
    required this.device,
    required this.slot,
  });

  final DeviceEntity device;
  final String slot; // 'on' or 'off'

  @override
  State<_SwitchSlotActionTile> createState() => _SwitchSlotActionTileState();
}

class _SwitchSlotActionTileState extends State<_SwitchSlotActionTile> {
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
      final actions = await remote.getSwitchButtonActions(ip);
      if (!mounted) return;
      setState(() {
        _currentUrl = widget.slot == 'on' ? actions.on : actions.off;
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
      if (widget.slot == 'on') {
        await remote.setSwitchButtonActionOn(ip, url);
      } else {
        await remote.setSwitchButtonActionOff(ip, url);
      }
      if (!mounted) return;
      setState(() => _currentUrl = url);
      final l10n = AppLocalizations.of(context);
      final slotLabel = widget.slot == 'on' ? l10n.on : l10n.off;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.slotActionSaved(slotLabel, url))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).saveFailed(e.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = widget.slot == 'on'
        ? l10n.whenRelayTurnsOn
        : l10n.whenRelayTurnsOff;
    return ListTile(
      leading: Icon(
        widget.slot == 'on' ? Icons.power_settings_new : Icons.power_off,
      ),
      title: Text(label),
      subtitle: Text(
        _loading
            ? l10n.loading
            : (_currentUrl != null && _currentUrl!.isNotEmpty
                  ? _currentUrl!
                  : l10n.notConfigured),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _pick,
    );
  }
}

/// PIR action section — renders one tile per PIR condition slot.
///
/// WMS (PIR) exposes six action URL slots via
/// `GET/POST /api/v1/action/pir/<generic|night|twilight|day|rise|fall>`.
/// Each slot is a raw text URL body, analogous to the switch on/off slots.
class _PirActionSection extends StatefulWidget {
  const _PirActionSection({required this.device});

  final DeviceEntity device;

  @override
  State<_PirActionSection> createState() => _PirActionSectionState();
}

class _PirActionSectionState extends State<_PirActionSection> {
  /// Ordered PIR condition slots.
  static const _slots = <(String, IconData)>[
    ('generic', Icons.sensors),
    ('night', Icons.nightlight),
    ('twilight', Icons.brightness_3),
    ('day', Icons.wb_sunny),
    ('rise', Icons.notifications_active),
    ('fall', Icons.notifications_off),
  ];

  Map<String, String> _urls = {};
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
      final actions = await remote.getPirActions(ip);
      if (!mounted) return;
      setState(() {
        _urls = actions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pick(String slot) async {
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
      await remote.setPirAction(ip, slot, url: url);
      if (!mounted) return;
      setState(() => _urls[slot] = url);
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.slotActionSaved(localizedPirSlotLabel(l10n, slot), url),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).saveFailed(e.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        for (final (slot, icon) in _slots)
          _PirSlotActionTile(
            key: Key('pir_action_${slot}_tile'),
            label: localizedPirSlotLabel(l10n, slot),
            icon: icon,
            url: _urls[slot] ?? '',
            onTap: () => _pick(slot),
          ),
      ],
    );
  }
}

/// A single PIR condition slot tile showing the configured URL (if any).
class _PirSlotActionTile extends StatelessWidget {
  const _PirSlotActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.url,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(
        url.isNotEmpty ? url : l10n.notConfigured,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// PIR light thresholds section — night/day boundaries used by the PIR
/// to classify motion events by ambient light level.
///
/// `GET /api/v1/settings/pir/thresholds` returns `{"night": <uint>, "day": <uint>}`.
/// `POST` accepts the same JSON; the device rejects (400) when night >= day.
/// Values share the same scale as the `light` field in `/api/v1/sensors`.
class _PirThresholdsSection extends StatefulWidget {
  const _PirThresholdsSection({required this.device});

  final DeviceEntity device;

  @override
  State<_PirThresholdsSection> createState() => _PirThresholdsSectionState();
}

class _PirThresholdsSectionState extends State<_PirThresholdsSection> {
  int? _night;
  int? _day;
  bool _loading = true;
  String? _error;

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
      final t = await remote.getPirThresholds(ip);
      if (!mounted) return;
      setState(() {
        _night = t.night;
        _day = t.day;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final ip = widget.device.bestIp;
    if (ip == null || _night == null || _day == null) return;
    if (_night! >= _day!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).nightThresholdBelowDay)),
      );
      return;
    }
    try {
      final remote = DeviceRemoteDataSource(
        DeviceHttpClient(token: widget.device.token),
      );
      final t = await remote.setPirThresholds(
        ip,
        night: _night!.clamp(0, 65535),
        day: _day!.clamp(0, 65535),
      );
      if (!mounted) return;
      setState(() {
        _night = t.night;
        _day = t.day;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).thresholdsSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).saveFailed(e.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.red.shade100,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_error!),
          ),
        ),
      );
    }
    final night = _night ?? 0;
    final day = _day ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lightThresholds,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.lightThresholdsSubtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Text(l10n.nightValue(night.toString())),
        Slider(
          key: const Key('pir_threshold_night_slider'),
          min: 0,
          max: 65535,
          divisions: 100,
          value: night.clamp(0, 65535).toDouble(),
          label: night.toString(),
          onChanged: (v) => setState(() => _night = v.round()),
        ),
        Text(l10n.dayValue(day.toString())),
        Slider(
          key: const Key('pir_threshold_day_slider'),
          min: 0,
          max: 65535,
          divisions: 100,
          value: day.clamp(0, 65535).toDouble(),
          label: day.toString(),
          onChanged: (v) => setState(() => _day = v.round()),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('pir_threshold_save_button'),
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: Text(l10n.saveThresholds),
        ),
      ],
    );
  }
}

/// PIR general settings section — backoff time and LED enable toggle.
///
/// `GET /api/v1/settings/pir` returns `{"backoff_time": <uint>, "led_enable": <bool>}`.
/// `POST` accepts a partial JSON body; only the included fields are updated.
/// `backoff_time` is the cooldown in seconds after a motion event (1–3600).
class _PirSettingsSection extends StatefulWidget {
  const _PirSettingsSection({required this.device});

  final DeviceEntity device;

  @override
  State<_PirSettingsSection> createState() => _PirSettingsSectionState();
}

class _PirSettingsSectionState extends State<_PirSettingsSection> {
  int? _backoffTime;
  bool? _ledEnable;
  bool _loading = true;
  String? _error;

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
      final s = await remote.getPirSettings(ip);
      if (!mounted) return;
      setState(() {
        _backoffTime = s.backoffTime;
        _ledEnable = s.ledEnable;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final ip = widget.device.bestIp;
    if (ip == null) return;
    try {
      final remote = DeviceRemoteDataSource(
        DeviceHttpClient(token: widget.device.token),
      );
      final s = await remote.setPirSettings(
        ip,
        backoffTime: _backoffTime?.clamp(1, 3600),
        ledEnable: _ledEnable,
      );
      if (!mounted) return;
      setState(() {
        _backoffTime = s.backoffTime;
        _ledEnable = s.ledEnable;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).pirSettingsSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).saveFailed(e.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.red.shade100,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_error!),
          ),
        ),
      );
    }
    final backoff = _backoffTime ?? 60;
    final led = _ledEnable ?? true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pirSettings,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Backoff time is the cooldown in seconds after a motion event '
          '(1–3600). LED enable controls the status indicator on the device.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Text(l10n.backoffTimeValue(backoff.toString())),
        Slider(
          key: const Key('pir_backoff_slider'),
          min: 1,
          max: 3600,
          divisions: 100,
          value: backoff.clamp(1, 3600).toDouble(),
          label: '${backoff}s',
          onChanged: (v) => setState(() => _backoffTime = v.round()),
        ),
        SwitchListTile(
          key: const Key('pir_led_enable_switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.ledEnable),
          subtitle: Text(
            l10n.ledEnableSubtitle,
            style: const TextStyle(fontSize: 12),
          ),
          value: led,
          onChanged: (v) => setState(() => _ledEnable = v),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('pir_settings_save_button'),
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: Text(l10n.savePirSettings),
        ),
      ],
    );
  }
}
