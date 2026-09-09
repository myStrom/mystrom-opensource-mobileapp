import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../l10n/app_localizations.dart';
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
import '../utils/device_type_l10n.dart';
import '../widgets/add_device_dialog.dart';
import '../widgets/discovered_device_card.dart';

/// Host-side WiFi AP scan is only available on Android (iOS has no API for it).
bool get _hostApScanSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// WiFi provisioning wizard (SoftAP + WPS) + discovered devices tab.
/// See the API docs
class AddDevicePage extends StatelessWidget {
  const AddDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('add_device_back_button'),
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(l10n.addDeviceTitle),
          bottom: TabBar(
            tabs: [
              Tab(key: const Key('tab_discovered'), text: l10n.tabDiscovered),
              Tab(key: const Key('tab_softap'), text: l10n.tabSoftAp),
              Tab(key: const Key('tab_wps'), text: l10n.tabWps),
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
    final l10n = AppLocalizations.of(context);
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        final fresh = provider.newDevices;

        if (fresh.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l10n.noNewDevicesFound,
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
                      content: Text(
                        l10n.deviceAddedSnack(d.type.localizedName(l10n)),
                      ),
                      action: SnackBarAction(
                        label: l10n.undo,
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
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.credentialsSentSnackbar)),
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ExpansionTile(
      key: const Key('softap_ap_instructions'),
      title: Text(l10n.howToEnterApMode),
      subtitle: Text(l10n.apModeInstructionsSubtitle),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InstructionBlock(
                  title: l10n.apModeSwitchesTitle,
                  steps: [
                    l10n.apModeSwitchResetStep1,
                    l10n.apModeSwitchResetStep2,
                  ],
                ),
                const SizedBox(height: 12),
                _InstructionBlock(
                  title: l10n.apModeButtonsTitle,
                  steps: [
                    l10n.apModeButtonResetStep1,
                    l10n.apModeButtonResetStep2,
                  ],
                ),
                const SizedBox(height: 12),
                _InstructionBlock(
                  title: l10n.apModeBulbTitle,
                  steps: [
                    l10n.apModeBulbResetStep1,
                    l10n.apModeBulbResetStep2,
                  ],
                ),
                const SizedBox(height: 12),
                _InstructionBlock(
                  title: l10n.apModeLedSignalsTitle,
                  steps: [
                    l10n.apModeLedFastRed,
                    l10n.apModeLedSlowRed,
                    l10n.apModeLedWhite,
                    l10n.apModeLedGreenSuccess,
                    l10n.apModeLedRedFailure,
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
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.softApSelectApIntro),
        const SizedBox(height: 8),
        const _ApModeInstructions(),
        if (_hostApScanSupported) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('softap_scan_aps'),
            icon: const Icon(Icons.wifi_find),
            label: Text(l10n.scanForMyStromDevices),
            onPressed: provider.busy ? null : provider.scanForAps,
          ),
          const SizedBox(height: 8),
          if (provider.busy)
            const Center(child: CircularProgressIndicator())
          else if (provider.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _provisionErrorMessage(provider, l10n),
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (provider.apCandidates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.noMyStromApsFound,
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else
            for (final ap in provider.apCandidates)
              ListTile(
                key: Key('ap_candidate_${ap.ssid}'),
                leading: Icon(_iconForType(ap.type), color: Colors.blue),
                title: Text(ap.ssid),
                subtitle: Text(
                  l10n.apCandidateSubtitle(
                    ap.type.localizedName(l10n),
                    ap.signal.toString(),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => provider.selectAp(ap),
              ),
        ] else
          const SizedBox(height: 16),
        const Divider(),
        TextButton.icon(
          key: const Key('softap_manual_connected'),
          icon: const Icon(Icons.check),
          label: Text(l10n.alreadyConnectedToAp),
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
    final l10n = AppLocalizations.of(context);
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
                    ? l10n.connectedManual
                    : provider.selectedAp!.ssid,
              ),
              subtitle: Text(
                provider.deviceInfo != null
                    ? l10n.deviceInfoMacLine(
                        provider.deviceInfo!.type.toUpperCase(),
                        provider.deviceInfo!.mac,
                      )
                    : provider.selectedAp!.type.localizedName(l10n),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(l10n.scanNetworksIntro),
        const SizedBox(height: 16),
        TextField(
          controller: ipController,
          decoration: InputDecoration(
            labelText: l10n.deviceApIp,
            hintText: AppConfig.softApDefaultIp,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('softap_scan_wifi'),
          icon: const Icon(Icons.wifi),
          label: Text(l10n.scanWifiNetworks),
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
          Text(
            _provisionErrorMessage(provider, l10n),
            style: const TextStyle(color: Colors.red),
          )
        else if (provider.networks.isEmpty)
          Text(
            l10n.noNetworksFound,
            style: const TextStyle(color: Colors.grey),
          )
        else
          for (final n in provider.networks)
            ListTile(
              key: Key('wifi_net_${n.ssid}'),
              leading: Icon(_barsForSignal(n.signal)),
              title: Text(n.ssid),
              subtitle: Text(l10n.signalDbm(n.signal.toString())),
              onTap: () {
                provider.skipToCredentials();
              },
            ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          key: const Key('softap_skip_scan'),
          icon: const Icon(Icons.edit),
          label: Text(l10n.enterSsidManually),
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
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.networks.isNotEmpty) ...[
          Text(l10n.pickNetworkOrSsid),
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
                      subtitle: Text(l10n.signalDbm(n.signal.toString())),
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
          decoration: InputDecoration(
            labelText: l10n.wifiSsid,
            hintText: l10n.wifiSsidHint,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('softap_password_field'),
          controller: passwordController,
          decoration: InputDecoration(labelText: l10n.wifiPassword),
          obscureText: true,
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          key: const Key('softap_advanced'),
          title: Text(l10n.advanced),
          initiallyExpanded: showAdvanced,
          onExpansionChanged: (_) => onToggleAdvanced(),
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.deviceNameOptional,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ipController,
              decoration: InputDecoration(
                labelText: l10n.deviceApIp,
                hintText: AppConfig.softApDefaultIp,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: staticIpController,
              decoration: InputDecoration(
                labelText: l10n.staticIpOptional,
                hintText: '192.168.1.50',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: maskController,
              decoration: InputDecoration(
                labelText: l10n.subnetMaskOptional,
                hintText: '255.255.255.0',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: gwController,
              decoration: InputDecoration(
                labelText: l10n.gatewayOptional,
                hintText: '192.168.1.1',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dnsController,
              decoration: InputDecoration(
                labelText: l10n.dnsOptional,
                hintText: '8.8.8.8',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('softap_roaming_switch'),
              title: Text(l10n.roaming80211r),
              value: roaming,
              onChanged: onRoamingChanged,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('softap_send_credentials'),
          icon: const Icon(Icons.send),
          label: Text(l10n.sendCredentials),
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
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n.sendingCredentials),
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
    final l10n = AppLocalizations.of(context);
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
          Text(
            l10n.credentialsSentSuccess,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(l10n.deviceRebootingMessage),
          if (mac.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.macLabel(mac)),
            Text(l10n.typeLabel(type.localizedName(l10n))),
          ],
          const SizedBox(height: 24),
          if (mac.isNotEmpty)
            FilledButton.icon(
              key: const Key('softap_add_to_list'),
              icon: const Icon(Icons.add),
              label: Text(l10n.addToDeviceListNow),
              onPressed: () {
                // Add directly with the info we have; the device will be
                // updated with its real IP once UDP discovery picks it up.
                final dp = context.read<DeviceProvider>();
                dp.addDevice(
                  DeviceEntity(
                    mac: mac,
                    name: nameController.text.isEmpty
                        ? type.localizedName(l10n)
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
                    SnackBar(content: Text(l10n.deviceAddedWillComeOnline)),
                  );
                }
                onRestart();
              },
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('softap_done_restart'),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.provisionAnotherDevice),
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
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(
            l10n.provisioningFailed,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            provider.error != null
                ? _provisionErrorMessage(provider, l10n)
                : l10n.unknownError,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('softap_error_retry'),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.startOver),
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

/// Formats [ProvisioningProvider.error] for display (localizes scan failures).
String _provisionErrorMessage(
  ProvisioningProvider provider,
  AppLocalizations l10n,
) {
  final err = provider.error!;
  if (provider.scanWifiError) return l10n.couldNotScanWifi(err);
  return err;
}

class _WpsTab extends StatelessWidget {
  const _WpsTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.wpsIntro),
        const SizedBox(height: 12),
        _InstructionBlock(
          title: l10n.apModeSwitchesTitle,
          steps: [
            l10n.wpsSwitchStep1,
            l10n.wpsSwitchStep2,
            l10n.wpsSwitchStep3,
          ],
        ),
        const SizedBox(height: 12),
        _InstructionBlock(
          title: l10n.apModeButtonsTitle,
          steps: [
            l10n.apModeButtonResetStep1,
            l10n.wpsButtonWpsModeAuto,
            l10n.wpsButtonPressRouter,
            l10n.wpsResultHint,
          ],
        ),
        const SizedBox(height: 12),
        _InstructionBlock(
          title: l10n.apModeBulbTitle,
          steps: [
            l10n.wpsBulbReset,
            l10n.wpsBulbMode,
            l10n.wpsResultHint,
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('wps_trigger'),
          icon: const Icon(Icons.wifi_tethering),
          label: Text(l10n.triggerWpsOnDevice),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.wpsTriggerSnackbar)),
            );
          },
        ),
      ],
    );
  }
}
