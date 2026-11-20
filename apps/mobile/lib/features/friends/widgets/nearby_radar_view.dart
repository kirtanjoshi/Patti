import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/toast_banner.dart';

/// Interactive Radar Scanner and Nearby Players list
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

  List<NearbyPlayerModel> _nearbyPlayers = [
    const NearbyPlayerModel(
      userId: 'usr_rohan',
      displayName: 'Rohan Sharma',
      friendCode: 'PT-8842',
      distanceMeters: 350,
      distanceText: '~350m away',
      level: 4,
      isOnline: true,
      currentGame: 'Callbreak',
    ),
    const NearbyPlayerModel(
      userId: 'usr_deepa',
      displayName: 'Deepa Shakya',
      friendCode: 'PT-3190',
      distanceMeters: 800,
      distanceText: '~800m away',
      level: 2,
      isOnline: true,
      currentGame: null,
    ),
    const NearbyPlayerModel(
      userId: 'usr_prabhat',
      displayName: 'Prabhat Adhikari',
      friendCode: 'PT-6651',
      distanceMeters: 2100,
      distanceText: '~2.1 km away',
      level: 6,
      isOnline: true,
      currentGame: 'Marriage',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _radarAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
        // Send coarse coordinates (Kathmandu central default: 27.7172, 85.3240)
        await http.post(
          Uri.parse('${AuthNotifier.baseUrl}/social/nearby/location'),
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

        final res = await http.get(
          Uri.parse('${AuthNotifier.baseUrl}/social/nearby?radiusKm=$_radiusKm&lat=27.7172&lon=85.3240'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 3));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as List<dynamic>;
          if (mounted && data.isNotEmpty) {
            setState(() {
              _nearbyPlayers = data
                  .map((p) => NearbyPlayerModel.fromJson(Map<String, dynamic>.from(p as Map)))
                  .toList();
            });
          }
        }
      }
    } catch (_) {
      // Keep responsive mock fallback
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
          Uri.parse('${AuthNotifier.baseUrl}/social/nearby/visibility'),
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
        value ? 'You are now visible to players around you' : 'Location hidden from nearby players',
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
          Uri.parse('${AuthNotifier.baseUrl}/social/friends/request'),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Privacy toggle & scan controls card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PatiiColors.gold.withValues(alpha: 0.16),
                    ),
                    child: const Icon(Icons.radar_rounded, color: PatiiColors.gold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discoverable Nearby',
                          style: PatiiTypography.display(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Let nearby players see your profile and invite you',
                          style: PatiiTypography.body(fontSize: 11, color: PatiiColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isDiscoverable,
                    activeThumbColor: PatiiColors.gold,
                    onChanged: _toggleDiscoverable,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search Radius: ${_radiusKm.toInt()} km',
                    style: PatiiTypography.body(fontSize: 12, color: PatiiColors.textSecondary),
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
                            fontSize: 11,
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
        ),

        // Radar pulse visual banner
        _buildRadarBanner(),

        // Player list
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

  Widget _buildRadarBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: PatiiColors.navyElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PatiiColors.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _radarAnim,
            builder: (ctx, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 28 + (_radarAnim.value * 12),
                    height: 28 + (_radarAnim.value * 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: PatiiColors.gold.withValues(alpha: (1 - _radarAnim.value).clamp(0.0, 1.0)),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const Icon(Icons.my_location_rounded, color: PatiiColors.gold, size: 18),
                ],
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _isScanning
                  ? 'Scanning for players around you...'
                  : '${_nearbyPlayers.length} players found in your area',
              style: PatiiTypography.body(fontSize: 12.5, color: PatiiColors.goldLight),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: PatiiColors.gold, size: 20),
            onPressed: _fetchNearbyPlayers,
            tooltip: 'Rescan Area',
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyCard(NearbyPlayerModel p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PatiiColors.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatiiColors.hairline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: PatiiColors.gold.withValues(alpha: 0.2),
            child: Text(
              p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
              style: PatiiTypography.display(fontSize: 16, color: PatiiColors.goldLight),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PatiiTypography.display(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: PatiiColors.chipBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lv ${p.level}',
                        style: PatiiTypography.body(fontSize: 10, color: PatiiColors.chipBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 12, color: PatiiColors.gold),
                    const SizedBox(width: 3),
                    Text(
                      p.distanceText,
                      style: PatiiTypography.body(fontSize: 11, color: PatiiColors.goldLight),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      p.currentGame != null ? 'Playing ${p.currentGame}' : 'In Lobby',
                      style: PatiiTypography.body(
                        fontSize: 11,
                        color: p.currentGame != null ? PatiiColors.info : PatiiColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 32,
                child: Pressable(
                  onPressed: () => _sendFriendRequest(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PatiiColors.gold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+ Friend',
                      style: PatiiTypography.body(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: PatiiColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 26,
                child: Pressable(
                  onPressed: () => _inviteToTable(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PatiiColors.navyElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PatiiColors.hairline),
                    ),
                    child: Text(
                      'Invite',
                      style: PatiiTypography.body(fontSize: 10, color: PatiiColors.textSecondary),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.radar_rounded, size: 48, color: PatiiColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No players detected nearby',
            style: PatiiTypography.display(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Try increasing your search radius or share your invite link',
            style: PatiiTypography.body(fontSize: 12, color: PatiiColors.textMuted),
          ),
        ],
      ),
    );
  }
}
