import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/toast_banner.dart';
import '../auth/google_auth_sheet.dart';
import '../changelog/changelog_dialog.dart';
import '../economy/daily_reward_dialog.dart';
import '../friends/friends_screen.dart';
import '../games/callbreak/callbreak_table_screen.dart';
import '../games/dhumbal/dhumbal_table_screen.dart';
import '../games/jutpatti/jutpatti_table_screen.dart';
import '../games/kitti/kitti_table_screen.dart';
import '../games/marriage/marriage_table_screen.dart';
import '../games/rummy/rummy_table_screen.dart';
import '../games/teenpatti/teenpatti_table_screen.dart';
import '../room/room_screen.dart';
import 'widgets/daily_bonus_banner.dart';
import 'widgets/game_card_tile.dart';
import 'widgets/lobby_bottom_nav.dart';
import 'widgets/lobby_top_bar.dart';
import 'widgets/quick_play_hero.dart';

/// Patii lobby (portrait).
///
/// Hierarchy, top to bottom: who I am + coins, ONE big "play now" hero,
/// two quick secondary actions (private room, daily bonus), then every game
/// as an identity-coloured tile. Floating glass navigation at the bottom.
class CasinoLobbyScreen extends ConsumerStatefulWidget {
  const CasinoLobbyScreen({super.key});

  @override
  ConsumerState<CasinoLobbyScreen> createState() => _CasinoLobbyScreenState();
}

class _CasinoLobbyScreenState extends ConsumerState<CasinoLobbyScreen> {
  int _coins = 10000;
  int _currentTab = 0;
  StreamSubscription? _inviteSub;

  @override
  void initState() {
    super.initState();
    _lockToPortrait();
    _subscribeToInvites();
    _checkFirstLaunchChangelog();
  }

  Future<void> _checkFirstLaunchChangelog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('seen_v110_changelog') ?? false;
      if (!seen && mounted) {
        await prefs.setBool('seen_v110_changelog', true);
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) ChangelogDialog.show(context);
        });
      }
    } catch (_) {}
  }

  void _subscribeToInvites() {
    _inviteSub = ref.read(socketServiceProvider).roomInviteStream.listen((invite) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: PatiiColors.navyElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: PatiiColors.gold),
          ),
          title: Row(
            children: [
              const Icon(Icons.mark_chat_unread_rounded, color: PatiiColors.gold),
              const SizedBox(width: 8),
              Text(
                'Table Invite',
                style: PatiiTypography.display(fontSize: 18, color: PatiiColors.goldLight),
              ),
            ],
          ),
          content: Text(
            '${invite.hostName} invited you to play ${invite.gameId.toUpperCase()}! Join room now?',
            style: PatiiTypography.body(color: PatiiColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('actions.cancel'.tr(), style: const TextStyle(color: PatiiColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PatiiColors.gold,
                foregroundColor: PatiiColors.navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RoomScreen(initialCode: invite.code)),
                );
              },
              child: const Text('Join Table', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _inviteSub?.cancel();
    super.dispose();
  }

  void _lockToPortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _coins += 50; // Refresh bonus
      });
      ToastBanner.show(context, 'Synced with Patii game servers', icon: Icons.sync_rounded);
    }
  }

  void _openDailyReward() {
    showDialog(
      context: context,
      barrierColor: PatiiColors.scrim,
      builder: (ctx) => const DailyRewardDialog(),
    ).then((_) {
      if (mounted) {
        setState(() {
          _coins += 500;
        });
        ToastBanner.show(
          context,
          'Daily reward claimed: +500 coins!',
          icon: Icons.stars,
        );
      }
    });
  }

  void _navigateToGame(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      // Re-lock to portrait when returning from landscape tables
      _lockToPortrait();
    });
  }

  List<GameOption> _buildGameOptions() {
    return [
      GameOption(
        id: 'callbreak',
        titleKey: 'lobby.games.callbreak',
        onlineCount: 1420,
        badgeKey: 'lobby.hot',
        fannedCardSuits: ['♠', '♠', '♠'],
        fannedCardRanks: ['A', 'K', 'Q'],
        onTap: () => _navigateToGame(const CallbreakTableScreen()),
      ),
      GameOption(
        id: 'marriage',
        titleKey: 'lobby.games.marriage',
        onlineCount: 1890,
        badgeKey: 'lobby.hot',
        fannedCardSuits: ['♥', '♥', '♥'],
        fannedCardRanks: ['7', '8', '9'],
        onTap: () => _navigateToGame(const MarriageTableScreen()),
      ),
      GameOption(
        id: 'teenpatti',
        titleKey: 'lobby.games.teenpatti',
        onlineCount: 2150,
        badgeKey: 'lobby.hot',
        fannedCardSuits: ['♠', '♥', '♦'],
        fannedCardRanks: ['A', 'A', 'A'],
        onTap: () => _navigateToGame(const TeenPattiTableScreen()),
      ),
      GameOption(
        id: 'kitti',
        titleKey: 'lobby.games.kitti',
        onlineCount: 940,
        badgeKey: 'lobby.popular',
        fannedCardSuits: ['♣', '♦', '♥'],
        fannedCardRanks: ['2', '3', '5'],
        onTap: () => _navigateToGame(const KittiTableScreen()),
      ),
      GameOption(
        id: 'dhumbal',
        titleKey: 'lobby.games.dhumbal',
        onlineCount: 620,
        fannedCardSuits: ['♥', '♠', '♦'],
        fannedCardRanks: ['A', '2', '3'],
        onTap: () => _navigateToGame(const DhumbalTableScreen()),
      ),
      GameOption(
        id: 'jutpatti',
        titleKey: 'lobby.games.jutpatti',
        onlineCount: 510,
        fannedCardSuits: ['♠', '♥', '♣'],
        fannedCardRanks: ['10', '10', 'K'],
        onTap: () => _navigateToGame(const JutpattiTableScreen()),
      ),
      GameOption(
        id: 'rummy',
        titleKey: 'lobby.games.rummy',
        onlineCount: 780,
        fannedCardSuits: ['♦', '♦', '♦'],
        fannedCardRanks: ['J', 'Q', 'K'],
        onTap: () => _navigateToGame(const RummyTableScreen()),
      ),
      GameOption(
        id: 'jokerrummy',
        titleKey: 'lobby.games.jokerrummy',
        onlineCount: 690,
        fannedCardSuits: ['♣', '★', '♣'],
        fannedCardRanks: ['4', 'J', '6'],
        onTap: () => _navigateToGame(const RummyTableScreen(isJokerVariant: true)),
      ),
    ];
  }

  Widget _privateRoomTile() {
    return Semantics(
      button: true,
      label: 'lobby.private_room'.tr(),
      excludeSemantics: true,
      child: Pressable(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => const RoomScreen()),
        ),
        child: Container(
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: PatiiColors.navySurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PatiiColors.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PatiiColors.info.withValues(alpha: 0.16),
                ),
                child: const Icon(Icons.group_add_rounded, color: PatiiColors.info, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lobby.private_room'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PatiiTypography.display(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'lobby.private_room_sub'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PatiiTypography.body(fontSize: 12, color: PatiiColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final games = _buildGameOptions();
    final featured = games.first;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final columns = MediaQuery.sizeOf(context).width >= 560 ? 3 : 2;

    Widget hero = QuickPlayHero(
      gameTitle: featured.titleKey.tr(),
      gameMeta: 'lobby.meta.${featured.id}'.tr(),
      playingNow: featured.onlineCount,
      onPlay: featured.onTap,
    );
    if (!reduceMotion) {
      hero = hero
          .animate()
          .fadeIn(duration: 350.ms)
          .moveY(begin: 12, end: 0, duration: 450.ms, curve: Curves.easeOutCubic);
    }

    return Scaffold(
      backgroundColor: PatiiColors.navy,
      body: Stack(
        children: [
          // Ambient backdrop: ink with a crimson + blue glow behind the header.
          const Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: PatiiColors.backdrop)),
          ),
          Positioned(
            top: -140,
            left: -100,
            child: _Glow(color: PatiiColors.crimson.withValues(alpha: 0.28), size: 380),
          ),
          Positioned(
            top: -80,
            right: -160,
            child: _Glow(color: PatiiColors.chipBlue.withValues(alpha: 0.20), size: 360),
          ),

          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: PatiiColors.gold,
              backgroundColor: PatiiColors.navySurface,
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: LobbyTopBar(
                      coins: ref.watch(authProvider).user?.coins ?? _coins,
                      vipLevel: ref.watch(authProvider).user?.level ?? 3,
                      username: ref.watch(authProvider).user?.displayName ?? 'Patii Player',
                      onAddCoins: _openDailyReward,
                      onAvatarTap: () => GoogleAuthSheet.show(context),
                      onOpenGallery: () => Navigator.pushNamed(context, '/dev/gallery'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    sliver: SliverToBoxAdapter(child: hero),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(child: _privateRoomTile()),
                          const SizedBox(width: 12),
                          Expanded(child: DailyBonusBanner(onClaim: _openDailyReward)),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              'lobby.all_games'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PatiiTypography.display(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'lobby.games_count'.tr(args: ['${games.length}']),
                            style: PatiiTypography.body(fontSize: 12.5, color: PatiiColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.08,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => GameCardTile(
                          option: games[index],
                          animationDelayMs: index * 55,
                        ),
                        childCount: games.length,
                      ),
                    ),
                  ),
                  // Clear the floating navigation bar.
                  const SliverToBoxAdapter(child: SizedBox(height: 104)),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LobbyBottomNav(
              currentIndex: _currentTab,
              onTabSelected: (index) {
                setState(() => _currentTab = index);
                if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FriendsScreen()),
                  );
                } else if (index == 2) {
                  ToastBanner.show(context, 'Leaderboard: You are ranked #42 in Nepal', icon: Icons.emoji_events_rounded);
                } else if (index == 3) {
                  GoogleAuthSheet.show(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft colour blob for the ambient backdrop.
class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
