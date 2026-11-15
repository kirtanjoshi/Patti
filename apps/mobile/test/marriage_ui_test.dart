import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:patii_engine/patii_engine.dart';
import 'package:patii/features/games/marriage/marriage_meld_tray.dart';
import 'package:patii/features/games/marriage/marriage_models.dart';
import 'package:patii/features/games/marriage/marriage_table_screen.dart';

void main() {
  group('Marriage Logic Tests', () {
    test('SpecialCardsInfo computes Tiplu, Poplu, Jhiplu, Alter with Ace wrap', () {
      // Cut Joker is Jack of Clubs (11C)
      const cutJoker = Card(suit: Suit.C, rank: 11, deck: 0, id: '11C');
      final info = SpecialCardsInfo.fromMaal(cutJoker);

      expect(info.tiplu.rank, 11);
      expect(info.tiplu.suit, Suit.C);

      // Poplu: Q of Clubs (rank 12)
      expect(info.poplu.rank, 12);
      expect(info.poplu.suit, Suit.C);

      // Jhiplu: 10 of Clubs (rank 10)
      expect(info.jhiplu.rank, 10);
      expect(info.jhiplu.suit, Suit.C);

      // Alter: J of Spades (rank 11, Suit.S)
      expect(info.alter.rank, 11);
      expect(info.alter.suit, Suit.S);
    });

    test('SpecialCardsInfo handles Ace wrap-around correctly', () {
      // Cut Joker is King of Clubs (13C) -> Poplu wraps to Ace (1)
      const kingMaal = Card(suit: Suit.C, rank: 13, deck: 0, id: '13C');
      final kingInfo = SpecialCardsInfo.fromMaal(kingMaal);
      expect(kingInfo.poplu.rank, 1);
      expect(kingInfo.jhiplu.rank, 12);

      // Cut Joker is Ace of Hearts (1H) -> Jhiplu wraps to King (13)
      const aceMaal = Card(suit: Suit.H, rank: 1, deck: 0, id: '1H');
      final aceInfo = SpecialCardsInfo.fromMaal(aceMaal);
      expect(aceInfo.poplu.rank, 2);
      expect(aceInfo.jhiplu.rank, 13);
      expect(aceInfo.alter.suit, Suit.D);
    });

    test('Identifies Pure Sequences, Tunnelas, and Dublees correctly', () {
      // Pure Sequence: 4S, 5S, 6S
      const seq = [
        Card(suit: Suit.S, rank: 4, deck: 0, id: '4S'),
        Card(suit: Suit.S, rank: 5, deck: 0, id: '5S'),
        Card(suit: Suit.S, rank: 6, deck: 0, id: '6S'),
      ];
      expect(MarriageMeldSlot.isPureSequence(seq), isTrue);

      // Tunnela: 7D, 7D, 7D
      const tunnela = [
        Card(suit: Suit.D, rank: 7, deck: 0, id: '7D0'),
        Card(suit: Suit.D, rank: 7, deck: 1, id: '7D1'),
        Card(suit: Suit.D, rank: 7, deck: 2, id: '7D2'),
      ];
      expect(MarriageMeldSlot.isTunnela(tunnela), isTrue);

      // Dublee: 2C, 2C
      const dublee = [
        Card(suit: Suit.C, rank: 2, deck: 0, id: '2C0'),
        Card(suit: Suit.C, rank: 2, deck: 1, id: '2C1'),
      ];
      expect(MarriageMeldSlot.isDublee(dublee), isTrue);
    });

    test('Calculates live Maal points for Marriage set and Alter', () {
      const cutJoker = Card(suit: Suit.C, rank: 11, deck: 0, id: 'JC');
      // Hand with Marriage (10C, 11C, 12C) + Alter (11S)
      const hand = [
        Card(suit: Suit.C, rank: 10, deck: 0, id: '10C'),
        Card(suit: Suit.C, rank: 11, deck: 1, id: '11C_h'),
        Card(suit: Suit.C, rank: 12, deck: 0, id: '12C'),
        Card(suit: Suit.S, rank: 11, deck: 0, id: '11S'),
      ];

      // Marriage set = 10 pts, Alter = 5 pts -> Total 15 pts
      final points = calculateLiveMaalPoints(
        hand: hand,
        maal: cutJoker,
        alterEnabled: true,
      );
      expect(points, 15);
    });
  });

  group('Marriage Widget Tests', () {
    testWidgets('MarriageTableScreen renders table, seats, center piles and hand',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: MarriageTableScreen(),
        ),
      );

      expect(find.byType(MarriageTableScreen), findsOneWidget);
      expect(find.text('Bot 1'), findsOneWidget);
      expect(find.text('Bot 2'), findsOneWidget);
      expect(find.text('Bot 3'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      expect(find.byType(MarriageMeldTray), findsOneWidget);
    });

    testWidgets('Auto Group populates meld slots and allows Seeing Maal',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: MarriageTableScreen(),
        ),
      );

      // Tap Auto Group button in Meld Tray
      final autoGroupBtn = find.byIcon(Icons.auto_fix_high);
      expect(autoGroupBtn, findsOneWidget);
      await tester.tap(autoGroupBtn);
      await tester.pump();

      // Now all 3 pure slots should be valid, enabling "See Maal" button
      final seeMaalBtn = find.widgetWithText(FilledButton, 'marriage.see_maal');
      expect(seeMaalBtn, findsOneWidget);

      // Tap See Maal
      await tester.tap(seeMaalBtn);
      await tester.pump();

      // Maal is now seen: Declare button appears
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });
  });
}
