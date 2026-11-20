import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patii/features/dev/gallery_screen.dart';
import 'package:patii/features/games/callbreak/callbreak_table_screen.dart';
import 'package:patii/features/games/dhumbal/dhumbal_table_screen.dart';
import 'package:patii/features/games/jutpatti/jutpatti_table_screen.dart';
import 'package:patii/features/games/kitti/kitti_table_screen.dart';
import 'package:patii/features/games/marriage/marriage_table_screen.dart';
import 'package:patii/features/games/rummy/rummy_table_screen.dart';
import 'package:patii/features/games/teenpatti/teenpatti_table_screen.dart';
import 'package:patii/features/lobby/casino_lobby_screen.dart';

void main() {
  const landscapeSizes = [
    Size(640, 360),   // Small Android Landscape
    Size(852, 393),   // Standard Phone Landscape
    Size(1024, 600),  // 7-inch Tablet Landscape
  ];

  const portraitSizes = [
    Size(360, 640),   // Small Android Portrait
    Size(393, 852),   // Standard Phone Portrait
    Size(600, 960),   // 7-inch Tablet Portrait
  ];

  group('Lobby Multi-Screen Overflow Audit (Portrait)', () {
    for (final size in portraitSizes) {
      testWidgets('Lobby renders cleanly on ${size.width.toInt()}x${size.height.toInt()} with 0 overflows', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: CasinoLobbyScreen())));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(CasinoLobbyScreen), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 5));
      });
    }
  });

  group('All 7 Card Games Multi-Screen Overflow Audit (Landscape)', () {
    final games = <String, Widget Function()>{
      'Callbreak': () => const CallbreakTableScreen(),
      'Marriage': () => const MarriageTableScreen(),
      'TeenPatti': () => const TeenPattiTableScreen(),
      'Kitti': () => const KittiTableScreen(),
      'Dhumbal': () => const DhumbalTableScreen(),
      'Jutpatti': () => const JutpattiTableScreen(),
      'Rummy': () => const RummyTableScreen(),
      'JokerRummy': () => const RummyTableScreen(isJokerVariant: true),
    };

    for (final entry in games.entries) {
      final name = entry.key;
      final builder = entry.value;

      for (final size in landscapeSizes) {
        testWidgets('$name table renders cleanly on ${size.width.toInt()}x${size.height.toInt()} with 0 overflows', (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(MaterialApp(home: builder()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(find.byType(builder().runtimeType), findsOneWidget);

          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 5));
        });
      }
    }
  });

  group('Gallery Screen Multi-Screen Audit', () {
    testWidgets('Gallery screen renders without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: GalleryScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GalleryScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
