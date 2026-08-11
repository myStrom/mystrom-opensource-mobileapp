import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../utils/device_type.dart';

/// A device seen via UDP broadcast.
class DiscoveredDevice {
  final String mac;
  final String ip;
  final DeviceType type;
  final bool registered;
  final bool cloudConnected;
  final DateTime lastSeen;

  const DiscoveredDevice({
    required this.mac,
    required this.ip,
    required this.type,
    required this.registered,
    required this.cloudConnected,
    required this.lastSeen,
  });

  bool get isOffline =>
      DateTime.now().difference(lastSeen) > AppConfig.offlineThreshold;

  DiscoveredDevice copyWith({
    String? mac,
    String? ip,
    DeviceType? type,
    bool? registered,
    bool? cloudConnected,
    DateTime? lastSeen,
  }) {
    return DiscoveredDevice(
      mac: mac ?? this.mac,
      ip: ip ?? this.ip,
      type: type ?? this.type,
      registered: registered ?? this.registered,
      cloudConnected: cloudConnected ?? this.cloudConnected,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

/// Persistent UDP listener on port 7979.
///
/// Parses 13-byte broadcast packets and exposes a stream of discovered
/// devices keyed by MAC address.
class UdpDiscoveryService {
  static const int port = AppConfig.udpDiscoveryPort;
  static const int packetMinSize = AppConfig.udpPacketMinSize;

  RawDatagramSocket? _socket;
  final Map<String, DiscoveredDevice> _devices = {};
  final StreamController<List<DiscoveredDevice>> _controller =
      StreamController<List<DiscoveredDevice>>.broadcast();

  Stream<List<DiscoveredDevice>> get devices => _controller.stream;

  List<DiscoveredDevice> get currentDevices =>
      _devices.values.toList(growable: false);

  Future<void> start() async {
    if (_socket != null) return;
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _socket!.broadcastEnabled = true;
      debugPrint('[UDP] Listening on port $port (${_socket!.address.address})');
      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _socket!.receive();
          if (dg != null) {
            if (dg.data.length >= packetMinSize) {
              _handlePacket(dg.data, dg.address.address);
            } else {
              debugPrint(
                '[UDP] Packet too short: ${dg.data.length} bytes '
                '(need $packetMinSize)',
              );
            }
          }
        } else if (event == RawSocketEvent.closed) {
          debugPrint('[UDP] Socket closed unexpectedly, restarting...');
          _socket = null;
          Future.delayed(const Duration(seconds: 1), start);
        }
      });
    } catch (e) {
      debugPrint('[UDP] Failed to bind on port $port: $e');
      // Retry after a delay — Windows firewall may prompt on first run.
      await Future.delayed(const Duration(seconds: 2));
      await start();
    }
  }

  void _handlePacket(Uint8List data, String ip) {
    final mac = _formatMac(data.sublist(0, 6));
    final typeCode = data[6];
    final flags = data[7];
    final device = DiscoveredDevice(
      mac: mac,
      ip: ip,
      type: DeviceType.fromCode(typeCode),
      registered: (flags & 0x02) != 0,
      cloudConnected: (flags & 0x04) != 0,
      lastSeen: DateTime.now(),
    );
    _devices[mac] = device;
    _controller.add(_devices.values.toList());
  }

  String _formatMac(Uint8List bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  /// Remove devices that haven't been seen recently.
  void pruneStale() {
    final now = DateTime.now();
    _devices.removeWhere(
      (_, d) => now.difference(d.lastSeen) > AppConfig.offlineThreshold * 2,
    );
    _controller.add(_devices.values.toList());
  }

  void stop() {
    _socket?.close();
    _socket = null;
  }

  void dispose() {
    _controller.close();
    stop();
  }
}
