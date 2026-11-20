import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/api_const.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/toast_banner.dart';
import 'radar_dome_widget.dart';

/// Visually compelling Sonar Radar Scanner and Nearby Players Discovery
class NearbyRadarView extends ConsumerStatefulWidget {
  const NearbyRadarView({super.key});

  @override
  ConsumerState<NearbyRadarView> createState() => _NearbyRadarViewState();
}

class _NearbyRadarViewState extends ConsumerState<NearbyRadarView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radarAnim;
  bool _isDiscoverable = true;
  bool _isScanning = false;
  double _radiusKm = 5.0;

  // Real nearby players list loaded from API (empty by default)
  List<NearbyPlayerModel> _nearbyPlayers = [];
  NearbyPlayerModel? _selectedPlayer;

  @override
  void initState() {
    super.initState();
    _radarAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _fetchNearbyPlayers();
  }

  @override
  void dispose() {
    _radarAnim.dispose();
    super.dispose();
  }

  Future<void> _fetchNearbyPlayers() async {
    setState(() => _isScanning = true);
    final token = ref.read(authProvider).token;

    try {
      if (token != null) {
        // Broadcast location (Kathmandu central default: 27.7172, 85.3240)
        await http.post(
          Uri.parse(ApiConst.nearbyLocation),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'latitude': 27.7172,
            'longitude': 85.3240,
            'isVisible': _isDiscoverable,
          }),
        ).timeout(const Duration(seconds: 3));

        // Query active nearby players
        final res = await http.get(
          ApiConst.nearbyPlayersUri(
            radiusKm: _radiusKm,
            lat: 27.7172,
            lon: 85.3240,
          ),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as List<dynamic>;
          if (mounted) {
            setState(() {
              _nearbyPlayers = data
                  .map((p) => NearbyPlayerModel.fromJson(Map<String, dynamic>.from(p as Map)))
                  .toList();
            });
          }
        } else {
          if (mounted) setState(() => _nearbyPlayers = []);
        }
      } else {
        if (mounted) setState(() => _nearbyPlayers = []);
      }
    } catch (_) {
      if (mounted) setState(() => _nearbyPlayers = []);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _toggleDiscoverable(bool value) async {
    setState(() => _isDiscoverable = value);
    HapticFeedback.selectionClick();

    final token = ref.read(authProvider).token;
    if (token != null) {
      try {
        await http.post(
          Uri.parse(ApiConst.nearbyVisibility),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'isVisible': value}),
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    if (mounted) {
      ToastBanner.show(
        context,
        value ? 'You are now visible on the radar' : 'Location hidden from radar',
        icon: value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
      );
    }
  }

  Future<void> _sendFriendRequest(NearbyPlayerModel player) async {
    HapticFeedback.lightImpact();
    final token = ref.read(authProvider).token;

    try {
      if (token != null) {
        await http.post(
          Uri.parse(ApiConst.friendRequest),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'targetCodeOrId': player.friendCode}),
        );
      }
    } catch (_) {}

    if (mounted) {
      ToastBanner.show(
        context,
        'Friend request sent to ${player.displayName}!',
        icon: Icons.person_add_rounded,
      );
    }
  }

  void _inviteToTable(NearbyPlayerModel player) {
    HapticFeedback.lightImpact();
    final socket = ref.read(socketServiceProvider);
    socket.inviteFriend(player.userId);

    ToastBanner.show(
      context,
      'Table invite sent to ${player.displayName}!',
      icon: Icons.casino_rounded,
    );
  }

  void _shareInviteLink() {
    final user = ref.read(authProvider).user;
    final code = user?.friendCode ?? 'PATII';
    final shareUrl = 'https://patii.app/f/$code';
    Share.share(
      '🃏 Play Callbreak & Marriage cards with me on Patii! Join my table: $shareUrl (Code: $code)',
      subject: 'Play Patii with me!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Interactive Sonar Radar Dome
        RadarDomeWidget(
          animation: _radarAnim,
          radiusKm: _radiusKm,
          players: _nearbyPlayers,
          selectedPlayer: _selectedPlayer,
          onSelectPlayer: (p) => setState(() => _selectedPlayer = p),
        ),

        // 2. Discoverability & Radius Controls
        _buildControlsCard(),

        // 3. Status Bar
        _buildStatusBar(),

        // 4. Players List or Empty State
        Expanded(
          child: _nearbyPlayers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: PatiiColors.gold,
                  backgroundColor: PatiiColors.navySurface,
                  onRefresh: _fetchNearbyPlayers,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _nearbyPlayers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) => _buildNearbyCard(_nearbyPlayers[idx]),
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
                child: const Icon(Icons.radar_rounded, color: PatiiColors.gold, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discoverable Nearby',
                      style: PatiiTypography.display(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Allow local card players to discover and invite you',
                      style: PatiiTypography.body(fontSize: 10.5, color: PatiiColors.textMuted),
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
                style: PatiiTypography.body(fontSize: 11.5, color: PatiiColors.textSecondary),
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
                        color: isSel ? PatiiColors.navy : PatiiColors.textSecondary,
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

  Widget _buildStatusBar() {
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
                  ? 'Scanning area for card players...'
                  : _nearbyPlayers.isEmpty
                      ? 'No other players detected within ${_radiusKm.toInt()} km'
                      : '${_nearbyPlayers.length} card players detected in range',
              style: PatiiTypography.body(fontSize: 11.5, color: PatiiColors.goldLight),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: PatiiColors.gold, size: 18),
            onPressed: _fetchNearbyPlayers,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Rescan',
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyCard(NearbyPlayerModel p) {
    final isSel = _selectedPlayer?.userId == p.userId;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSel ? PatiiColors.navyElevated : PatiiColors.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSel ? PatiiColors.gold : PatiiColors.hairline,
          width: isSel ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: PatiiColors.gold.withValues(alpha: 0.2),
            child: Text(
              p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
              style: PatiiTypography.display(fontSize: 15, color: PatiiColors.goldLight),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.displayName,
                        style: PatiiTypography.body(fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: PatiiColors.navyElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Lv ${p.level}',
                        style: PatiiTypography.body(fontSize: 9, color: PatiiColors.gold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.place_rounded, color: PatiiColors.gold, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      p.distanceText,
                      style: PatiiTypography.body(fontSize: 11, color: PatiiColors.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: PatiiColors.hairline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        p.currentGame != null ? 'Playing ${p.currentGame}' : 'In Lobby',
                        style: PatiiTypography.body(
                          fontSize: 11,
                          color: p.currentGame != null ? const Color(0xFF00E5FF) : PatiiColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              SizedBox(
                height: 28,
                child: Pressable(
                  onPressed: () => _sendFriendRequest(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: PatiiColors.goldButtonGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+ Friend',
                      style: PatiiTypography.body(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: PatiiColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 24,
                child: Pressable(
                  onPressed: () => _inviteToTable(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PatiiColors.navyElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: PatiiColors.hairline),
                    ),
                    child: Text(
                      'Invite',
                      style: PatiiTypography.body(fontSize: 9.5, color: PatiiColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
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
                  border: Border.all(color: PatiiColors.gold.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.people_outline_rounded, size: 30, color: PatiiColors.gold),
              ),
              const SizedBox(height: 14),
              Text(
                'Be the First in Your Area!',
                style: PatiiTypography.display(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Your radar is actively broadcasting. Invite friends nearby on WhatsApp or Viber to challenge them!',
                style: PatiiTypography.body(fontSize: 12, color: PatiiColors.textMuted),
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
                        const Icon(Icons.share_rounded, size: 16, color: PatiiColors.navy),
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
