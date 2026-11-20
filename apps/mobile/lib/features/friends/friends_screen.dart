import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../../core/constants/api_const.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/toast_banner.dart';
import 'widgets/nearby_radar_view.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const FriendsScreen({super.key, this.onBack});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  int _subTab = 0; // 0: My Friends, 1: Nearby Radar

  // Local list of friends for responsive UI
  List<FriendModel> _friends = [
    const FriendModel(
      userId: 'usr_saroj',
      displayName: 'Saroj Shrestha',
      friendCode: 'PT-9941',
      isOnline: true,
      currentGame: 'Callbreak',
    ),
    const FriendModel(
      userId: 'usr_anita',
      displayName: 'Anita Gurung',
      friendCode: 'PT-1284',
      isOnline: true,
      currentGame: null,
    ),
    const FriendModel(
      userId: 'usr_bipin',
      displayName: 'Bipin Thapa',
      friendCode: 'PT-7723',
      isOnline: false,
    ),
  ];

  final List<FriendModel> _pendingRequests = [
    const FriendModel(
      userId: 'usr_kiran',
      displayName: 'Kiran KC',
      friendCode: 'PT-5512',
      status: 'pending',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchFriends() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConst.friends),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawFriends = data['friends'] as List<dynamic>? ?? [];
        if (mounted && rawFriends.isNotEmpty) {
          setState(() {
            _friends = rawFriends
                .map((f) => FriendModel.fromJson(Map<String, dynamic>.from(f as Map)))
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  void _shareInviteLink(String friendCode) {
    HapticFeedback.lightImpact();
    final link = 'https://patii.app/f/$friendCode';
    Share.share(
      'friends.share_text'.tr(args: [link, friendCode]),
      subject: 'Join me on Patii Card Games!',
    );
  }

  Future<void> _sendFriendRequest() async {
    final rawInput = _codeController.text.trim();
    if (rawInput.isEmpty) return;

    // Support extracting friend code if a full URL was pasted
    String code = rawInput;
    if (code.contains('/f/')) {
      code = code.split('/f/').last;
    } else if (code.contains('friend/')) {
      code = code.split('friend/').last;
    }

    setState(() => _isLoading = true);
    HapticFeedback.selectionClick();

    // Optimistic addition
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _codeController.clear();
      setState(() => _isLoading = false);
      ToastBanner.show(
        context,
        'friends.request_sent'.tr(),
        icon: Icons.person_add_alt_1_rounded,
      );
    }
  }

  void _acceptRequest(FriendModel request) {
    setState(() {
      _pendingRequests.removeWhere((r) => r.userId == request.userId);
      _friends.insert(
        0,
        FriendModel(
          userId: request.userId,
          displayName: request.displayName,
          friendCode: request.friendCode,
          isOnline: true,
        ),
      );
    });
    ToastBanner.show(
      context,
      'friends.request_accepted'.tr(),
      icon: Icons.check_circle_rounded,
    );
  }

  void _declineRequest(FriendModel request) {
    setState(() {
      _pendingRequests.removeWhere((r) => r.userId == request.userId);
    });
  }

  void _inviteToPlay(FriendModel friend) {
    final socket = ref.read(socketServiceProvider);
    socket.inviteFriendToRoom('PAT777', friend.userId);
    ToastBanner.show(
      context,
      'Invited ${friend.displayName} to play!',
      icon: Icons.send_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final friendCode = user?.friendCode ?? 'PT-7777';

    final onlineFriends = _friends.where((f) => f.isOnline).toList();
    final offlineFriends = _friends.where((f) => !f.isOnline).toList();

    return Scaffold(
      backgroundColor: PatiiColors.navy,
      appBar: AppBar(
        backgroundColor: PatiiColors.navyElevated,
        elevation: 0,
        title: Text(
          'friends.title'.tr(),
          style: PatiiTypography.display(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: PatiiColors.goldLight,
          ),
        ),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PatiiColors.textPrimary),
                onPressed: widget.onBack,
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: PatiiColors.navySurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PatiiColors.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Pressable(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _subTab = 0);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _subTab == 0 ? PatiiColors.gold : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            size: 16,
                            color: _subTab == 0 ? PatiiColors.navy : PatiiColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'My Friends (${_friends.length})',
                            style: PatiiTypography.body(
                              fontSize: 12,
                              fontWeight: _subTab == 0 ? FontWeight.bold : FontWeight.w500,
                              color: _subTab == 0 ? PatiiColors.navy : PatiiColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Pressable(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _subTab = 1);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _subTab == 1 ? PatiiColors.gold : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.radar_rounded,
                            size: 16,
                            color: _subTab == 1 ? PatiiColors.navy : PatiiColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Nearby Radar',
                            style: PatiiTypography.body(
                              fontSize: 12,
                              fontWeight: _subTab == 1 ? FontWeight.bold : FontWeight.w500,
                              color: _subTab == 1 ? PatiiColors.navy : PatiiColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _subTab == 1
          ? const NearbyRadarView()
          : RefreshIndicator(
        color: PatiiColors.gold,
        backgroundColor: PatiiColors.navySurface,
        onRefresh: _fetchFriends,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // 1. Share Invite Link Hero Banner
            _buildShareBanner(friendCode),
            const SizedBox(height: 16),

            // 2. Add Friend Card
            _buildAddFriendCard(),
            const SizedBox(height: 20),

            // 3. Pending Requests
            if (_pendingRequests.isNotEmpty) ...[
              Text(
                'friends.pending_requests'.tr(),
                style: PatiiTypography.display(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: PatiiColors.goldLight,
                ),
              ),
              const SizedBox(height: 10),
              ..._pendingRequests.map(_buildPendingRequestTile),
              const SizedBox(height: 20),
            ],

            // 4. Online Friends
            Text(
              'friends.online_friends'.tr(args: ['${onlineFriends.length}']),
              style: PatiiTypography.display(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: PatiiColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (onlineFriends.isEmpty)
              _buildEmptyPlaceholder()
            else
              ...onlineFriends.map(_buildFriendTile),

            const SizedBox(height: 24),

            // 5. Offline Friends
            if (offlineFriends.isNotEmpty) ...[
              Text(
                'friends.offline_friends'.tr(args: ['${offlineFriends.length}']),
                style: PatiiTypography.display(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: PatiiColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              ...offlineFriends.map(_buildFriendTile),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildShareBanner(String friendCode) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B1D38), Color(0xFF161C2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PatiiColors.gold.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: PatiiColors.crimson.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PatiiColors.gold.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_rounded, color: PatiiColors.gold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'friends.share_link_title'.tr(),
                      style: PatiiTypography.display(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: PatiiColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'friends.share_link_subtitle'.tr(),
                      style: PatiiTypography.body(
                        fontSize: 12,
                        color: PatiiColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GoldButton(
            label: 'friends.share_link_button'.tr(),
            icon: Icons.link_rounded,
            height: 44,
            onPressed: () => _shareInviteLink(friendCode),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFriendCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PatiiColors.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatiiColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              style: PatiiTypography.body(color: PatiiColors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                hintText: 'friends.enter_friend_code'.tr(),
                hintStyle: PatiiTypography.body(fontSize: 13, color: PatiiColors.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: PatiiColors.gold),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PatiiColors.gold,
                    foregroundColor: PatiiColors.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _sendFriendRequest,
                  child: Text(
                    'friends.add_friend'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestTile(FriendModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PatiiColors.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatiiColors.hairline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: PatiiColors.gold.withValues(alpha: 0.15),
            child: Text(
              request.displayName[0],
              style: const TextStyle(color: PatiiColors.goldLight, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.displayName,
                  style: PatiiTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PatiiColors.textPrimary,
                  ),
                ),
                Text(
                  request.friendCode,
                  style: PatiiTypography.body(fontSize: 11, color: PatiiColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: PatiiColors.success, size: 28),
            onPressed: () => _acceptRequest(request),
            tooltip: 'friends.accept'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: PatiiColors.textMuted, size: 28),
            onPressed: () => _declineRequest(request),
            tooltip: 'friends.decline'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(FriendModel friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: PatiiColors.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatiiColors.hairline),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: PatiiColors.navyElevated,
                child: Text(
                  friend.displayName[0],
                  style: const TextStyle(color: PatiiColors.textPrimary, fontWeight: FontWeight.bold),
                ),
              ),
              if (friend.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: PatiiColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: PatiiColors.navySurface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PatiiTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PatiiColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  friend.currentGame != null
                      ? 'friends.status_in_game'.tr(args: [friend.currentGame!])
                      : friend.isOnline
                          ? 'friends.status_online'.tr()
                          : 'friends.status_offline'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PatiiTypography.body(
                    fontSize: 11.5,
                    color: friend.isOnline ? PatiiColors.success : PatiiColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (friend.isOnline) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _inviteToPlay(friend),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: PatiiColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PatiiColors.info.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'friends.invite_to_play'.tr(),
                  style: const TextStyle(
                    color: PatiiColors.info,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(
        'friends.no_friends'.tr(),
        textAlign: TextAlign.center,
        style: PatiiTypography.body(fontSize: 13, color: PatiiColors.textMuted),
      ),
    );
  }
}
