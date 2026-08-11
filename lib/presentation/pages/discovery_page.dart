import 'package:flutter/material.dart';

/// Placeholder discovery page — shows raw UDP discovery stream.
///
/// In the current architecture the main [DeviceListPage] already merges
/// discovery + stored devices, so this page is a debugging view.
class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discovery')),
      body: const Center(
        child: Text('See device list — discovery runs continuously.'),
      ),
    );
  }
}