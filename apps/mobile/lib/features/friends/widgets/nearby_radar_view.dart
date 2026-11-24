import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/api_const.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/lan_discovery_service.dart';
import '../../../core/services/social_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/toast_banner.dart';
import 'invite_to_room_sheet.dart';
import 'nearby_player_card.dart';
import 'radar_dome_widget.dart';
import 'shake_match_dialog.dart';

/// Visually compelling Sonar Radar Scanner and Nearby Players Discovery
class NearbyRadarView extends ConsumerStatefulWidget {
  const NearbyRadarView({super.key});

  @override
  ConsumerState<NearbyRadarView> createState() => _NearbyRadarViewState();
}

class _NearbyRadarViewState extends ConsumerState<NearbyRadarView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radarAnim;
  final LanDiscoveryService _lanService = LanDiscoveryService();
  StreamSubscription<List<LanPeer>>? _lanSub;
  Timer? _pollTimer;

  bool _isDiscoverable = true;
  bool _isScanning = false;
  double _radiusKm = 5.0;

  List<NearbyPlayerModel> _apiNearbyPlayers = [];
  List<LanPeer> _lanPeers = [];
  NearbyPlayerModel? _selectedPlayer;

  @override
  void initState() {
    super.initState();
    _radarAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _startDiscovery();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _lanSub?.cancel();
    _lanService.dispose();
    _radarAnim.dispose();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      _lanSub = _lanService.peersStream.listen((peers) {
        if (mounted) {
          setState(() => _lanPeers = peers);
        }
      });
      await _lanService.start(user: user, isVisible: _isDiscoverable);
    }

    await _fetchNearbyPlayers();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _isDiscoverable) {
        _fetchNearbyPlayers(silent: true);
      }
    });
  }

  Future<void> _fetchNearbyPlayers({bool silent = false}) async {
    if (!silent) {
      setState(() => _isScanning = true);
    }
    final token = ref.read(authProvider).token;

    try {
      if (token != null) {
        final netInfo = await _lanService.getLocalNetworkInfo();

        // Broadcast location & local Wi-Fi subnet
        await http
            .post(
              Uri.parse(ApiConst.nearbyLocation),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'latitude': 27.7172,
                'longitude': 85.3240,
                'isVisible': _isDiscoverable,
                if (netInfo.ip != null) 'localIp': netInfo.ip,
                if (netInfo.subnet != null) 'localSubnet': netInfo.subnet,
              }),
            )
            .timeout(const Duration(seconds: 4));

        // Query active nearby players
        final res = await http.get(
          ApiConst.nearbyPlayersUri(
            radiusKm: _radiusKm,
            lat: 27.7172,
            lon: 85.3240,
            localIp: netInfo.ip,
            localSubnet: netInfo.subnet,
          ),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as List<dynamic>;
          if (mounted) {
            setState(() {
              _apiNearbyPlayers = data
                  .map((p) => NearbyPlayerModel.fromJson(
                      Map<String, dynamic>.from(p as Map)))
                  .toList();
            });
          }
        }
      }
    } catch (_) {
      // Keep existing LAN-discovered peers even if backend request times out
    } finally {
      if (mounted && !silent) setState(() => _isScanning = false);
    }
  }

  /// Merges backend nearby players + LAN UDP-discovered peers and enriches
  /// each with live friendship & device-connection state from [socialProvider].
  List<NearbyPlayerModel> _mergedPlayers(SocialState social) {
    final byId = <String, NearbyPlayerModel>{};

    for (final p in _apiNearbyPlayers) {
      byId[p.userId] = p;
    }

    for (final lan in _lanPeers) {
      final existing = byId[lan.userId];
      if (existing != null) {
        byId[lan.userId] = existing.copyWith(
          isSameWifi: true,
          distanceMeters: 0,
          distanceText: 'Same Wi-Fi Network',
          isOnline: true,
        );
      } else {
        byId[lan.userId] = lan.toNearbyPlayer();
      }
    }

    final enriched = byId.values.map((p) {
      final socialStatus = social.friendStatusFor(p.userId);
      final effectiveStatus = socialStatus != NearbyFriendStatus.none
          ? socialStatus
          : p.friendStatus;
      final isFriend = effectiveStatus == NearbyFriendStatus.accepted;
      final hasPending =
          effectiveStatus == NearbyFriendStatus.outgoingPending ||
              effectiveStatus == NearbyFriendStatus.incomingPending;
      final isConnected = social.isDeviceConnected(p.userId) || p.isConnected;

      return p.copyWith(
        friendStatus: effectiveStatus,
        isFriend: isFriend,
        hasPendingRequest: hasPending,
        isConnected: isConnected,
      );
    }).toList();

    enriched.sort((a, b) {
      if (a.isSameWifi != b.isSameWifi) return a.isSameWifi ? -1 : 1;
      if (a.isConnected != b.isConnected) return a.isConnected ? -1 : 1;
      return a.distanceMeters.compareTo(b.distanceMeters);
    });

    return enriched;
  }

  Future<void> _toggleDiscoverable(bool value) async {
    setState(() => _isDiscoverable = value);
    HapticFeedback.selectionClick();

    final user = ref.read(authProvider).user;
    if (user != null) {
      if (value) {
        await _lanService.start(user: user, isVisible: true);
        _fetchNearbyPlayers();
      } else {
        await _lanService.stop();
      }
    }

    final token = ref.read(authProvider).token;
    if (token != null) {
      try {
        await http
            .post(
              Uri.parse(ApiConst.nearbyVisibility),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({'isVisible': value}),
            )
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    if (mounted) {
      ToastBanner.show(
        context,
        value
            ? 'You are now visible on the radar'
            : 'Location hidden from radar',
        icon: value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
      );
    }
  }

  Future<void> _sendFriendRequest(NearbyPlayerModel player) async {
    HapticFeedback.lightImpact();
    final target = player.friendCode.isNotEmpty
        ? player.friendCode
        : player.userId;
    final err = await ref.read(socialProvider.notifier).sendFriendRequest(
          target,
          knownUserId: player.userId,
          knownDisplayName: player.displayName,
          knownFriendCode: player.friendCode,
        );

    if (mounted) {
      ToastBanner.show(
        context,
        err ?? 'Friend request sent to ${player.displayName}!',
        icon: err != null
            ? Icons.info_outline_rounded
            : Icons.person_add_rounded,
      );
    }
  }

  Future<void> _respondToRequest(
    NearbyPlayerModel player, {
    required bool accept,
  }) async {
    HapticFeedback.selectionClick();
    final err = await ref.read(socialProvider.notifier).respondToRequest(
          FriendModel(
            userId: player.userId,
            displayName: player.displayName,
            friendCode: player.friendCode,
            avatarUrl: player.avatarUrl,
            status: 'pending',
            isOnline: player.isOnline,
          ),
          accept: accept,
        );
    if (mounted) {
      ToastBanner.show(
        context,
        err ??
            (accept
                ? 'You and ${player.displayName} are now friends!'
                : 'Friend request declined'),
        icon: accept ? Icons.check_circle_rounded : Icons.close_rounded,
      );
    }
  }

  void _inviteToTable(NearbyPlayerModel player) {
    HapticFeedback.lightImpact();
    InviteToRoomHelper.inviteFriend(
      context,
      ref,
      userId: player.userId,
      displayName: player.displayName,
    );
  }

  void _shareInviteLink() {
    final user = ref.read(authProvider).user;
    final code = user?.friendCode ?? 'PATII';
    final shareUrl = ApiConst.friendInviteUrl(code);
    Share.share(
      '🃏 Play Callbreak & Marriage cards with me on Patii! Join my table: $shareUrl (Code: $code)',
      subject: 'Play Patii with me!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialProvider);
    final players = _mergedPlayers(social);

    return Column(
      children: [
        // 1. Interactive Sonar Radar Dome
        RadarDomeWidget(
          animation: _radarAnim,
          radiusKm: _radiusKm,
          players: players,
          selectedPlayer: _selectedPlayer,
          onSelectPlayer: (p) => setState(() => _selectedPlayer = p),
        ),

        // 2. Discoverability & Radius Controls
        _buildControlsCard(),

        // 3. Status Bar
        _buildStatusBar(players.length),

        // 4. Players List or Empty State
        Expanded(
          child: players.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: PatiiColors.gold,
                  backgroundColor: PatiiColors.navySurface,
                  onRefresh: _fetchNearbyPlayers,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: players.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final p = players[idx];
                      final isBusy = social.pendingActionUserIds.contains(p.userId);
                      return NearbyPlayerCard(
                        player: p,
                        isSelected: _selectedPlayer?.userId == p.userId,
                        isBusy: isBusy,
                        onConnect: () => ShakeMatchDialog.show(context),
                        onAddFriend: () => _sendFriendRequest(p),
                        onAcceptRequest: () =>
                            _respondToRequest(p, accept: true),
                        onDeclineRequest: () =>
                            _respondToRequest(p, accept: false),
                        onInvite: () => _inviteToTable(p),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildControlsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: PatiiColors.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatiiColors.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PatiiColors.gold.withValues(alpha: 0.16),
                ),
                child: const Icon(Icons.radar_rounded,
                    color: PatiiColors.gold, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discoverable Nearby',
                      style: PatiiTypography.display(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Allow local card players to discover and invite you',
                      style: PatiiTypography.body(
                          fontSize: 10.5, color: PatiiColors.textMuted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isDiscoverable,
                // ignore: deprecated_member_use
                activeColor: PatiiColors.gold,
                onChanged: _toggleDiscoverable,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Radius: ${_radiusKm.toInt()} km',
                style: PatiiTypography.body(
                    fontSize: 11.5, color: PatiiColors.textSecondary),
              ),
              Row(
                children: [1.0, 5.0, 10.0].map((r) {
                  final isSel = _radiusKm == r;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text('${r.toInt()} km'),
                      selected: isSel,
                      selectedColor: PatiiColors.gold,
                      labelStyle: TextStyle(
                        color: isSel
                            ? PatiiColors.navy
                            : PatiiColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: PatiiColors.navyElevated,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _radiusKm = r);
                          _fetchNearbyPlayers();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(int playerCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: PatiiColors.navyElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PatiiColors.hairline),
      ),
      child: Row(
        children: [
          Icon(
            _isScanning ? Icons.sync_rounded : Icons.my_location_rounded,
            color: PatiiColors.gold,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isScanning
                  ? 'Scanning Wi-Fi & area for card players...'
                  : playerCount == 0
                      ? 'No other players detected within ${_radiusKm.toInt()} km'
                      : '$playerCount card player${playerCount == 1 ? '' : 's'} detected in range',
              style: PatiiTypography.body(
                  fontSize: 11.5, color: PatiiColors.goldLight),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: PatiiColors.gold, size: 18),
            onPressed: _fetchNearbyPlayers,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Rescan',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PatiiColors.gold.withValues(alpha: 0.1),
                  border: Border.all(
                      color: PatiiColors.gold.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.people_outline_rounded,
                    size: 30, color: PatiiColors.gold),
              ),
              const SizedBox(height: 14),
              Text(
                'Be the First in Your Area!',
                style: PatiiTypography.display(
                    fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Your radar is actively broadcasting. Invite friends nearby on WhatsApp or Viber to challenge them!',
                style: PatiiTypography.body(
                    fontSize: 12, color: PatiiColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 42,
                child: Pressable(
                  onPressed: _shareInviteLink,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: PatiiColors.goldButtonGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: PatiiColors.gold.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.share_rounded,
                            size: 16, color: PatiiColors.navy),
                        const SizedBox(width: 8),
                        Text(
                          'Share Invite Link',
                          style: PatiiTypography.body(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: PatiiColors.navy,
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
    );
  }
}
