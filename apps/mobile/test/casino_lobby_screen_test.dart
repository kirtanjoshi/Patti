import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patii/core/theme/patii_theme.dart';
import 'package:patii/features/lobby/casino_lobby_screen.dart';
import 'package:patii/features/lobby/widgets/daily_bonus_banner.dart';
import 'package:patii/features/lobby/widgets/game_card_tile.dart';
import 'package:patii/features/lobby/widgets/lobby_bottom_nav.dart';
import 'package:patii/features/lobby/widgets/lobby_top_bar.dart';

void main() {
  group('Casino Lobby Screen Tests', () {
    testWidgets('Renders complete CasinoLobbyScreen on 393x852 standard phone', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: const CasinoLobbyScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CasinoLobbyScreen), findsOneWidget);
      expect(find.byType(LobbyTopBar), findsOneWidget);
      expect(find.byType(DailyBonusBanner), findsOneWidget);
      expect(find.byType(GameCardTile), findsNWidgets(8));
      expect(find.byType(LobbyBottomNav), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Clean up widget tree to cancel timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Renders CasinoLobbyScreen on 360x640 small screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: const CasinoLobbyScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CasinoLobbyScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Renders CasinoLobbyScreen on 600x960 tablet portrait without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 960));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: const CasinoLobbyScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CasinoLobbyScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Bottom navigation tab selection changes active index', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: const CasinoLobbyScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Leaderboard tab (3rd item)
      final leaderboardTab = find.byIcon(Icons.emoji_events_outlined);
      expect(leaderboardTab, findsOneWidget);

      await tester.tap(leaderboardTab);
      await tester.pump(const Duration(milliseconds: 100));

      // Now active icon should be filled emoji_events
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
