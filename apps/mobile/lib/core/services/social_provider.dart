import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants/api_const.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'socket_service.dart';

class SocialState {
  final List<FriendModel> friends;
  final List<FriendModel> incomingRequests;
  final List<FriendModel> outgoingRequests;
  final Set<String> connectedPeerIds;
  final Set<String> pendingActionUserIds;
  final bool isLoading;
  final String? error;

  const SocialState({
    this.friends = const [],
    this.incomingRequests = const [],
    this.outgoingRequests = const [],
    this.connectedPeerIds = const {},
    this.pendingActionUserIds = const {},
    this.isLoading = false,
    this.error,
  });

  SocialState copyWith({
    List<FriendModel>? friends,
    List<FriendModel>? incomingRequests,
    List<FriendModel>? outgoingRequests,
    Set<String>? connectedPeerIds,
    Set<String>? pendingActionUserIds,
    bool? isLoading,
    String? error,
  }) {
    return SocialState(
      friends: friends ?? this.friends,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      outgoingRequests: outgoingRequests ?? this.outgoingRequests,
      connectedPeerIds: connectedPeerIds ?? this.connectedPeerIds,
      pendingActionUserIds: pendingActionUserIds ?? this.pendingActionUserIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isFriend(String userId) => friends.any((f) => f.userId == userId);

  bool hasIncomingRequest(String userId) =>
      incomingRequests.any((r) => r.userId == userId);

  bool hasOutgoingRequest(String userId) =>
      outgoingRequests.any((r) => r.userId == userId);

  bool isDeviceConnected(String userId) => connectedPeerIds.contains(userId);

  NearbyFriendStatus friendStatusFor(String userId) {
    if (isFriend(userId)) return NearbyFriendStatus.accepted;
    if (hasIncomingRequest(userId)) return NearbyFriendStatus.incomingPending;
    if (hasOutgoingRequest(userId)) return NearbyFriendStatus.outgoingPending;
    return NearbyFriendStatus.none;
  }
}

class SocialNotifier extends StateNotifier<SocialState> {
  final Ref _ref;
  StreamSubscription? _friendSub;
  StreamSubscription? _presenceSub;

  SocialNotifier(this._ref) : super(const SocialState()) {
    _subscribeSocketEvents();
  }

  void _subscribeSocketEvents() {
    final socket = _ref.read(socketServiceProvider);

    _friendSub = socket.friendEventStream.listen((event) {
      final type = event['type'] as String? ?? '';
      final fromRaw = event['fromUser'];
      if (fromRaw is! Map) return;
      final fromMap = Map<String, dynamic>.from(fromRaw);
      final fromUserId = fromMap['userId'] as String? ?? '';
      if (fromUserId.isEmpty) return;

      final model = FriendModel(
        userId: fromUserId,
        displayName: fromMap['displayName'] as String? ?? 'Player',
        friendCode: fromMap['friendCode'] as String? ?? '',
        avatarUrl: fromMap['avatarUrl'] as String?,
        status: type == 'request_accepted' ? 'accepted' : 'pending',
        isOnline: true,
      );

      if (type == 'request_received') {
        if (!state.isFriend(fromUserId) &&
            !state.hasIncomingRequest(fromUserId)) {
          state = state.copyWith(
            incomingRequests: [model, ...state.incomingRequests],
          );
        }
      } else if (type == 'request_accepted') {
        final updatedOutgoing = state.outgoingRequests
            .where((r) => r.userId != fromUserId)
            .toList();
        final updatedIncoming = state.incomingRequests
            .where((r) => r.userId != fromUserId)
            .toList();
        final updatedFriends = state.isFriend(fromUserId)
            ? state.friends
            : [model, ...state.friends];
        state = state.copyWith(
          friends: updatedFriends,
          outgoingRequests: updatedOutgoing,
          incomingRequests: updatedIncoming,
        );
      } else if (type == 'request_declined') {
        state = state.copyWith(
          outgoingRequests: state.outgoingRequests
              .where((r) => r.userId != fromUserId)
              .toList(),
        );
      } else if (type == 'friend_removed') {
        state = state.copyWith(
          friends: state.friends.where((f) => f.userId != fromUserId).toList(),
        );
      }
    });

    _presenceSub = socket.presenceUpdateStream.listen((event) {
      final userId = event['userId'] as String? ?? '';
      if (userId.isEmpty) return;
      final status = event['status'] as String? ?? 'offline';
      final gameId = event['gameId'] as String?;
      final isOnline = status != 'offline';

      state = state.copyWith(
        friends: state.friends
            .map((f) => f.userId == userId
                ? f.copyWith(isOnline: isOnline, currentGame: gameId)
                : f)
            .toList(),
      );
    });
  }

  Future<void> fetchFriends({bool showLoading = false}) async {
    final token = _ref.read(authProvider).token;
    if (token == null) return;

    if (showLoading) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConst.friends),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final friends = _dedupe(
          (data['friends'] as List<dynamic>? ?? [])
              .map((f) =>
                  FriendModel.fromJson(Map<String, dynamic>.from(f as Map)))
              .toList(),
        );
        final incoming = _dedupe(
          (data['incomingRequests'] as List<dynamic>? ?? [])
              .map((f) =>
                  FriendModel.fromJson(Map<String, dynamic>.from(f as Map)))
              .toList(),
        );
        final outgoing = _dedupe(
          (data['outgoingRequests'] as List<dynamic>? ?? [])
              .map((f) =>
                  FriendModel.fromJson(Map<String, dynamic>.from(f as Map)))
              .toList(),
        );

        state = state.copyWith(
          friends: friends,
          incomingRequests: incoming,
          outgoingRequests: outgoing,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load friends (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('SocialNotifier.fetchFriends error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Network error while loading friends',
      );
    }
  }

  List<FriendModel> _dedupe(List<FriendModel> items) {
    final seen = <String>{};
    final result = <FriendModel>[];
    for (final item in items) {
      if (item.userId.isNotEmpty && seen.add(item.userId)) {
        result.add(item);
      }
    }
    return result;
  }

  void markDeviceConnected(String userId) {
    if (userId.isEmpty) return;
    if (state.connectedPeerIds.contains(userId)) return;
    state = state.copyWith(
      connectedPeerIds: {...state.connectedPeerIds, userId},
    );
  }

  /// Sends a friend request by userId or friendCode.
  /// Returns `null` on success, or an error message string on failure.
  Future<String?> sendFriendRequest(
    String targetCodeOrId, {
    String? knownUserId,
    String? knownDisplayName,
    String? knownFriendCode,
  }) async {
    final token = _ref.read(authProvider).token;
    if (token == null) return 'Please sign in first.';

    final checkId = knownUserId ?? targetCodeOrId;
    if (state.isFriend(checkId)) {
      return 'Already friends!';
    }
    if (state.hasOutgoingRequest(checkId)) {
      return 'Friend request already sent.';
    }

    final actionKey = knownUserId ?? targetCodeOrId;
    state = state.copyWith(
      pendingActionUserIds: {...state.pendingActionUserIds, actionKey},
    );

    try {
      final response = await http
          .post(
            Uri.parse(ApiConst.friendRequest),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'targetCodeOrId': targetCodeOrId}),
          )
          .timeout(const Duration(seconds: 6));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final targetMap = body['targetUser'] as Map<String, dynamic>?;
        final targetId = targetMap?['userId'] as String? ??
            targetMap?['id'] as String? ??
            knownUserId ??
            '';
        final targetModel = FriendModel(
          userId: targetId,
          displayName: targetMap?['displayName'] as String? ??
              knownDisplayName ??
              'Player',
          friendCode:
              targetMap?['friendCode'] as String? ?? knownFriendCode ?? '',
          avatarUrl: targetMap?['avatarUrl'] as String?,
          status: 'pending',
          isOnline: true,
        );

        final updatedOutgoing =
            targetId.isNotEmpty && !state.hasOutgoingRequest(targetId)
                ? [targetModel, ...state.outgoingRequests]
                : state.outgoingRequests;

        state = state.copyWith(
          outgoingRequests: updatedOutgoing,
          pendingActionUserIds: {...state.pendingActionUserIds}
            ..remove(actionKey),
        );
        return null;
      } else {
        state = state.copyWith(
          pendingActionUserIds: {...state.pendingActionUserIds}
            ..remove(actionKey),
        );
        return body['message']?.toString() ?? 'Failed to send friend request.';
      }
    } catch (e) {
      state = state.copyWith(
        pendingActionUserIds: {...state.pendingActionUserIds}
          ..remove(actionKey),
      );
      return 'Network error while sending request.';
    }
  }

  /// Accepts or declines an incoming friend request.
  Future<String?> respondToRequest(
    FriendModel request, {
    required bool accept,
  }) async {
    final token = _ref.read(authProvider).token;
    if (token == null) return 'Please sign in first.';

    state = state.copyWith(
      pendingActionUserIds: {...state.pendingActionUserIds, request.userId},
    );

    try {
      final response = await http
          .post(
            Uri.parse(ApiConst.friendRespond),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'requesterUserId': request.userId,
              'action': accept ? 'accept' : 'decline',
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final updatedIncoming = state.incomingRequests
            .where((r) => r.userId != request.userId)
            .toList();
        final updatedFriends = accept && !state.isFriend(request.userId)
            ? [
                request.copyWith(status: 'accepted', isOnline: true),
                ...state.friends,
              ]
            : state.friends;

        state = state.copyWith(
          friends: updatedFriends,
          incomingRequests: updatedIncoming,
          pendingActionUserIds: {...state.pendingActionUserIds}
            ..remove(request.userId),
        );
        return null;
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        state = state.copyWith(
          pendingActionUserIds: {...state.pendingActionUserIds}
            ..remove(request.userId),
        );
        return body['message']?.toString() ?? 'Failed to update request.';
      }
    } catch (_) {
      state = state.copyWith(
        pendingActionUserIds: {...state.pendingActionUserIds}
          ..remove(request.userId),
      );
      return 'Network error while updating request.';
    }
  }

  Future<void> removeFriend(String friendId) async {
    final token = _ref.read(authProvider).token;
    if (token == null) return;
    try {
      final response = await http.delete(
        Uri.parse(ApiConst.removeFriend(friendId)),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        state = state.copyWith(
          friends: state.friends.where((f) => f.userId != friendId).toList(),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _friendSub?.cancel();
    _presenceSub?.cancel();
    super.dispose();
  }
}

final socialProvider = StateNotifierProvider<SocialNotifier, SocialState>((ref) {
  ref.watch(authProvider);
  return SocialNotifier(ref);
});
