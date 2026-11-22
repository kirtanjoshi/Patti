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
    return FriendModel(
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Player',
      friendCode: json['friendCode'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String? ?? 'accepted',
      isOnline: json['isOnline'] as bool? ?? false,
      currentGame: json['currentGame'] as String?,
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
  final bool isSameWifi;

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
    this.isSameWifi = false,
  });

  factory NearbyPlayerModel.fromJson(Map<String, dynamic> json) {
    final presence = json['presence'] as Map<String, dynamic>?;
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
      isFriend: json['isFriend'] as bool? ?? false,
      hasPendingRequest: json['hasPendingRequest'] as bool? ?? false,
      isSameWifi: json['isSameWifi'] as bool? ?? false,
    );
  }
}
