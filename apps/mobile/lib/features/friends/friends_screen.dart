import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/social_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/toast_banner.dart';
import '../room/room_screen.dart';
import 'widgets/friend_share_banner.dart';
import 'widgets/friend_tiles.dart';
import 'widgets/invite_to_room_sheet.dart';
import 'widgets/nearby_radar_view.dart';
import 'widgets/shake_match_dialog.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const FriendsScreen({super.key, this.onBack});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSendingRequest = false;
  int _subTab = 0; // 0: My Friends, 1: Nearby Radar

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(socialProvider.notifier).fetchFriends(showLoading: true);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchFriends() async {
    await ref.read(socialProvider.notifier).fetchFriends();
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

    setState(() => _isSendingRequest = true);
    HapticFeedback.selectionClick();

    final err = await ref.read(socialProvider.notifier).sendFriendRequest(code);
    if (!mounted) return;
    setState(() => _isSendingRequest = false);

    if (err == null) {
      _codeController.clear();
      ToastBanner.show(
        context,
        'friends.request_sent'.tr(),
        icon: Icons.person_add_alt_1_rounded,
      );
    } else {
      ToastBanner.show(
        context,
        err,
        icon: Icons.info_outline_rounded,
      );
    }
  }

  Future<void> _acceptRequest(FriendModel request) async {
    final err = await ref
        .read(socialProvider.notifier)
        .respondToRequest(request, accept: true);
    if (!mounted) return;
    ToastBanner.show(
      context,
      err ?? 'friends.request_accepted'.tr(),
      icon: err != null ? Icons.error_outline_rounded : Icons.check_circle_rounded,
    );
  }

  Future<void> _declineRequest(FriendModel request) async {
    final err = await ref
        .read(socialProvider.notifier)
        .respondToRequest(request, accept: false);
    if (!mounted) return;
    if (err != null) {
      ToastBanner.show(context, err, icon: Icons.error_outline_rounded);
    }
  }

  void _inviteToPlay(FriendModel friend) {
    InviteToRoomHelper.inviteFriend(
      context,
      ref,
      userId: friend.userId,
      displayName: friend.displayName,
    );
  }

  void _openCreateRoom() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RoomScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final social = ref.watch(socialProvider);
    final user = authState.user;
    final friendCode = user?.friendCode ?? 'PT-7777';

    final friends = social.friends;
    final incomingRequests = social.incomingRequests;
    final outgoingRequests = social.outgoingRequests;
    final onlineFriends = friends.where((f) => f.isOnline).toList();
    final offlineFriends = friends.where((f) => !f.isOnline).toList();

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
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: PatiiColors.textPrimary),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.vibration_rounded, color: PatiiColors.gold),
            tooltip: 'Shake to Match',
            onPressed: () => ShakeMatchDialog.show(context),
          ),
          const SizedBox(width: 8),
        ],
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
                        color: _subTab == 0
                            ? PatiiColors.gold
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            size: 16,
                            color: _subTab == 0
                                ? PatiiColors.navy
                                : PatiiColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'My Friends (${friends.length})',
                            style: PatiiTypography.body(
                              fontSize: 12,
                              fontWeight: _subTab == 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _subTab == 0
                                  ? PatiiColors.navy
                                  : PatiiColors.textSecondary,
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
                        color: _subTab == 1
                            ? PatiiColors.gold
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.radar_rounded,
                            size: 16,
                            color: _subTab == 1
                                ? PatiiColors.navy
                                : PatiiColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Nearby Radar',
                            style: PatiiTypography.body(
                              fontSize: 12,
                              fontWeight: _subTab == 1
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _subTab == 1
                                  ? PatiiColors.navy
                                  : PatiiColors.textSecondary,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // 1. Share Invite Link Hero Banner
                  FriendShareBanner(friendCode: friendCode),
                  const SizedBox(height: 12),

                  // 2. Create Room & Shake to Match Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: Pressable(
                          onPressed: _openCreateRoom,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: PatiiColors.navySurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: PatiiColors.info.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color:
                                        PatiiColors.info.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.meeting_room_rounded,
                                      color: PatiiColors.info, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Create Room',
                                        style: PatiiTypography.display(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: PatiiColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Start a table & invite',
                                        style: PatiiTypography.body(
                                          fontSize: 10.5,
                                          color: PatiiColors.textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildShakeMatchBanner(),
                  const SizedBox(height: 16),

                  // 3. Add Friend Card
                  _buildAddFriendCard(),
                  const SizedBox(height: 20),

                  // 4. Incoming Friend Requests
                  if (incomingRequests.isNotEmpty) ...[
                    Text(
                      'friends.pending_requests'.tr(),
                      style: PatiiTypography.display(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: PatiiColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...incomingRequests.map(
                      (req) => PendingFriendRequestTile(
                        request: req,
                        onAccept: () => _acceptRequest(req),
                        onDecline: () => _declineRequest(req),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 5. Outgoing Sent Requests
                  if (outgoingRequests.isNotEmpty) ...[
                    Text(
                      'Sent Requests (${outgoingRequests.length})',
                      style: PatiiTypography.display(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: PatiiColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...outgoingRequests.map(
                      (req) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: PatiiColors.navySurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: PatiiColors.hairline),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: PatiiColors.navyElevated,
                              child: Text(
                                req.displayName.isNotEmpty
                                    ? req.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: PatiiColors.goldLight,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                req.displayName,
                                style: PatiiTypography.body(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: PatiiColors.navyElevated,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Pending',
                                style: PatiiTypography.body(
                                    fontSize: 10.5,
                                    color: PatiiColors.goldLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 4. Online Friends
                  Text(
                    'friends.online_friends'
                        .tr(args: ['${onlineFriends.length}']),
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
                    ...onlineFriends.map(
                      (f) => FriendItemTile(
                        friend: f,
                        onInvite: () => _inviteToPlay(f),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 5. Offline Friends
                  if (offlineFriends.isNotEmpty) ...[
                    Text(
                      'friends.offline_friends'
                          .tr(args: ['${offlineFriends.length}']),
                      style: PatiiTypography.display(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: PatiiColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...offlineFriends.map(
                      (f) => FriendItemTile(
                        friend: f,
                        onInvite: () => _inviteToPlay(f),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildShakeMatchBanner() {
    return Pressable(
      onPressed: () => ShakeMatchDialog.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF28193D), Color(0xFF141F36)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: PatiiColors.gold.withValues(alpha: 0.35),
            width: 1.1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PatiiColors.gold.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.vibration_rounded,
                color: PatiiColors.gold,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shake to Match',
                    style: PatiiTypography.display(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: PatiiColors.goldLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Shake device to instantly match tables with nearby friends',
                    style: PatiiTypography.body(
                      fontSize: 11,
                      color: PatiiColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: PatiiColors.goldButtonGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'SHAKE',
                style: PatiiTypography.body(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: PatiiColors.navy,
                ),
              ),
            ),
          ],
        ),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                hintText: 'friends.enter_friend_code'.tr(),
                hintStyle: PatiiTypography.body(
                    fontSize: 13, color: PatiiColors.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isSendingRequest
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: PatiiColors.gold),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PatiiColors.gold,
                    foregroundColor: PatiiColors.navy,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _sendFriendRequest,
                  child: Text(
                    'friends.add_friend'.tr(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
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
