import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:patii/features/games/teenpatti/teenpatti_action_bar.dart';
import 'package:patii/features/games/teenpatti/teenpatti_evaluator.dart';
import 'package:patii/features/games/teenpatti/teenpatti_table_screen.dart';
import 'package:patii_engine/patii_engine.dart';

void main() {
  group('TeenPattiEvaluator Tests', () {
    test('evaluates Trail, Pure Sequence, Sequence, Color, Pair, and High Card', () {
      // 1. Trail (Three of a Kind)
      final trail = [
        const Card(suit: Suit.S, rank: 1, deck: 0, id: 'AS'),
        const Card(suit: Suit.H, rank: 1, deck: 0, id: 'AH'),
        const Card(suit: Suit.D, rank: 1, deck: 0, id: 'AD'),
      ];
      expect(TeenPattiEvaluator.evaluateScore(trail), greaterThanOrEqualTo(600000));

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
          home: Scaffold(
            body: TeenPattiActionBar(
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
      );
      await tester.pump();

      // Chaal button for blind is 100 (1x stake)
      final chaalFinder = find.widgetWithText(FilledButton, 'teenpatti.blind 100');
      expect(chaalFinder, findsOneWidget);

      await tester.tap(chaalFinder);
      expect(betPlaced, 100);

      // Pack button
      final packFinder = find.widgetWithText(OutlinedButton, 'teenpatti.pack');
      expect(packFinder, findsOneWidget);

      await tester.tap(packFinder);
      expect(packPressed, true);
    });
  });

  group('TeenPattiTableScreen Widget Tests', () {
    testWidgets('renders Teen Patti table with 5 seats, pot, cards and actions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TeenPattiTableScreen(initialPlayerCount: 5),
        ),
      );
      await tester.pump();

      // Screen mounted
      expect(find.byType(TeenPattiTableScreen), findsOneWidget);

      // Seats are rendered
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Bot 1'), findsOneWidget);
      expect(find.text('Bot 2'), findsOneWidget);
      expect(find.text('Bot 3'), findsOneWidget);
      expect(find.text('Bot 4'), findsOneWidget);

      // "See Cards" toggle exists
      final seeCardsFinder = find.widgetWithText(FilledButton, 'teenpatti.see_cards');
      expect(seeCardsFinder, findsOneWidget);

      // Tap "See Cards" to flip cards to Seen
      await tester.tap(seeCardsFinder);
      await tester.pumpAndSettle();

      // Action bar updates: now Seen, so Chaal is 200 (2x stake)
      expect(find.widgetWithText(FilledButton, 'teenpatti.chaal 200'), findsOneWidget);

      // Tap Chaal 200
      await tester.tap(find.widgetWithText(FilledButton, 'teenpatti.chaal 200'));
      await tester.pump();
    });
  });
}
