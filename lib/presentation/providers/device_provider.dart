import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/device_http_client.dart';
import '../../core/network/udp_discovery.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/stored_device.dart';
import '../../data/models/switch_state.dart';
import '../../data/repositories/device_repository.dart';
import '../../domain/entities/device_entity.dart';

/// Merges persisted devices (Hive) with live UDP discovery into a single
/// observable list of [DeviceEntity].
class DeviceProvider extends ChangeNotifier {
  DeviceProvider({required this._deviceRepo, required this._discoveryStream}) {
    _discoverySub = _discoveryStream.listen(_onDiscovery);
    _refresh();
  }

  final DeviceRepository _deviceRepo;
  final Stream<List<DiscoveredDevice>> _discoveryStream;
  late final StreamSubscription<List<DiscoveredDevice>> _discoverySub;
  final DeviceRemoteDataSource _remote = DeviceRemoteDataSource(
    DeviceHttpClient(),
  );
  final Map<String, bool> _httpReachability = <String, bool>{};
  List<DiscoveredDevice> _lastDiscovered = const [];

  List<DeviceEntity> _devices = [];
  List<DeviceEntity> get devices => _devices;

  /// Devices seen in discovery but not yet added to the DB.
  List<DeviceEntity> _newDevices = [];
  List<DeviceEntity> get newDevices => _newDevices;

  /// Total count of devices currently visible via UDP (including stored).
  int get discoveredCount => _discoveredCount;
  int _discoveredCount = 0;

  /// Whether the discovery stream has emitted at least one event.
  bool get discoveryActive => _discoveryActive;
  bool _discoveryActive = false;

  void _refresh() {
    final stored = _deviceRepo.getAll();
    _devices = stored.map(_toEntity).toList();
    notifyListeners();
  }

  DeviceEntity _toEntity(StoredDevice s) {
    return DeviceEntity(
      mac: s.mac,
      name: s.name,
      type: s.type,
      lastKnownIp: s.lastKnownIp,
      lastSeen: s.lastSeen,
      customName: s.customName,
      room: s.room,
      token: s.token,
      addedAt: s.addedAt,
      colorValue: s.colorValue,
      favorite: s.favorite,
      lockable: s.lockable,
      totalEnergyWs: s.totalEnergyWs,
      bootId: s.bootId,
      bootEnergyWs: s.bootEnergyWs,
      temperatureOffset: s.temperatureOffset,
    );
  }

  void _onDiscovery(List<DiscoveredDevice> discovered) {
    _discoveryActive = true;
    _discoveredCount = discovered.length;
    _lastDiscovered = discovered;

    // Update stored devices with fresh IP/lastSeen.
    for (final d in discovered) {
      final s = _deviceRepo.getByMac(d.mac);
      if (s != null) {
        _deviceRepo.updateDiscoveryInfo(d.mac, d.ip, d.lastSeen);
      }
    }

    _refreshDiscoveryLists(discovered);
    notifyListeners();

    for (final d in discovered) {
      if (!_httpReachability.containsKey(d.mac)) {
        unawaited(_probeHttpReachability(d));
      }
    }
  }

  void _refreshDiscoveryLists(List<DiscoveredDevice> discovered) {
    final stored = _deviceRepo.getAll();
    final storedMacs = stored.map((s) => s.mac).toSet();

    _devices = stored.map((s) {
      final live = discovered.firstWhere(
        (d) => d.mac == s.mac,
        orElse: () => DiscoveredDevice(
          mac: s.mac,
          ip: s.lastKnownIp ?? '',
          type: s.type,
          registered: false,
          cloudConnected: false,
          lastSeen: s.lastSeen ?? DateTime(2000),
        ),
      );
      return DeviceEntity(
        mac: s.mac,
        name: s.name,
        type: s.type,
        lastKnownIp: s.lastKnownIp,
        lastSeen: live.lastSeen,
        customName: s.customName,
        room: s.room,
        token: s.token,
        addedAt: s.addedAt,
        discoveryIp: live.ip,
        registered: live.registered,
        cloudConnected: live.cloudConnected,
        httpReachable: _httpReachability[s.mac] ?? false,
        colorValue: s.colorValue,
        favorite: s.favorite,
        lockable: s.lockable,
        totalEnergyWs: s.totalEnergyWs,
        bootId: s.bootId,
        bootEnergyWs: s.bootEnergyWs,
        temperatureOffset: s.temperatureOffset,
      );
    }).toList();

    _newDevices = discovered
        .where((d) => !storedMacs.contains(d.mac))
        .map(
          (d) => DeviceEntity(
            mac: d.mac,
            name: d.type.displayName,
            type: d.type,
            addedAt: DateTime.now(),
            discoveryIp: d.ip,
            lastSeen: d.lastSeen,
            registered: d.registered,
            cloudConnected: d.cloudConnected,
            httpReachable: _httpReachability[d.mac] ?? false,
          ),
        )
        .toList();
  }

  Future<void> _probeHttpReachability(DiscoveredDevice device) async {
    bool reachable = false;
    try {
      await _remote.getInfo(device.ip);
      reachable = true;
    } catch (_) {
      reachable = false;
    }

    _httpReachability[device.mac] = reachable;
    _refreshDiscoveryLists(_lastDiscovered);
    notifyListeners();
  }

  /// Accumulate energy from a freshly fetched `/report`.
  ///
  /// The device reports `energy_since_boot` (Ws) and a `boot_id`. Across
  /// reboots the per-boot counter resets, so to keep a long-term total we
  /// fold the previous boot's energy into [totalEnergyWs] whenever a new
  /// boot id appears, then store the new boot id + its current energy.
  ///
  /// When `bootId` is null (device does not report it) we only refresh
  /// [bootEnergyWs] and leave the total untouched — there is no reliable
  /// way to detect a reboot in that case.
  Future<void> accumulateEnergy(String mac, SwitchStateModel report) async {
    final s = _deviceRepo.getByMac(mac);
    if (s == null) return;
    final newBootId = report.bootId;
    final newEnergy = report.energySinceBoot ?? 0;
    if (newBootId != null && newBootId != s.bootId) {
      // New boot: fold the previous boot's energy into the total.
      s.totalEnergyWs += s.bootEnergyWs;
      s.bootId = newBootId;
      s.bootEnergyWs = newEnergy;
    } else {
      // Same boot (or no boot id reported): just refresh the per-boot energy.
      s.bootEnergyWs = newEnergy;
      if (newBootId != null && s.bootId == null) {
        s.bootId = newBootId;
      }
    }
    await _deviceRepo.update(s);
    _refresh();
  }

  /// Add a discovered device to the local DB.
  Future<void> addDevice(
    DeviceEntity entity, {
    String? customName,
    int? colorValue,
    bool favorite = false,
  }) async {
    final stored = StoredDevice(
      mac: entity.mac,
      name: entity.name,
      typeCode: entity.type.code,
      lastKnownIp: entity.discoveryIp ?? entity.lastKnownIp,
      lastSeen: entity.lastSeen,
      customName: customName ?? entity.customName,
      addedAt: entity.addedAt,
      room: entity.room,
      token: entity.token,
      colorValue: colorValue ?? entity.colorValue,
      favorite: favorite,
    );
    await _deviceRepo.add(stored);
    _refresh();
  }

  Future<void> removeDevice(String mac) async {
    await _deviceRepo.remove(mac);
    _refresh();
  }

  Future<void> renameDevice(String mac, String name) async {
    final s = _deviceRepo.getByMac(mac);
    if (s == null) return;
    s.customName = name;
    await _deviceRepo.update(s);
    _refresh();
  }

  Future<void> assignRoom(String mac, String room) async {
    final s = _deviceRepo.getByMac(mac);
    if (s == null) return;
    s.room = room;
    await _deviceRepo.update(s);
    _refresh();
  }

  Future<void> setDeviceColor(String mac, int? colorValue) async {
    final s = _deviceRepo.getByMac(mac);
    if (s == null) return;
    s.colorValue = colorValue;
    await _deviceRepo.update(s);
    _refresh();
  }

  Future<void> setFavorite(String mac, bool favorite) async {
    final s = _deviceRepo.getByMac(mac);
    if (s == null) return;
    s.favorite = favorite;
    await _deviceRepo.update(s);
    _refresh();
  }

  Future<void> setLockable(String mac, bool lockable) async {
    final s = _deviceRepo.getByMac(mac);
    if (s == null) return;
    s.lockable = lockable;
    await _deviceRepo.update(s);
    _refresh();
  }

  Future<void> setTemperatureOffset(String mac, double offset) async {
    final s = _deviceRepo.getByMac(mac);
    if (s == null) return;
    s.temperatureOffset = offset;
    await _deviceRepo.update(s);
    _refresh();
  }

  @override
  void dispose() {
    _discoverySub.cancel();
    super.dispose();
  }
}
