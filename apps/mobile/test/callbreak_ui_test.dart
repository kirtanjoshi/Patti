import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patii/core/theme/patii_theme.dart';
import 'package:patii/core/widgets/card_hand.dart';
import 'package:patii/core/widgets/player_seat.dart';
import 'package:patii/core/widgets/table_shell.dart';
import 'package:patii/features/games/callbreak/callbreak_table_screen.dart';
import 'package:patii/features/games/callbreak/widgets/callbreak_bid_sheet.dart';
import 'package:patii/features/games/callbreak/widgets/callbreak_trick_area.dart';
import 'package:patii/features/games/callbreak/widgets/opponent_seat_panel.dart';

void main() {
  group('Callbreak Table Screen Landscape Tests', () {
    testWidgets('Renders Callbreak on 852x393 landscape without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(852, 393));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: const CallbreakTableScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CallbreakTableScreen), findsOneWidget);
      expect(find.byType(TableShell), findsOneWidget);
      expect(find.byType(OpponentSeatPanel), findsNWidgets(3));
      expect(find.byType(PlayerSeat), findsNWidgets(4));
      expect(find.byType(CallbreakTrickArea), findsOneWidget);
      expect(find.byType(CallbreakBidSheet), findsOneWidget);
      expect(find.byType(CardHand), findsOneWidget);

      // Finds 4 player names
      expect(find.text('Bot 1'), findsOneWidget);
      expect(find.text('Bot 2'), findsOneWidget);
      expect(find.text('Bot 3'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      // Bidding sheet has 1-8 circular buttons
      expect(find.text('1'), findsWidgets);
      expect(find.text('8'), findsWidgets);

      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets(
        'Renders Callbreak on 640x360 compact landscape without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(640, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: const CallbreakTableScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('Confirming bid switches phase from bidding to playing',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(852, 393));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: PatiiTheme.casinoDarkTheme,
          home: const CallbreakTableScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Bidding sheet exists initially
      expect(find.byType(CallbreakBidSheet), findsOneWidget);

      // Select bid 3
      final bid3Finder = find.widgetWithText(InkWell, '3');
      if (bid3Finder.evaluate().isNotEmpty) {
        await tester.tap(bid3Finder);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Tap Confirm button
      final confirmButtonFinder = find.byIcon(Icons.check);
      expect(confirmButtonFinder, findsOneWidget);
      await tester.tap(confirmButtonFinder);
      await tester.pump(const Duration(milliseconds: 100));

      // Bidding sheet should be dismissed
      expect(find.byType(CallbreakBidSheet), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
