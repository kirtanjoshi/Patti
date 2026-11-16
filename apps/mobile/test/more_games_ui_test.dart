import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:patii/features/games/dhumbal/dhumbal_table_screen.dart';
import 'package:patii/features/games/jutpatti/jutpatti_table_screen.dart';
import 'package:patii/features/games/rummy/rummy_table_screen.dart';

void main() {
  group('Dhumbal Table UI Tests', () {
    testWidgets('renders Dhumbal table without overflow (852x393)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(852, 393));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: DhumbalTableScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DhumbalTableScreen), findsOneWidget);
      expect(find.text('Bot 1'), findsOneWidget);
      expect(find.text('Bot 2'), findsOneWidget);
      expect(find.text('Bot 3'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('renders Dhumbal table without overflow on small landscape (640x360)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(640, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: DhumbalTableScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DhumbalTableScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('Jutpatti Table UI Tests', () {
    testWidgets('renders Jutpatti table without overflow (852x393)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(852, 393));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: JutpattiTableScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(JutpattiTableScreen), findsOneWidget);
      expect(find.text('Bot 1'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('renders Jutpatti table without overflow on small landscape (640x360)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(640, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: JutpattiTableScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(JutpattiTableScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('Rummy Table UI Tests', () {
    testWidgets('renders Classic Rummy table without overflow (852x393)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(852, 393));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: RummyTableScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RummyTableScreen), findsOneWidget);
      expect(find.text('Bot 1'), findsOneWidget);
      expect(find.text('Bot 2'), findsOneWidget);
      expect(find.text('Bot 3'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('renders Joker Rummy variant with Joker indicator without overflow (640x360)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(640, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: RummyTableScreen(isJokerVariant: true)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RummyTableScreen), findsOneWidget);
      expect(find.text('JOKER'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
