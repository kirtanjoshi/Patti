/// User, Friend and Room state models for Patii Mobile client.
class UserAccount {
  final String userId;
  final String displayName;
  final String friendCode;
  final String? avatarUrl;
  final bool isGuest;
  final int coins;
  final int level;
  final int xp;

  const UserAccount({
    required this.userId,
    required this.displayName,
    required this.friendCode,
    this.avatarUrl,
    required this.isGuest,
    this.coins = 10000,
    this.level = 1,
    this.xp = 0,
  });

  UserAccount copyWith({
    String? userId,
    String? displayName,
    String? friendCode,
    String? avatarUrl,
    bool? isGuest,
    int? coins,
    int? level,
    int? xp,
  }) {
    return UserAccount(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      friendCode: friendCode ?? this.friendCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGuest: isGuest ?? this.isGuest,
      coins: coins ?? this.coins,
      level: level ?? this.level,
      xp: xp ?? this.xp,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'friendCode': friendCode,
        'avatarUrl': avatarUrl,
        'isGuest': isGuest,
        'coins': coins,
        'level': level,
        'xp': xp,
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      displayName:
          json['displayName'] as String? ?? json['name'] as String? ?? 'Player',
      friendCode: json['friendCode'] as String? ?? 'PT-NEW',
      avatarUrl: json['avatarUrl'] as String?,
      isGuest: json['isGuest'] as bool? ?? true,
      coins: (json['coins'] as num?)?.toInt() ?? 10000,
      level: (json['level'] as num?)?.toInt() ?? 1,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
    );
  }
}

class FriendModel {
  final String userId;
  final String displayName;
  final String friendCode;
  final String? avatarUrl;
  final String status; // 'pending' | 'accepted'
  final bool isOnline;
  final String? currentGame;

  const FriendModel({
    required this.userId,
    required this.displayName,
    required this.friendCode,
    this.avatarUrl,
    this.status = 'accepted',
    this.isOnline = false,
    this.currentGame,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    final presence = json['presence'] as Map<String, dynamic>?;
    final presenceStatus = presence?['status'] as String?;
    final isOnline = presenceStatus != null
        ? presenceStatus != 'offline'
        : (json['isOnline'] as bool? ?? false);
    final currentGame =
        presence?['gameId'] as String? ?? json['currentGame'] as String?;

    return FriendModel(
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Player',
      friendCode: json['friendCode'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String? ?? 'accepted',
      isOnline: isOnline,
      currentGame: currentGame,
    );
  }

  FriendModel copyWith({
    String? userId,
    String? displayName,
    String? friendCode,
    String? avatarUrl,
    String? status,
    bool? isOnline,
    String? currentGame,
  }) {
    return FriendModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      friendCode: friendCode ?? this.friendCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      currentGame: currentGame ?? this.currentGame,
    );
  }
}

class RoomParticipantModel {
  final int seat;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final bool isHost;
  final bool isBot;
  final String botDifficulty;

  const RoomParticipantModel({
    required this.seat,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.isHost = false,
    this.isBot = false,
    this.botDifficulty = 'medium',
  });

  factory RoomParticipantModel.fromJson(Map<String, dynamic> json) {
    return RoomParticipantModel(
      seat: (json['seat'] as num?)?.toInt() ?? 0,
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ??
          (json['isBot'] == true ? 'Bot' : 'Player'),
      avatarUrl: json['avatarUrl'] as String?,
      isHost: json['isHost'] as bool? ?? false,
      isBot: json['isBot'] as bool? ?? false,
      botDifficulty: json['botDifficulty'] as String? ?? 'medium',
    );
  }
}

class RoomStateModel {
  final String code;
  final String? pin;
  final String gameId;
  final String hostUserId;
  final int stake;
  final int maxSeats;
  final int turnTimerSeconds;
  final Map<String, dynamic> rules;
  final List<RoomParticipantModel> participants;
  final String? tableId;

  const RoomStateModel({
    required this.code,
    this.pin,
    required this.gameId,
    required this.hostUserId,
    this.stake = 0,
    this.maxSeats = 4,
    this.turnTimerSeconds = 15,
    this.rules = const {},
    required this.participants,
    this.tableId,
  });

  factory RoomStateModel.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'] as List<dynamic>? ?? [];
    return RoomStateModel(
      code: json['code'] as String? ?? '',
      pin: json['pin'] as String?,
      gameId: json['gameId'] as String? ?? 'callbreak',
      hostUserId: json['hostUserId'] as String? ?? '',
      stake: (json['stake'] as num?)?.toInt() ?? 0,
      maxSeats: (json['maxSeats'] as num?)?.toInt() ?? 4,
      turnTimerSeconds: (json['turnTimerSeconds'] as num?)?.toInt() ?? 15,
      rules: Map<String, dynamic>.from(json['rules'] as Map? ?? {}),
      participants: rawParticipants
          .map((p) => RoomParticipantModel.fromJson(
              Map<String, dynamic>.from(p as Map)))
          .toList(),
      tableId: json['tableId'] as String?,
    );
  }
}

enum NearbyFriendStatus {
  none,
  outgoingPending,
  incomingPending,
  accepted,
}

class NearbyPlayerModel {
  final String userId;
  final String displayName;
  final String friendCode;
  final String? avatarUrl;
  final int level;
  final int rating;
  final int distanceMeters;
  final String distanceText;
  final bool isOnline;
  final String? currentGame;
  final bool isFriend;
  final bool hasPendingRequest;
  final NearbyFriendStatus friendStatus;
  final bool isSameWifi;
  final bool isConnected;

  const NearbyPlayerModel({
    required this.userId,
    required this.displayName,
    required this.friendCode,
    this.avatarUrl,
    this.level = 1,
    this.rating = 1200,
    required this.distanceMeters,
    required this.distanceText,
    this.isOnline = true,
    this.currentGame,
    this.isFriend = false,
    this.hasPendingRequest = false,
    this.friendStatus = NearbyFriendStatus.none,
    this.isSameWifi = false,
    this.isConnected = false,
  });

  NearbyPlayerModel copyWith({
    String? userId,
    String? displayName,
    String? friendCode,
    String? avatarUrl,
    int? level,
    int? rating,
    int? distanceMeters,
    String? distanceText,
    bool? isOnline,
    String? currentGame,
    bool? isFriend,
    bool? hasPendingRequest,
    NearbyFriendStatus? friendStatus,
    bool? isSameWifi,
    bool? isConnected,
  }) {
    return NearbyPlayerModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      friendCode: friendCode ?? this.friendCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      rating: rating ?? this.rating,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      distanceText: distanceText ?? this.distanceText,
      isOnline: isOnline ?? this.isOnline,
      currentGame: currentGame ?? this.currentGame,
      isFriend: isFriend ?? this.isFriend,
      hasPendingRequest: hasPendingRequest ?? this.hasPendingRequest,
      friendStatus: friendStatus ?? this.friendStatus,
      isSameWifi: isSameWifi ?? this.isSameWifi,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  factory NearbyPlayerModel.fromJson(Map<String, dynamic> json) {
    final presence = json['presence'] as Map<String, dynamic>?;
    final isFriend = json['isFriend'] as bool? ?? false;
    final hasPending = json['hasPendingRequest'] as bool? ?? false;
    final rawStatus = json['friendStatus'] as String?;

    NearbyFriendStatus friendStatus;
    switch (rawStatus) {
      case 'accepted':
        friendStatus = NearbyFriendStatus.accepted;
        break;
      case 'outgoing_pending':
        friendStatus = NearbyFriendStatus.outgoingPending;
        break;
      case 'incoming_pending':
        friendStatus = NearbyFriendStatus.incomingPending;
        break;
      default:
        if (isFriend) {
          friendStatus = NearbyFriendStatus.accepted;
        } else if (hasPending) {
          friendStatus = NearbyFriendStatus.outgoingPending;
        } else {
          friendStatus = NearbyFriendStatus.none;
        }
    }

    return NearbyPlayerModel(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Player',
      friendCode: json['friendCode'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 1,
      rating: (json['rating'] as num?)?.toInt() ?? 1200,
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      distanceText: json['distanceText'] as String? ?? '',
      isOnline: presence != null ? presence['status'] != 'offline' : true,
      currentGame: presence?['gameId'] as String?,
      isFriend: isFriend || friendStatus == NearbyFriendStatus.accepted,
      hasPendingRequest: hasPending ||
          friendStatus == NearbyFriendStatus.outgoingPending ||
          friendStatus == NearbyFriendStatus.incomingPending,
      friendStatus: friendStatus,
      isSameWifi: json['isSameWifi'] as bool? ?? false,
      isConnected: json['isConnected'] as bool? ?? false,
    );
  }
}
