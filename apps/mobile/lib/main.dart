import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/patii_theme.dart';
import 'features/dev/gallery_screen.dart';
import 'features/lobby/casino_lobby_screen.dart';

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

class PatiiApp extends StatelessWidget {
  const PatiiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'app_name'.tr(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: PatiiTheme.casinoDarkTheme,
      routes: {
        '/': (context) => const CasinoLobbyScreen(),
        '/dev/gallery': (context) => const GalleryScreen(),
      },
    );
  }
}
