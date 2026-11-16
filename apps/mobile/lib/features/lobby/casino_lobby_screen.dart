import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/dhaka_pattern_painter.dart';
import '../../core/widgets/toast_banner.dart';
import '../economy/daily_reward_dialog.dart';
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

/// Premium Casino Lobby Screen for Patii.
/// Locked to portrait orientation with luxury felt/navy aesthetic,
/// animated CoinCounter HUD, Daily Bonus hero banner, 8-game 2-column grid,
/// and dark glass bottom navigation.
class CasinoLobbyScreen extends StatefulWidget {
  const CasinoLobbyScreen({super.key});

  @override
  State<CasinoLobbyScreen> createState() => _CasinoLobbyScreenState();
}

class _CasinoLobbyScreenState extends State<CasinoLobbyScreen> {
  int _coins = 10000;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _lockToPortrait();
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
      ToastBanner.show(context, 'Synced with Patii game servers');
    }
  }

  void _openDailyReward() {
    showDialog(
      context: context,
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
        fannedCardSuits: ['♥', '♦', '♣'],
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
        fannedCardSuits: ['♠', '♠', '♥'],
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

  @override
  Widget build(BuildContext context) {
    final games = _buildGameOptions();

    return Scaffold(
      backgroundColor: PatiiColors.navy,
      body: Stack(
        children: [
          // 1. Faint Dhaka geometric pattern background
          Positioned.fill(
            child: CustomPaint(
              painter: DhakaPatternPainter(
                primaryColor: PatiiColors.gold.withValues(alpha: 0.035),
                secondaryColor: Colors.transparent,
              ),
            ),
          ),

          // 2. Soft radial gold glow behind the header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 0.9,
                  colors: [
                    PatiiColors.gold.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Scrollable Content with Pull-To-Refresh
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
                  // Top Bar HUD
                  SliverToBoxAdapter(
                    child: LobbyTopBar(
                      coins: _coins,
                      vipLevel: 3,
                      username: 'Patii King',
                      onAddCoins: _openDailyReward,
                      onOpenGallery: () {
                        Navigator.pushNamed(context, '/dev/gallery');
                      },
                    ),
                  ),

                  // Daily Bonus Hero Banner
                  SliverToBoxAdapter(
                    child: DailyBonusBanner(
                      onClaim: _openDailyReward,
                    ),
                  ),

                  // Quick Play & Private Room Action Buttons
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PatiiSpacing.s16,
                        vertical: PatiiSpacing.s4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GoldButton(
                              label: 'lobby.quick_match'.tr(),
                              icon: Icons.flash_on,
                              height: 44,
                              onPressed: () => _navigateToGame(
                                const CallbreakTableScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: PatiiSpacing.s8),
                          Expanded(
                            child: GhostButton(
                              label: 'lobby.private_room'.tr(),
                              icon: Icons.meeting_room_outlined,
                              height: 44,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => const RoomScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Section Title: "Casino Games"
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: PatiiSpacing.s16,
                        right: PatiiSpacing.s16,
                        top: PatiiSpacing.s8,
                        bottom: PatiiSpacing.s4,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.stars,
                            color: PatiiColors.gold,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'lobby.all_games'.tr(),
                            style: PatiiTypography.cinzel(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: PatiiColors.goldLight,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    PatiiColors.gold.withValues(alpha: 0.4),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2-Column Games Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PatiiSpacing.s16,
                      vertical: PatiiSpacing.s4,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: PatiiSpacing.s8,
                        mainAxisSpacing: PatiiSpacing.s8,
                        childAspectRatio: 0.95,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final option = games[index];
                          return GameCardTile(
                            option: option,
                            animationDelayMs: index * 300,
                          );
                        },
                        childCount: games.length,
                      ),
                    ),
                  ),

                  // Extra bottom padding to clear the floating bottom navigation bar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 84),
                  ),
                ],
              ),
            ),
          ),

          // 4. Fixed Dark Glass Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LobbyBottomNav(
              currentIndex: _currentTab,
              onTabSelected: (index) {
                setState(() {
                  _currentTab = index;
                });
                if (index == 1) {
                  ToastBanner.show(context, 'Friends list: 4 friends online');
                } else if (index == 2) {
                  ToastBanner.show(
                    context,
                    'Leaderboard: You are ranked #42 in Nepal',
                  );
                } else if (index == 3) {
                  ToastBanner.show(context, 'Profile: VIP Tier 3 · 284 Wins');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
