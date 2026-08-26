import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Placeholder discovery page — shows raw UDP discovery stream.
///
/// In the current architecture the main [DeviceListPage] already merges
/// discovery + stored devices, so this page is a debugging view.
class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.discovery)),
      body: Center(child: Text(l10n.discoveryPlaceholder)),
    );
  }
}
