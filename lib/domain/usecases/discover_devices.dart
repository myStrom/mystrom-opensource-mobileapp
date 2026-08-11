import '../../data/repositories/discovery_repository.dart';
import '../../core/network/udp_discovery.dart';

/// Streams discovered devices from the UDP listener.
class DiscoverDevices {
  DiscoverDevices(this._repo);

  final DiscoveryRepository _repo;

  Stream<List<DiscoveredDevice>> call() => _repo.devices;

  List<DiscoveredDevice> snapshot() => _repo.current;
}
