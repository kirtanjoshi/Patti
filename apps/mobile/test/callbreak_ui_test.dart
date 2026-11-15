import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patii/features/games/callbreak/callbreak_table_screen.dart';

void main() {
  testWidgets('CallbreakTableScreen renders seats, round info and bid buttons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CallbreakTableScreen(),
      ),
    );

    expect(find.byType(CallbreakTableScreen), findsOneWidget);
    // Finds seats for players
    expect(find.text('Bot 1'), findsOneWidget);
    expect(find.text('Bot 2'), findsOneWidget);
    expect(find.text('Bot 3'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);

    // Bidding buttons 1 to 8 exist
    expect(find.text('1'), findsWidgets);
    expect(find.text('8'), findsWidgets);
  });
}
