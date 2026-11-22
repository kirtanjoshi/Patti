import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:patii_engine/patii_engine.dart';
import 'package:patii/core/theme/patii_theme.dart';
import 'package:patii/core/widgets/buttons.dart';
import 'package:patii/core/widgets/player_seat.dart';
import 'package:patii/core/widgets/table_shell.dart';
import 'package:patii/features/games/teenpatti/teenpatti_evaluator.dart';
import 'package:patii/features/games/teenpatti/teenpatti_table_screen.dart';
import 'package:patii/features/games/teenpatti/widgets/teenpatti_action_bar.dart';
import 'package:patii/features/games/teenpatti/widgets/teenpatti_hand_fan.dart';
import 'package:patii/features/games/teenpatti/widgets/teenpatti_pot_center.dart';

void main() {
  group('TeenPattiEvaluator Tests', () {
    test('evaluates Trail, Pure Sequence, Sequence, Color, Pair, and High Card',
        () {
      // 1. Trail (Three of a Kind)
      final trail = [
        const Card(suit: Suit.S, rank: 1, deck: 0, id: 'AS'),
        const Card(suit: Suit.H, rank: 1, deck: 0, id: 'AH'),
        const Card(suit: Suit.D, rank: 1, deck: 0, id: 'AD'),
      ];
      expect(TeenPattiEvaluator.evaluateScore(trail),
          greaterThanOrEqualTo(600000));

      // 2. Pure Sequence (Straight Flush)
      final pureSeq = [
        const Card(suit: Suit.H, rank: 1, deck: 0, id: 'AH'),
        const Card(suit: Suit.H, rank: 13, deck: 0, id: 'KH'),
        const Card(suit: Suit.H, rank: 12, deck: 0, id: 'QH'),
      ];
      final pureScore = TeenPattiEvaluator.evaluateScore(pureSeq);
      expect(pureScore, greaterThanOrEqualTo(500000));
      expect(pureScore, lessThan(600000));

      // 3. Sequence (Straight)
      final seq = [
        const Card(suit: Suit.S, rank: 10, deck: 0, id: '10S'),
        const Card(suit: Suit.H, rank: 9, deck: 0, id: '9H'),
        const Card(suit: Suit.D, rank: 8, deck: 0, id: '8D'),
      ];
      final seqScore = TeenPattiEvaluator.evaluateScore(seq);
      expect(seqScore, greaterThanOrEqualTo(400000));
      expect(seqScore, lessThan(500000));

      // 4. Color (Flush)
      final color = [
        const Card(suit: Suit.C, rank: 13, deck: 0, id: 'KC'),
        const Card(suit: Suit.C, rank: 9, deck: 0, id: '9C'),
        const Card(suit: Suit.C, rank: 2, deck: 0, id: '2C'),
      ];
      final colorScore = TeenPattiEvaluator.evaluateScore(color);
      expect(colorScore, greaterThanOrEqualTo(300000));
      expect(colorScore, lessThan(400000));

      // 5. Pair
      final pair = [
        const Card(suit: Suit.D, rank: 8, deck: 0, id: '8D'),
        const Card(suit: Suit.C, rank: 8, deck: 0, id: '8C'),
        const Card(suit: Suit.S, rank: 3, deck: 0, id: '3S'),
      ];
      final pairScore = TeenPattiEvaluator.evaluateScore(pair);
      expect(pairScore, greaterThanOrEqualTo(200000));
      expect(pairScore, lessThan(300000));

      // 6. High Card
      final highCard = [
        const Card(suit: Suit.S, rank: 13, deck: 0, id: 'KS'),
        const Card(suit: Suit.H, rank: 7, deck: 0, id: '7H'),
        const Card(suit: Suit.D, rank: 2, deck: 0, id: '2D'),
      ];
      final highScore = TeenPattiEvaluator.evaluateScore(highCard);
      expect(highScore, greaterThanOrEqualTo(100000));
      expect(highScore, lessThan(200000));
    });
  });

  group('TeenPattiActionBar Tests', () {
    testWidgets('renders action buttons and handles taps', (tester) async {
      int betPlaced = 0;
      bool packPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: Scaffold(
            body: Center(
              child: TeenPattiActionBar(
                isMyTurn: true,
                isSeen: false,
                currentStake: 100,
                activePlayerCount: 4,
                canSideShow: false,
                canShow: false,
                onChaal: (amt) => betPlaced = amt,
                onPack: () => packPressed = true,
                onSideShow: () {},
                onShow: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Chaal button is GoldButton
      final chaalFinder = find.byType(GoldButton);
      expect(chaalFinder, findsWidgets);

      await tester.tap(chaalFinder.first);
      expect(betPlaced, 100);

      // Pack button is DangerButton
      final packFinder = find.byType(DangerButton);
      expect(packFinder, findsOneWidget);

      await tester.tap(packFinder);
      expect(packPressed, true);
    });
  });

  group('TeenPattiTableScreen Widget Tests', () {
    testWidgets(
        'renders Teen Patti table on 852x393 landscape without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(852, 393));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: const TeenPattiTableScreen(initialPlayerCount: 5),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Screen mounted
      expect(find.byType(TeenPattiTableScreen), findsOneWidget);
      expect(find.byType(TableShell), findsOneWidget);
      expect(find.byType(TeenPattiPotCenter), findsOneWidget);
      expect(find.byType(TeenPattiHandFan), findsOneWidget);
      expect(find.byType(TeenPattiActionBar), findsOneWidget);

      // 5 Player seats rendered around oval
      expect(find.byType(PlayerSeat), findsNWidgets(5));
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Bot 1'), findsOneWidget);
      expect(find.text('Bot 2'), findsOneWidget);
      expect(find.text('Bot 3'), findsOneWidget);
      expect(find.text('Bot 4'), findsOneWidget);

      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets(
        'renders Teen Patti table on 640x360 compact landscape without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(640, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: const TeenPattiTableScreen(initialPlayerCount: 5),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TeenPattiTableScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('Tap See Cards reveals 3 cards and flips to Seen mode',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(852, 393));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: const TeenPattiTableScreen(initialPlayerCount: 5),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // See Cards button exists in HandFan
      final seeCardsFinder = find.byIcon(Icons.visibility_outlined);
      expect(seeCardsFinder, findsOneWidget);

      await tester.tap(seeCardsFinder);
      await tester.pump(const Duration(milliseconds: 350));

      // Now rank stars icon appears in HandFan
      expect(find.byIcon(Icons.stars), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
