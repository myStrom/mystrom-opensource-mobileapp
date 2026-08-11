import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/device_http_client.dart';
import '../../core/network/wifi_platform.dart';
import '../../core/utils/device_type.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/wifi_network.dart';
import '../../data/repositories/provisioning_repository.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/provision_wifi.dart';
import '../providers/device_provider.dart';
import '../providers/provisioning_provider.dart';
import '../widgets/add_device_dialog.dart';
import '../widgets/discovered_device_card.dart';

/// WiFi provisioning wizard (SoftAP + WPS) + discovered devices tab.
/// See the API docs
class AddDevicePage extends StatelessWidget {
  const AddDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('add_device_back_button'),
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Add Device'),
          bottom: const TabBar(
            tabs: [
              Tab(key: Key('tab_discovered'), text: 'Discovered'),
              Tab(key: Key('tab_softap'), text: 'SoftAP'),
              Tab(key: Key('tab_wps'), text: 'WPS'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_DiscoveredTab(), _SoftApTab(), _WpsTab()],
        ),
      ),
    );
  }
}

/// Shows devices already found on the local network via UDP discovery
/// that are not yet added to the database. User can add them with one tap.
class _DiscoveredTab extends StatelessWidget {
  const _DiscoveredTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        final fresh = provider.newDevices;

        if (fresh.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No new devices found on the local network.\n\n'
                'Make sure your myStrom devices are powered on and connected '
                'to the same WiFi. Discovery runs automatically in the background.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: fresh.length,
          itemBuilder: (context, index) {
            final d = fresh[index];
            return DiscoveredDeviceCard(
              device: d,
              onAdd: () async {
                final result = await showDialog<AddDeviceResult>(
                  context: context,
                  builder: (_) => AddDeviceDialog(device: d),
                );
                if (result != null && context.mounted) {
                  provider.addDevice(
                    d,
                    customName: result.customName,
                    colorValue: result.colorValue,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${d.type.displayName} added'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () => provider.removeDevice(d.mac),
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class _SoftApTab extends StatefulWidget {
  const _SoftApTab();

  @override
  State<_SoftApTab> createState() => _SoftApTabState();
}

class _SoftApTabState extends State<_SoftApTab> {
  late final ProvisioningProvider _provider;
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ipController = TextEditingController(text: AppConfig.softApDefaultIp);
  final _nameController = TextEditingController();
  final _staticIpController = TextEditingController();
  final _maskController = TextEditingController();
  final _gwController = TextEditingController();
  final _dnsController = TextEditingController();
  WifiNetworkModel? _selectedNetwork;
  bool _showAdvanced = false;
  bool _roaming = false;

  @override
  void initState() {
    super.initState();
    _provider = ProvisioningProvider(
      ProvisionWifi(
        ProvisioningRepository(
          DeviceRemoteDataSource(
            DeviceHttpClient(timeout: AppConfig.provisioningTimeout),
          ),
          // Short-timeout (5s) client for the /api/v1/info probe so the
          // wizard doesn't block for 30s when the device doesn't answer.
          infoRemote: DeviceRemoteDataSource(
            DeviceHttpClient(timeout: const Duration(seconds: 5)),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _ipController.dispose();
    _nameController.dispose();
    _staticIpController.dispose();
    _maskController.dispose();
    _gwController.dispose();
    _dnsController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<ProvisioningProvider>(
        builder: (context, p, _) {
          switch (p.stage) {
            case ProvisioningStage.selectAp:
              return _SelectApStep(provider: p, onManual: _onManualAp);
            case ProvisioningStage.scanNetworks:
              return _ScanNetworksStep(
                provider: p,
                ipController: _ipController,
                onScanned: () => setState(() {}),
              );
            case ProvisioningStage.enterCredentials:
              return _CredentialsStep(
                provider: p,
                ssidController: _ssidController,
                passwordController: _passwordController,
                nameController: _nameController,
                ipController: _ipController,
                staticIpController: _staticIpController,
                maskController: _maskController,
                gwController: _gwController,
                dnsController: _dnsController,
                selectedNetwork: _selectedNetwork,
                showAdvanced: _showAdvanced,
                roaming: _roaming,
                onToggleAdvanced: () =>
                    setState(() => _showAdvanced = !_showAdvanced),
                onRoamingChanged: (v) => setState(() => _roaming = v),
                onNetworkSelected: (n) => setState(() {
                  _selectedNetwork = n;
                  _ssidController.text = n?.ssid ?? '';
                }),
                onSend: () => _sendCredentials(context),
              );
            case ProvisioningStage.sending:
              return const _SendingStep();
            case ProvisioningStage.done:
              return _DoneStep(
                provider: p,
                nameController: _nameController,
                onRestart: () {
                  _provider.reset();
                  _ssidController.clear();
                  _passwordController.clear();
                  _nameController.clear();
                  _staticIpController.clear();
                  _maskController.clear();
                  _gwController.clear();
                  _dnsController.clear();
                  _selectedNetwork = null;
                  _showAdvanced = false;
                  _roaming = false;
                },
              );
            case ProvisioningStage.error:
              return _ErrorStep(provider: p, onRetry: () => _provider.reset());
          }
        },
      ),
    );
  }

  /// Manual AP entry (hidden network or AP not detected by the OS scan).
  void _onManualAp() {
    // Use a generic placeholder; the exact type will be confirmed via
    // /api/v1/info after we connect.
    _provider.selectAp(
      WifiApCandidate(ssid: '', bssid: '', signal: 0, type: DeviceType.unknown),
    );
  }

  Future<void> _sendCredentials(BuildContext context) async {
    final ok = await _provider.sendCredentials(
      _ssidController.text,
      _passwordController.text.isEmpty ? null : _passwordController.text,
      ip: _ipController.text,
      staticIp: _staticIpController.text.isEmpty
          ? null
          : _staticIpController.text,
      mask: _maskController.text.isEmpty ? null : _maskController.text,
      gw: _gwController.text.isEmpty ? null : _gwController.text,
      dns: _dnsController.text.isEmpty ? null : _dnsController.text,
      roaming: _roaming,
    );
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Credentials sent. The device will reboot and join your WiFi.',
          ),
        ),
      );
    }
  }
}

/// Per-device-type instructions for entering AP mode and the LED
/// signals during provisioning. Shown on the AP-selection step so the
/// user knows how to put *their* device into AP mode (the procedure
/// differs between switches, buttons and the bulb).
class _ApModeInstructions extends StatelessWidget {
  const _ApModeInstructions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      key: const Key('softap_ap_instructions'),
      title: const Text('How to enter AP mode'),
      subtitle: const Text('Differs by device type — tap to expand'),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium!,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InstructionBlock(
                  title:
                      'Switches (WS2, WSE, WSX), Strip (WRS), '
                      'Cube (WLL), PIR (WMS), LCS',
                  steps: [
                    'Factory reset: hold the "+" button for 10–20 s until '
                        'the LED blinks white.',
                    'After reset the LED blinks red briefly, then the '
                        'device enters AP mode.',
                  ],
                ),
                SizedBox(height: 12),
                _InstructionBlock(
                  title: 'Buttons (BP2, BM1, WBS/WBP)',
                  steps: [
                    'Factory reset: hold any button for 10–20 s until the '
                        'LED blinks alternating white/red, then release and '
                        'press once more within 2 s to confirm (LED blinks '
                        'white).',
                    'After reset the device starts in WPS mode (white '
                        'blink, 2 min). To switch to AP mode, hold the '
                        'button for 3 s — the LED blinks slowly alternating '
                        'white/red.',
                  ],
                ),
                SizedBox(height: 12),
                _InstructionBlock(
                  title: 'Bulb (WRB)',
                  steps: [
                    'Factory reset: cycle power off/on 5 times with ~5 s '
                        'pauses. After the 5th "on" the bulb blinks white '
                        '10×.',
                    'WPS mode runs for 3 min (white blink), then AP mode '
                        'starts automatically and runs for 5 min.',
                  ],
                ),
                SizedBox(height: 12),
                _InstructionBlock(
                  title: 'LED signals (all devices)',
                  steps: [
                    'Fast red blink — connecting to WiFi.',
                    'Slow red blink — connected, getting IP.',
                    'White blink — connecting to cloud.',
                    '3× green — connected successfully.',
                    '3× red — connection failed.',
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A titled bullet list used inside [_ApModeInstructions].
class _InstructionBlock extends StatelessWidget {
  const _InstructionBlock({required this.title, required this.steps});

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        for (final s in steps)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(s)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Step 1 — pick a myStrom device AP from the host WiFi scan, or enter
/// the SSID manually.
class _SelectApStep extends StatelessWidget {
  const _SelectApStep({required this.provider, required this.onManual});

  final ProvisioningProvider provider;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Put your device into AP mode (see instructions below), then pick '
          'it from the list or connect to its WiFi manually and tap '
          '"I\'m connected".',
        ),
        const SizedBox(height: 8),
        const _ApModeInstructions(),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('softap_scan_aps'),
          icon: const Icon(Icons.wifi_find),
          label: const Text('Scan for myStrom devices'),
          onPressed: provider.busy ? null : provider.scanForAps,
        ),
        const SizedBox(height: 8),
        if (provider.busy)
          const Center(child: CircularProgressIndicator())
        else if (provider.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              provider.error!,
              style: const TextStyle(color: Colors.red),
            ),
          )
        else if (provider.apCandidates.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No myStrom APs found.\n\n'
              '• Make sure the device is in AP mode.\n'
              '• Grant Location permission (Settings → Apps → mystrom_local → Permissions).\n'
              '• Turn on Location (GPS) in system settings — Android requires it for WiFi scans.\n'
              '• If you are already connected to the device AP, tap "I\'m already connected" below.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          for (final ap in provider.apCandidates)
            ListTile(
              key: Key('ap_candidate_${ap.ssid}'),
              leading: Icon(_iconForType(ap.type), color: Colors.blue),
              title: Text(ap.ssid),
              subtitle: Text('${ap.type.displayName} • ${ap.signal} dBm'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => provider.selectAp(ap),
            ),
        const Divider(),
        TextButton.icon(
          key: const Key('softap_manual_connected'),
          icon: const Icon(Icons.check),
          label: const Text("I'm already connected to the device AP"),
          onPressed: onManual,
        ),
      ],
    );
  }
}

/// Step 2 — the host is on the device AP; scan for home WiFi networks
/// through the device (`GET /api/v1/scan`).
class _ScanNetworksStep extends StatelessWidget {
  const _ScanNetworksStep({
    required this.provider,
    required this.ipController,
    required this.onScanned,
  });

  final ProvisioningProvider provider;
  final TextEditingController ipController;
  final VoidCallback onScanned;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.selectedAp != null)
          Card(
            child: ListTile(
              leading: Icon(
                _iconForType(provider.selectedAp!.type),
                color: Colors.blue,
              ),
              title: Text(
                provider.selectedAp!.ssid.isEmpty
                    ? 'Connected (manual)'
                    : provider.selectedAp!.ssid,
              ),
              subtitle: Text(
                provider.deviceInfo != null
                    ? '${provider.deviceInfo!.type.toUpperCase()} • '
                          'MAC ${provider.deviceInfo!.mac}'
                    : provider.selectedAp!.type.displayName,
              ),
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Scan for the WiFi networks the device can see. This takes up to 5s.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: ipController,
          decoration: const InputDecoration(
            labelText: 'Device AP IP',
            hintText: AppConfig.softApDefaultIp,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('softap_scan_wifi'),
          icon: const Icon(Icons.wifi),
          label: const Text('Scan WiFi networks'),
          onPressed: provider.busy
              ? null
              : () async {
                  await provider.scanNetworks(ipController.text);
                  onScanned();
                },
        ),
        const SizedBox(height: 16),
        if (provider.busy)
          const Center(child: CircularProgressIndicator())
        else if (provider.error != null)
          Text(provider.error!, style: const TextStyle(color: Colors.red))
        else if (provider.networks.isEmpty)
          const Text(
            'No networks found. Tap "Scan" again or enter the SSID manually '
            'on the next step.',
            style: TextStyle(color: Colors.grey),
          )
        else
          for (final n in provider.networks)
            ListTile(
              key: Key('wifi_net_${n.ssid}'),
              leading: Icon(_barsForSignal(n.signal)),
              title: Text(n.ssid),
              subtitle: Text('${n.signal} dBm'),
              onTap: () {
                provider.skipToCredentials();
              },
            ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          key: const Key('softap_skip_scan'),
          icon: const Icon(Icons.edit),
          label: const Text('Enter SSID manually (hidden network)'),
          onPressed: provider.busy
              ? null
              : () {
                  provider.skipToCredentials();
                },
        ),
      ],
    );
  }
}

/// Step 3 — enter SSID + password (+ advanced static IP / name / color).
class _CredentialsStep extends StatelessWidget {
  const _CredentialsStep({
    required this.provider,
    required this.ssidController,
    required this.passwordController,
    required this.nameController,
    required this.ipController,
    required this.staticIpController,
    required this.maskController,
    required this.gwController,
    required this.dnsController,
    required this.selectedNetwork,
    required this.showAdvanced,
    required this.roaming,
    required this.onToggleAdvanced,
    required this.onRoamingChanged,
    required this.onNetworkSelected,
    required this.onSend,
  });

  final ProvisioningProvider provider;
  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final TextEditingController ipController;
  final TextEditingController staticIpController;
  final TextEditingController maskController;
  final TextEditingController gwController;
  final TextEditingController dnsController;
  final WifiNetworkModel? selectedNetwork;
  final bool showAdvanced;
  final bool roaming;
  final VoidCallback onToggleAdvanced;
  final ValueChanged<bool> onRoamingChanged;
  final ValueChanged<WifiNetworkModel?> onNetworkSelected;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.networks.isNotEmpty) ...[
          const Text('Pick a network or type the SSID:'),
          const SizedBox(height: 8),
          RadioGroup<WifiNetworkModel>(
            groupValue: selectedNetwork,
            onChanged: onNetworkSelected,
            child: Column(
              children: provider.networks
                  .map(
                    (n) => ListTile(
                      key: Key('cred_net_${n.ssid}'),
                      leading: Icon(_barsForSignal(n.signal)),
                      title: Text(n.ssid),
                      subtitle: Text('${n.signal} dBm'),
                      trailing: Radio<WifiNetworkModel>(value: n),
                      onTap: () => onNetworkSelected(n),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),
        ],
        TextField(
          key: const Key('softap_ssid_field'),
          controller: ssidController,
          decoration: const InputDecoration(
            labelText: 'WiFi SSID',
            hintText: 'HomeWiFi (or hidden network)',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('softap_password_field'),
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'WiFi Password'),
          obscureText: true,
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          key: const Key('softap_advanced'),
          title: const Text('Advanced'),
          initiallyExpanded: showAdvanced,
          onExpansionChanged: (_) => onToggleAdvanced(),
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Device name (optional)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'Device AP IP',
                hintText: AppConfig.softApDefaultIp,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: staticIpController,
              decoration: const InputDecoration(
                labelText: 'Static IP (optional)',
                hintText: '192.168.1.50',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: maskController,
              decoration: const InputDecoration(
                labelText: 'Subnet mask (optional)',
                hintText: '255.255.255.0',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: gwController,
              decoration: const InputDecoration(
                labelText: 'Gateway (optional)',
                hintText: '192.168.1.1',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dnsController,
              decoration: const InputDecoration(
                labelText: 'DNS (optional)',
                hintText: '8.8.8.8',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('softap_roaming_switch'),
              title: const Text('Roaming (802.11r)'),
              value: roaming,
              onChanged: onRoamingChanged,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('softap_send_credentials'),
          icon: const Icon(Icons.send),
          label: const Text('Send credentials'),
          onPressed: provider.busy ? null : onSend,
        ),
      ],
    );
  }
}

/// Step 4 — sending credentials (spinner).
class _SendingStep extends StatelessWidget {
  const _SendingStep();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Sending credentials…'),
        ],
      ),
    );
  }
}

/// Step 5 — done. Offer to add the device to the app's device list
/// (using the MAC from /info if we got it, otherwise the discovery
/// will pick it up after the device reboots onto the home WiFi).
class _DoneStep extends StatelessWidget {
  const _DoneStep({
    required this.provider,
    required this.nameController,
    required this.onRestart,
  });

  final ProvisioningProvider provider;
  final TextEditingController nameController;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final info = provider.deviceInfo;
    final mac = info?.mac ?? '';
    final type = info != null
        ? _typeFromInfo(info.type)
        : provider.selectedAp?.type ?? DeviceType.unknown;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 8),
          const Text(
            'Credentials sent successfully.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'The device is rebooting and joining your WiFi. It should appear '
            'in the Discovered tab within a minute.',
          ),
          if (mac.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('MAC: $mac'),
            Text('Type: ${type.displayName}'),
          ],
          const SizedBox(height: 24),
          if (mac.isNotEmpty)
            FilledButton.icon(
              key: const Key('softap_add_to_list'),
              icon: const Icon(Icons.add),
              label: const Text('Add to device list now'),
              onPressed: () {
                // Add directly with the info we have; the device will be
                // updated with its real IP once UDP discovery picks it up.
                final dp = context.read<DeviceProvider>();
                dp.addDevice(
                  DeviceEntity(
                    mac: mac,
                    name: nameController.text.isEmpty
                        ? type.displayName
                        : nameController.text,
                    type: type,
                    addedAt: DateTime.now(),
                  ),
                  customName: nameController.text.isEmpty
                      ? null
                      : nameController.text,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Device added. It will come online shortly.',
                      ),
                    ),
                  );
                }
                onRestart();
              },
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('softap_done_restart'),
            icon: const Icon(Icons.refresh),
            label: const Text('Provision another device'),
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}

/// Terminal error step.
class _ErrorStep extends StatelessWidget {
  const _ErrorStep({required this.provider, required this.onRetry});

  final ProvisioningProvider provider;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          const Text(
            'Provisioning failed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            provider.error ?? 'Unknown error',
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('softap_error_retry'),
            icon: const Icon(Icons.refresh),
            label: const Text('Start over'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

IconData _iconForType(DeviceType type) {
  if (type.isBulb) return Icons.lightbulb_outline;
  if (type.isStrip) return Icons.light_mode;
  if (type.isDimmer) return Icons.tune;
  if (type.isPir) return Icons.sensors;
  if (type.isButton) return Icons.smart_button;
  return Icons.power;
}

IconData _barsForSignal(int dbm) {
  if (dbm >= -50) return Icons.signal_wifi_4_bar;
  if (dbm >= -60) return Icons.network_wifi_3_bar;
  if (dbm >= -70) return Icons.network_wifi_2_bar;
  return Icons.network_wifi_1_bar;
}

DeviceType _typeFromInfo(String infoType) {
  final t = infoType.toLowerCase();
  return switch (t) {
    'ws2' => DeviceType.ws2,
    'wse' => DeviceType.wse,
    'wsx' => DeviceType.wsx,
    'strip' || 'wrs' => DeviceType.wrs,
    'cube' || 'wll' => DeviceType.wll,
    'pir' || 'wms' => DeviceType.wms,
    'bp2' => DeviceType.bp2,
    'bm1' => DeviceType.bm1,
    'bulb' || 'wrb' => DeviceType.bulb,
    'lcs' => DeviceType.lcs,
    'button' || 'wbs' || 'wbp' => DeviceType.button,
    _ => DeviceType.unknown,
  };
}

class _WpsTab extends StatelessWidget {
  const _WpsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'WPS lets the device join your WiFi by pairing with your router. '
          'The procedure to enter WPS mode differs by device type:',
        ),
        const SizedBox(height: 12),
        const _InstructionBlock(
          title:
              'Switches (WS2, WSE, WSX), Strip (WRS), Cube (WLL), '
              'PIR (WMS), LCS',
          steps: [
            'Hold the "+" button for 3 s — the LED starts blinking white '
                'slowly.',
            'Within 2 min, press the WPS button on your router.',
            'The device connects automatically and the LED blinks 3× green '
                'on success (3× red on failure).',
          ],
        ),
        const SizedBox(height: 12),
        const _InstructionBlock(
          title: 'Buttons (BP2, BM1, WBS/WBP)',
          steps: [
            'Factory reset: hold any button for 10–20 s until the LED '
                'blinks alternating white/red, release and press once more '
                'within 2 s to confirm (LED blinks white).',
            'After reset the device starts in WPS mode automatically '
                '(white blink, 2 min).',
            'Press the WPS button on your router within that window.',
            '3× green blink = success, 3× red = failure.',
          ],
        ),
        const SizedBox(height: 12),
        const _InstructionBlock(
          title: 'Bulb (WRB)',
          steps: [
            'Factory reset: cycle power off/on 5× with ~5 s pauses. After '
                'the 5th "on" the bulb blinks white 10×.',
            'WPS mode runs for 3 min (white blink). Press WPS on your '
                'router during this window.',
            '3× green blink = success, 3× red = failure.',
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('wps_trigger'),
          icon: const Icon(Icons.wifi_tethering),
          label: const Text('Trigger WPS on device'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Make sure the device is in WPS mode, then press WPS on '
                  'your router.',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
