import 'package:flutter/material.dart';

/// Placeholder WiFi setup page.
///
/// Reuses the provisioning wizard from [AddDevicePage] for a device that
/// is already on the network but needs reconfiguration.
class WifiSetupPage extends StatelessWidget {
  const WifiSetupPage({super.key, required this.deviceIp});

  final String deviceIp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WiFi Setup')),
      body: const Center(
        child: Text('WiFi reconfiguration wizard — see Add Device.'),
      ),
    );
  }
}