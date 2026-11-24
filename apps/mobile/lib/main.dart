import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/auth_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/theme/patii_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/dev/gallery_screen.dart';
import 'features/friends/friends_screen.dart';
import 'features/lobby/casino_lobby_screen.dart';
import 'features/room/room_screen.dart';
import 'features/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ne')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: PatiiApp()),
    ),
  );
}

class PatiiApp extends ConsumerStatefulWidget {
  const PatiiApp({super.key});

  @override
  ConsumerState<PatiiApp> createState() => _PatiiAppState();
}

class _PatiiAppState extends ConsumerState<PatiiApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final DeepLinkService _deepLinkService;
  StreamSubscription? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _deepLinkService = DeepLinkService();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    await _deepLinkService.init();
    _deepLinkSub = _deepLinkService.deepLinkStream.listen((data) {
      if (data.hasRoomCode) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => RoomScreen(initialCode: data.roomCode),
          ),
        );
      } else if (data.hasFriendCode) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const FriendsScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'app_name'.tr(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: PatiiTheme.casinoDarkTheme,
      home: authState.isLoading
          ? const Scaffold(
              backgroundColor: PatiiColors.navy,
              body: Center(
                child: CircularProgressIndicator(color: PatiiColors.gold),
              ),
            )
          : authState.isAuthenticated
              ? const CasinoLobbyScreen()
              : const AuthScreen(),
      routes: {
        '/lobby': (context) => const CasinoLobbyScreen(),
        '/dev/gallery': (context) => const GalleryScreen(),
        '/friends': (context) => const FriendsScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
