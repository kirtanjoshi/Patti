import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Discovered peer on the same local Wi-Fi network via UDP broadcast.
class LanPeer {
  final String userId;
  final String displayName;
  final String friendCode;
  final int level;
  final String ipAddress;
  final DateTime lastSeen;

  const LanPeer({
    required this.userId,
    required this.displayName,
    required this.friendCode,
    required this.level,
    required this.ipAddress,
    required this.lastSeen,
  });

  NearbyPlayerModel toNearbyPlayer() {
    return NearbyPlayerModel(
      userId: userId,
      displayName: displayName,
      friendCode: friendCode,
      level: level,
      distanceMeters: 0,
      distanceText: 'Same Wi-Fi Network',
      isOnline: true,
      isSameWifi: true,
    );
  }
}

/// Lightweight LAN / Wi-Fi local-network discovery using UDP broadcasts.
/// Works alongside backend discovery so two devices on the same Wi-Fi
/// reliably see each other even under dual-stack IPv4/IPv6 or NAT.
class LanDiscoveryService {
  static const int _discoveryPort = 41234;
  static const String _magic = 'patii_lan_v1';
  static const Duration _peerTtl = Duration(seconds: 15);

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  final Map<String, LanPeer> _peers = {};
  final _peersController = StreamController<List<LanPeer>>.broadcast();

  String? _cachedLocalIp;
  String? _cachedSubnet;

  Stream<List<LanPeer>> get peersStream => _peersController.stream;
  List<LanPeer> get currentPeers {
    _pruneExpired();
    return _peers.values.toList();
  }

  /// Resolves the device's primary non-loopback IPv4 address and /24 subnet.
  Future<({String? ip, String? subnet})> getLocalNetworkInfo() async {
    if (kIsWeb) return (ip: null, subnet: null);
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (!ip.startsWith('127.') && !ip.startsWith('169.254.')) {
            _cachedLocalIp = ip;
            final parts = ip.split('.');
            if (parts.length == 4) {
              _cachedSubnet = '${parts[0]}.${parts[1]}.${parts[2]}';
            }
            return (ip: _cachedLocalIp, subnet: _cachedSubnet);
          }
        }
      }
    } catch (e) {
      debugPrint('LanDiscoveryService network info error: $e');
    }
    return (ip: _cachedLocalIp, subnet: _cachedSubnet);
  }

  /// Starts listening for UDP beacons and broadcasting this user's presence.
  Future<void> start({
    required UserAccount user,
    required bool isVisible,
  }) async {
    if (kIsWeb) return;
    await stop();
    if (!isVisible) return;

    await getLocalNetworkInfo();

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _discoveryPort,
        reuseAddress: true,
        reusePort: false,
      );
      _socket!.broadcastEnabled = true;

      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram == null) return;
          _handlePacket(datagram, selfUserId: user.userId);
        }
      }, onError: (e) {
        debugPrint('LanDiscoveryService socket error: $e');
      });

      // Broadcast immediately, then periodically every 2.5 seconds
      _sendBeacon(user);
      _broadcastTimer = Timer.periodic(
        const Duration(milliseconds: 2500),
        (_) => _sendBeacon(user),
      );
    } catch (e) {
      debugPrint('LanDiscoveryService bind error: $e');
    }
  }

  void _sendBeacon(UserAccount user) {
    if (_socket == null) return;
    final payload = jsonEncode({
      'magic': _magic,
      'userId': user.userId,
      'displayName': user.displayName,
      'friendCode': user.friendCode,
      'level': user.level,
    });
    final bytes = utf8.encode(payload);

    try {
      _socket!.send(bytes, InternetAddress('255.255.255.255'), _discoveryPort);
    } catch (_) {}

    if (_cachedSubnet != null) {
      try {
        _socket!.send(
          bytes,
          InternetAddress('$_cachedSubnet.255'),
          _discoveryPort,
        );
      } catch (_) {}
    }
  }

  void _handlePacket(Datagram datagram, {required String selfUserId}) {
    try {
      final raw = utf8.decode(datagram.data);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['magic'] != _magic) return;

      final peerId = map['userId'] as String? ?? '';
      if (peerId.isEmpty || peerId == selfUserId) return;

      _peers[peerId] = LanPeer(
        userId: peerId,
        displayName: map['displayName'] as String? ?? 'Nearby Player',
        friendCode: map['friendCode'] as String? ?? '',
        level: (map['level'] as num?)?.toInt() ?? 1,
        ipAddress: datagram.address.address,
        lastSeen: DateTime.now(),
      );

      _pruneExpired();
      if (!_peersController.isClosed) {
        _peersController.add(_peers.values.toList());
      }
    } catch (_) {}
  }

  void _pruneExpired() {
    final cutoff = DateTime.now().subtract(_peerTtl);
    _peers.removeWhere((_, peer) => peer.lastSeen.isBefore(cutoff));
  }

  Future<void> stop() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _socket?.close();
    _socket = null;
  }

  void dispose() {
    stop();
    _peersController.close();
  }
}
