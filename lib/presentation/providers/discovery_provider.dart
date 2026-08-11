import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/udp_discovery.dart';

/// Thin provider exposing the raw discovery stream to the UI.
class DiscoveryProvider extends ChangeNotifier {
  DiscoveryProvider(Stream<List<DiscoveredDevice>> stream) {
    _sub = stream.listen((devices) {
      _devices = devices;
      notifyListeners();
    });
  }

  late final StreamSubscription<List<DiscoveredDevice>> _sub;

  List<DiscoveredDevice> _devices = [];
  List<DiscoveredDevice> get devices => _devices;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
