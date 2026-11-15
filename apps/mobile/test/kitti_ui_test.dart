import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:patii/features/games/kitti/kitti_evaluator.dart';
import 'package:patii/features/games/kitti/kitti_table_screen.dart';
import 'package:patii_engine/patii_engine.dart';

void main() {
  group('KittiEvaluator Tests', () {
    test('evaluates Trail, Pure Run, Run, Color, Pair, High Card, and 2-3-5', () {
      // Trail
      final trail = [
        const Card(suit: Suit.S, rank: 1, deck: 0, id: 'AS'),
        const Card(suit: Suit.H, rank: 1, deck: 0, id: 'AH'),
        const Card(suit: Suit.D, rank: 1, deck: 0, id: 'AD'),
      ];
      expect(KittiEvaluator.evaluate(trail).category, KittiHandCategory.trail);

      // Pure Run (Straight Flush)
      final pureRun = [
        const Card(suit: Suit.S, rank: 1, deck: 0, id: 'AS'),
        const Card(suit: Suit.S, rank: 13, deck: 0, id: 'KS'),
        const Card(suit: Suit.S, rank: 12, deck: 0, id: 'QS'),
      ];
      expect(KittiEvaluator.evaluate(pureRun).category, KittiHandCategory.pureRun);

      // Run (Straight)
      final run = [
        const Card(suit: Suit.S, rank: 10, deck: 0, id: '10S'),
        const Card(suit: Suit.H, rank: 9, deck: 0, id: '9H'),
        const Card(suit: Suit.D, rank: 8, deck: 0, id: '8D'),
      ];
      expect(KittiEvaluator.evaluate(run).category, KittiHandCategory.run);

      // Color (Flush)
      final color = [
        const Card(suit: Suit.H, rank: 13, deck: 0, id: 'KH'),
        const Card(suit: Suit.H, rank: 9, deck: 0, id: '9H'),
        const Card(suit: Suit.H, rank: 2, deck: 0, id: '2H'),
      ];
      expect(KittiEvaluator.evaluate(color).category, KittiHandCategory.color);

      // Pair
      final pair = [
        const Card(suit: Suit.C, rank: 7, deck: 0, id: '7C'),
        const Card(suit: Suit.D, rank: 7, deck: 0, id: '7D'),
        const Card(suit: Suit.S, rank: 3, deck: 0, id: '3S'),
      ];
      expect(KittiEvaluator.evaluate(pair).category, KittiHandCategory.pair);

      // High Card
      final highCard = [
        const Card(suit: Suit.S, rank: 13, deck: 0, id: 'KS'),
        const Card(suit: Suit.D, rank: 9, deck: 0, id: '9D'),
        const Card(suit: Suit.H, rank: 4, deck: 0, id: '4H'),
      ];
      expect(KittiEvaluator.evaluate(highCard).category, KittiHandCategory.highCard);

      // 2-3-5 of different suits
      final special235 = [
        const Card(suit: Suit.S, rank: 2, deck: 0, id: '2S'),
        const Card(suit: Suit.H, rank: 3, deck: 0, id: '3H'),
        const Card(suit: Suit.D, rank: 5, deck: 0, id: '5D'),
      ];
      expect(KittiEvaluator.evaluate(special235).category, KittiHandCategory.special235);
    });

    test('bestArrangement splits 9 cards into 3 valid hands of 3', () {
      final cards = [
        const Card(suit: Suit.S, rank: 1, deck: 0, id: 'AS'),
        const Card(suit: Suit.H, rank: 1, deck: 0, id: 'AH'),
        const Card(suit: Suit.D, rank: 1, deck: 0, id: 'AD'),
        const Card(suit: Suit.C, rank: 13, deck: 0, id: 'KC'),
        const Card(suit: Suit.C, rank: 12, deck: 0, id: 'QC'),
        const Card(suit: Suit.C, rank: 11, deck: 0, id: 'JC'),
        const Card(suit: Suit.S, rank: 9, deck: 0, id: '9S'),
        const Card(suit: Suit.H, rank: 9, deck: 0, id: '9H'),
        const Card(suit: Suit.D, rank: 4, deck: 0, id: '4D'),
      ];

      final arrangement = KittiEvaluator.bestArrangement(cards);
      expect(arrangement.length, 3);
      expect(arrangement[0].length, 3);
      expect(arrangement[1].length, 3);
      expect(arrangement[2].length, 3);
    });
  });

  group('KittiTableScreen Widget Tests', () {
    testWidgets('renders Kitti table screen with seats, slots, and actions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KittiTableScreen(),
        ),
      );
      await tester.pump();

      // Screen is mounted
      expect(find.byType(KittiTableScreen), findsOneWidget);

      // Opponents and player seats exist
      expect(find.text('Bot 1'), findsOneWidget);
      expect(find.text('Bot 2'), findsOneWidget);
      expect(find.text('Bot 3'), findsOneWidget);

      // Action buttons exist
      expect(find.byIcon(Icons.auto_fix_high), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      // Tap 'Best Arrangement' auto-helper button
      await tester.tap(find.byIcon(Icons.auto_fix_high));
      await tester.pump();

      // Confirm Show button should now be enabled and tapped
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      // Reveal Phase should now be visible
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });
}
