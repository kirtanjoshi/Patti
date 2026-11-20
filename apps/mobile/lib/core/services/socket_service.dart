import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/user_model.dart';
import 'auth_service.dart';

class RoomInviteNotification {
  final String code;
  final String gameId;
  final int stake;
  final String hostUserId;
  final String hostName;
  final String? hostAvatarUrl;

  const RoomInviteNotification({
    required this.code,
    required this.gameId,
    required this.stake,
    required this.hostUserId,
    required this.hostName,
    this.hostAvatarUrl,
  });

  factory RoomInviteNotification.fromJson(Map<String, dynamic> json) {
    return RoomInviteNotification(
      code: json['code'] as String? ?? '',
      gameId: json['gameId'] as String? ?? 'callbreak',
      stake: (json['stake'] as num?)?.toInt() ?? 0,
      hostUserId: json['hostUserId'] as String? ?? '',
      hostName: json['hostName'] as String? ?? 'Friend',
      hostAvatarUrl: json['hostAvatarUrl'] as String?,
    );
  }
}

class SocketService {
  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  final _roomStateController = StreamController<RoomStateModel>.broadcast();
  final _roomStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _roomInviteController = StreamController<RoomInviteNotification>.broadcast();
  final _tableStateController = StreamController<Map<String, dynamic>>.broadcast();
  final _tableEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _tableTurnController = StreamController<Map<String, dynamic>>.broadcast();
  final _tableResultController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<RoomStateModel> get roomStateStream => _roomStateController.stream;
  Stream<Map<String, dynamic>> get roomStartedStream => _roomStartedController.stream;
  Stream<RoomInviteNotification> get roomInviteStream => _roomInviteController.stream;
  Stream<Map<String, dynamic>> get tableStateStream => _tableStateController.stream;
  Stream<Map<String, dynamic>> get tableEventStream => _tableEventController.stream;
  Stream<Map<String, dynamic>> get tableTurnStream => _tableTurnController.stream;
  Stream<Map<String, dynamic>> get tableResultStream => _tableResultController.stream;
  Stream<String> get errorStream => _errorController.stream;

  void connect(String? token) {
    if (_socket != null && _isConnected) return;

    final url = AuthNotifier.baseUrl;
    _socket = io.io(
      '$url/game',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token ?? ''})
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('Connected to Patii game socket gateway.');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('Disconnected from Patii game socket.');
    });

    _socket!.on('room:state', (data) {
      if (data is Map) {
        _roomStateController.add(
          RoomStateModel.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });

    _socket!.on('room:started', (data) {
      if (data is Map) {
        _roomStartedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('social:room_invite', (data) {
      if (data is Map) {
        _roomInviteController.add(
          RoomInviteNotification.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });

    _socket!.on('table:state', (data) {
      if (data is Map) {
        _tableStateController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('table:event', (data) {
      if (data is Map) {
        _tableEventController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('table:turn', (data) {
      if (data is Map) {
        _tableTurnController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('table:result', (data) {
      if (data is Map) {
        _tableResultController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('error', (data) {
      if (data is Map && data['message'] != null) {
        _errorController.add(data['message'].toString());
      } else if (data is String) {
        _errorController.add(data);
      }
    });

    _socket!.connect();
  }

  void createRoom({
    required String gameId,
    required Map<String, dynamic> rules,
    int stake = 0,
    int seats = 4,
    String botDifficulty = 'medium',
    int turnTimerSeconds = 15,
  }) {
    if (_socket == null || !_isConnected) {
      // Simulate local mock room state for offline/demo
      final mock = RoomStateModel(
        code: 'PAT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        gameId: gameId,
        hostUserId: 'me',
        stake: stake,
        maxSeats: seats,
        turnTimerSeconds: turnTimerSeconds,
        rules: rules,
        participants: [
          const RoomParticipantModel(
            seat: 0,
            userId: 'me',
            displayName: 'You (Host)',
            isHost: true,
          ),
        ],
      );
      _roomStateController.add(mock);
      return;
    }

    _socket!.emit('room:create', {
      'gameId': gameId,
      'rules': rules,
      'stake': stake,
      'seats': seats,
      'botDifficulty': botDifficulty,
      'turnTimerSeconds': turnTimerSeconds,
    });
  }

  void joinRoom(String code) {
    if (_socket == null || !_isConnected) {
      final mock = RoomStateModel(
        code: code.toUpperCase(),
        gameId: 'callbreak',
        hostUserId: 'host_player',
        stake: 0,
        maxSeats: 4,
        participants: [
          const RoomParticipantModel(
            seat: 0,
            userId: 'host_player',
            displayName: 'Host Player',
            isHost: true,
          ),
          const RoomParticipantModel(
            seat: 1,
            userId: 'me',
            displayName: 'You',
            isHost: false,
          ),
        ],
      );
      _roomStateController.add(mock);
      return;
    }

    _socket!.emit('room:join', {'code': code.toUpperCase()});
  }

  void leaveRoom(String code) {
    _socket?.emit('room:leave', {'code': code});
  }

  void addBot(String code, {int? seat, String difficulty = 'medium'}) {
    _socket?.emit('room:addBot', {
      'code': code,
      'seat': seat,
      'difficulty': difficulty,
    });
  }

  void kickPlayer(String code, int seat) {
    _socket?.emit('room:kick', {'code': code, 'seat': seat});
  }

  void startRoom(String code) {
    if (_socket == null || !_isConnected) {
      _roomStartedController.add({
        'code': code,
        'tableId': 'tbl_local_${DateTime.now().millisecondsSinceEpoch}',
        'gameId': 'callbreak',
      });
      return;
    }
    _socket!.emit('room:start', {'code': code});
  }

  void inviteFriendToRoom(String code, String targetUserId) {
    _socket?.emit('room:invite_friend', {
      'code': code,
      'targetUserId': targetUserId,
    });
  }

  void inviteFriend(String targetUserId, {String roomCode = 'PAT777'}) {
    inviteFriendToRoom(roomCode, targetUserId);
  }

  void sendMove(String tableId, int version, Map<String, dynamic> move) {
    _socket?.emit('table:move', {
      'tableId': tableId,
      'version': version,
      'move': move,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _roomStateController.close();
    _roomStartedController.close();
    _roomInviteController.close();
    _tableStateController.close();
    _tableEventController.close();
    _tableTurnController.close();
    _tableResultController.close();
    _errorController.close();
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  final authState = ref.watch(authProvider);

  if (authState.isAuthenticated) {
    service.connect(authState.token);
  }

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
