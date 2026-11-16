import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:patii_engine/patii_engine.dart' as engine;
import 'package:patii/core/theme/patii_theme.dart';
import 'package:patii/core/widgets/patii_widgets.dart';
import 'package:patii/features/dev/gallery_screen.dart';

void main() {
  group('Design System & Gallery Screen Tests', () {
    testWidgets('Renders PlayingCard in face, back, and court card modes without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: const Scaffold(
            body: Center(
              child: Row(
                children: [
                  PlayingCard(
                    card: engine.Card(suit: engine.Suit.S, rank: 1, deck: 0, id: 'AS'),
                  ),
                  PlayingCard(
                    card: engine.Card(suit: engine.Suit.H, rank: 13, deck: 0, id: 'KH'),
                  ),
                  PlayingCard(
                    card: engine.Card(suit: engine.Suit.S, rank: 1, deck: 0, id: 'BACK'),
                    isFaceDown: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PlayingCard), findsNWidgets(3));
      expect(find.text('A'), findsWidgets);
      expect(find.text('K'), findsWidgets);
    });

    testWidgets('Renders CardHand 13-card fan without overflow', (tester) async {
      final hand = List.generate(
        13,
        (i) => engine.Card(suit: engine.Suit.S, rank: (i % 13) + 1, deck: 0, id: 'card_$i'),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: Scaffold(
            body: SizedBox(
              width: 360, // Small screen width test
              child: CardHand(cards: hand),
            ),
          ),
        ),
      );

      expect(find.byType(CardHand), findsOneWidget);
      expect(find.byType(PlayingCard), findsNWidgets(13));
    });

    testWidgets('Renders PlayerSeat with timer ring, dealer chip and bot badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: const Scaffold(
            body: Center(
              child: PlayerSeat(
                displayName: 'Sita',
                isCurrentTurn: true,
                isDealer: true,
                isBot: true,
                infoPillText: 'Bid 3 · Won 2',
                remainingSeconds: 4, // Urgent crimson timer
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sita'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(find.text('BOT'), findsOneWidget);
      expect(find.text('Bid 3 · Won 2'), findsOneWidget);
    });

    testWidgets('Renders Buttons and CoinCounter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: Scaffold(
            body: Center(
              child: Column(
                children: [
                  const CoinCounter(coins: 15000),
                  GoldButton(label: 'Gold CTA', onPressed: () {}),
                  GhostButton(label: 'Ghost', onPressed: () {}),
                  DangerButton(label: 'Danger', onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('15,000'), findsOneWidget);
      expect(find.text('Gold CTA'), findsOneWidget);
      expect(find.text('Ghost'), findsOneWidget);
      expect(find.text('Danger'), findsOneWidget);
    });

    testWidgets('Renders complete GalleryScreen without errors or overflows', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: const GalleryScreen(),
        ),
      );

      expect(find.byType(GalleryScreen), findsOneWidget);
      expect(find.text('Component Gallery'), findsOneWidget);
      expect(find.text('1. Typography Tokens'), findsOneWidget);
      expect(find.text('3. Buttons (Gold CTA, Ghost, Danger)'), findsOneWidget);
      expect(find.text('4. Playing Cards (States & Styles)'), findsOneWidget);
      expect(find.text('5. Overlapping Card Hand (Callbreak 13-Card Fan)'), findsOneWidget);
      expect(find.text('7. Casino Chips & Stacks'), findsOneWidget);
    });
  });
}
