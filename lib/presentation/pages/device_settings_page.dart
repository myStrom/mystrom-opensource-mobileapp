import 'package:flutter/material.dart';

import '../utils/device_error_message.dart';
import 'package:provider/provider.dart';

import '../../core/network/device_http_client.dart';
import '../../core/network/device_auth.dart';
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
  final _tokenController = TextEditingController();
  bool _updatingToken = false;

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
    _tokenController.dispose();
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
      if (!mounted) return;
      setState(() {
        _info = info;
        _loadingInfo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _infoError = deviceErrorMessage(e, AppLocalizations.of(context));
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

  Future<void> _updateToken() async {
    final l10n = AppLocalizations.of(context);
    final ip = widget.device.bestIp;
    if (ip == null) {
      _snack(l10n.noIpAddress);
      return;
    }
    final token = _tokenController.text;
    if (token.length > 255 || token.runes.any((c) => c < 32 || c > 126)) {
      _snack(l10n.tokenInvalid);
      return;
    }
    setState(() => _updatingToken = true);
    final client = DeviceHttpClient();
    try {
      await DeviceRemoteDataSource(client).setToken(ip, token);
      // Use the proposed credential directly; never let auth recovery mask
      // a settings endpoint that ignored the requested change.
      final valid = await client.verifyToken(ip, token.isEmpty ? null : token);
      final protected = token.isEmpty || !await client.verifyToken(ip, null);
      if (!valid || !protected) throw StateError('Token change unconfirmed');
      await DeviceAuth.shared?.accept(
        ip,
        token.isEmpty ? null : token,
        remember: true,
      );
      if (!mounted) return;
      _tokenController.clear();
      _snack(l10n.tokenUpdated);
    } catch (_) {
      if (mounted) _snack(l10n.tokenUpdateFailed);
    } finally {
      client.dispose();
      if (mounted) setState(() => _updatingToken = false);
    }
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

            const SizedBox(height: 24),
            TextField(
              key: const Key('settings_token_field'),
              controller: _tokenController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enabled: !_updatingToken,
              decoration: InputDecoration(
                labelText: l10n.deviceToken,
                helperText: l10n.tokenSettingsHint,
                helperMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: const Key('settings_token_apply'),
              onPressed: _updatingToken ? null : _updateToken,
              icon: const Icon(Icons.key),
              label: Text(
                _updatingToken ? l10n.loadingEllipsis : l10n.changeDeviceToken,
              ),
            ),

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
              if (d.type == DeviceType.lcs)
                _SingleButtonActionTile(
                  device: d,
                  key: const Key('lcs_action_tile'),
                )
              else
                _LocalActionSection(device: d),
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
              _LocalActionSection(device: d),
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
    if (_tokenController.text.isNotEmpty) return true;
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
        _infoTile(Icons.dns_outlined, l10n.dns, cs.dns ? l10n.ok : l10n.failed),
        _infoTile(
          Icons.handshake,
          l10n.handshake,
          cs.handshake ? l10n.ok : l10n.failed,
        ),
        _infoTile(Icons.login, l10n.login, cs.login ? l10n.ok : l10n.failed),
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
          content: Text(AppLocalizations.of(context).buttonActionSaved(url)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).saveFailed(deviceErrorMessage(e, AppLocalizations.of(context))),
          ),
        ),
      );
    }
  }

  /// Clear the configured button action by sending an empty URL.
  Future<void> _clear() async {
    final ip = widget.device.bestIp;
    if (ip == null) return;
    try {
      final remote = DeviceRemoteDataSource(
        DeviceHttpClient(token: widget.device.token),
      );
      await remote.setLcsButtonAction(ip, '');
      if (!mounted) return;
      setState(() => _currentUrl = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).buttonActionRemoved),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).removeFailed(deviceErrorMessage(e, AppLocalizations.of(context))),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final configured = _currentUrl != null && _currentUrl!.isNotEmpty;
    return ListTile(
      leading: const Icon(Icons.touch_app),
      title: Text(l10n.buttonAction),
      subtitle: Text(
        _loading
            ? l10n.loading
            : (configured ? _currentUrl! : l10n.notConfigured),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: configured
          ? IconButton(
              key: const Key('lcs_action_delete_button'),
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.removeAction,
              onPressed: _clear,
            )
          : const Icon(Icons.chevron_right),
      onTap: _pick,
    );
  }
}

/// Shared action editor for the six PIR slots and the three relay slots.
class _LocalActionSection extends StatefulWidget {
  const _LocalActionSection({required this.device});

  final DeviceEntity device;

  @override
  State<_LocalActionSection> createState() => _LocalActionSectionState();
}

class _LocalActionSectionState extends State<_LocalActionSection>
    with AutomaticKeepAliveClientMixin<_LocalActionSection> {
  static const _pirIcons = {
    'generic': Icons.sensors,
    'night': Icons.nightlight,
    'twilight': Icons.brightness_3,
    'day': Icons.wb_sunny,
    'rise': Icons.notifications_active,
    'fall': Icons.notifications_off,
  };
  static const _switchIcons = {
    'on': Icons.power_settings_new,
    'off': Icons.power_off,
    'generic': Icons.touch_app,
  };

  Map<String, String>? _urls;
  String? _error;
  bool _busy = true;

  bool get _isPir => widget.device.type.isPir;
  String get _keyPrefix => _isPir ? 'pir_action' : 'switch_action';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() => _request();

  Future<void> _request({String? slot, String? url}) async {
    final ip = widget.device.bestIp;
    if (ip == null) {
      setState(() => _busy = false);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final client = DeviceHttpClient(token: widget.device.token);
    final remote = DeviceRemoteDataSource(client);
    try {
      final Map<String, String> confirmed;
      if (slot == null) {
        confirmed = await (_isPir
            ? remote.getPirActions(ip)
            : remote.getSwitchButtonActions(ip));
      } else {
        confirmed = await (_isPir
            ? remote.setPirAction(ip, slot, url: url!)
            : remote.setSwitchButtonAction(ip, slot, url: url!));
      }
      if (!mounted) return;
      setState(() => _urls = confirmed);
      if (slot != null) {
        final l10n = AppLocalizations.of(context);
        final label = _label(l10n, slot);
        _snack(
          url!.isEmpty
              ? l10n.slotActionRemoved(label)
              : l10n.slotActionSaved(label, url),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final reason = deviceErrorMessage(error, l10n);
      var message = reason;
      if (slot != null) {
        message = url!.isEmpty
            ? l10n.removeFailed(reason)
            : l10n.saveFailed(reason);
      }
      setState(() => _error = message);
      if (slot != null) _snack(message);
    } finally {
      client.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pick(String slot) async {
    final devices = context.read<DeviceProvider>().devices;
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => ActionUrlPicker(
        devices: devices,
        onUrlGenerated: (url) => Navigator.pop(dialogContext, url),
      ),
    );
    if (mounted && url != null) await _request(slot: slot, url: url);
  }

  String _label(AppLocalizations l10n, String slot) {
    if (_isPir) return localizedPirSlotLabel(l10n, slot);
    return switch (slot) {
      'on' => l10n.whenRelayTurnsOn,
      'off' => l10n.whenRelayTurnsOff,
      _ => l10n.generic,
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    if (widget.device.bestIp == null) {
      return ListTile(title: Text(l10n.noIpAddress));
    }
    if (_error != null) {
      return ListTile(
        title: Text(_error!),
        trailing: TextButton(
          key: Key('${_keyPrefix}_retry'),
          onPressed: _busy ? null : _load,
          child: Text(l10n.retry),
        ),
      );
    }
    final urls = _urls;
    if (urls == null) return const LinearProgressIndicator();
    final icons = _isPir ? _pirIcons : _switchIcons;
    return Column(
      children: [
        if (_busy) const LinearProgressIndicator(),
        for (final entry in icons.entries)
          ListTile(
            key: Key('${_keyPrefix}_${entry.key}_tile'),
            leading: Icon(entry.value),
            title: Text(_label(l10n, entry.key)),
            subtitle: Text(
              urls[entry.key]!.isEmpty ? l10n.notConfigured : urls[entry.key]!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: urls[entry.key]!.isEmpty
                ? const Icon(Icons.chevron_right)
                : IconButton(
                    key: Key('${_keyPrefix}_${entry.key}_delete_button'),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.removeAction,
                    onPressed: _busy
                        ? null
                        : () => _request(slot: entry.key, url: ''),
                  ),
            onTap: _busy ? null : () => _pick(entry.key),
          ),
      ],
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
        _error = deviceErrorMessage(e, AppLocalizations.of(context));
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final ip = widget.device.bestIp;
    if (ip == null || _night == null || _day == null) return;
    if (_night! >= _day!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).nightThresholdBelowDay),
        ),
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
          content: Text(
            AppLocalizations.of(
              context,
            ).saveFailed(deviceErrorMessage(e, AppLocalizations.of(context))),
          ),
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
        _error = deviceErrorMessage(e, AppLocalizations.of(context));
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
          content: Text(
            AppLocalizations.of(
              context,
            ).saveFailed(deviceErrorMessage(e, AppLocalizations.of(context))),
          ),
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
