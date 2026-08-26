import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Placeholder WiFi setup page.
///
/// Reuses the provisioning wizard from [AddDevicePage] for a device that
/// is already on the network but needs reconfiguration.
class WifiSetupPage extends StatelessWidget {
  const WifiSetupPage({super.key, required this.deviceIp});

  final String deviceIp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wifiSetup)),
      body: Center(child: Text(l10n.wifiSetupPlaceholder)),
    );
  }
}
