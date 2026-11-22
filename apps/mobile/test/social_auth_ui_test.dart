import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patii/core/widgets/buttons.dart';
import 'package:patii/features/auth/auth_screen.dart';
import 'package:patii/features/auth/google_auth_sheet.dart';
import 'package:patii/features/friends/friends_screen.dart';

void main() {
  group('Social & Auth UI Tests', () {
    testWidgets('AuthScreen renders Google and Guest login options',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(GoldButton), findsOneWidget);
      expect(find.byType(GhostButton), findsOneWidget);
    });

    testWidgets('FriendsScreen renders Share Invite Link and Add Friend input',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FriendsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FriendsScreen), findsOneWidget);
      expect(find.byType(GoldButton), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('GoogleAuthSheet renders modal profile details',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleAuthSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GoogleAuthSheet), findsOneWidget);
    });
  });
}
