import '../../core/network/udp_discovery.dart';

/// Wraps the persistent [UdpDiscoveryService] and exposes a stream of
/// discovered devices for the UI.
class DiscoveryRepository {
  DiscoveryRepository(this._service);

  final UdpDiscoveryService _service;

  Stream<List<DiscoveredDevice>> get devices => _service.devices;

  List<DiscoveredDevice> get current => _service.currentDevices;

  Future<void> start() => _service.start();

  void stop() => _service.stop();

  void dispose() => _service.dispose();
}
