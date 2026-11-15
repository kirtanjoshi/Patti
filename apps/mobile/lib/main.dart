import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/games/callbreak/callbreak_table_screen.dart';
import 'features/games/marriage/marriage_table_screen.dart';
import 'features/games/teenpatti/teenpatti_table_screen.dart';
import 'features/games/kitti/kitti_table_screen.dart';

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
    // Theme using only ThemeData/ColorScheme tokens with crimson + deep-blue palette
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFC41E3A), // Crimson
        primary: const Color(0xFFC41E3A),
        secondary: const Color(0xFF0F1E36), // Deep Blue
        surface: const Color(0xFFF9FAFB),
        brightness: Brightness.light,
      ),
      fontFamily: 'Mukta',
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return MaterialApp(
      title: 'app_name'.tr(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: theme,
      home: const LobbyPlaceholderScreen(),
    );
  }
}

class LobbyPlaceholderScreen extends StatelessWidget {
  const LobbyPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'lobby.title'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // 8-pt spacing
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'lobby.coins'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        '10,000',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Semantics(
                button: true,
                label: 'lobby.quick_match'.tr(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48.0), // 48x48 min tap target
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CallbreakTableScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.flash_on),
                    label: Text(
                      '${'lobby.quick_match'.tr()}: ${'lobby.games.callbreak'.tr()}',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              Semantics(
                button: true,
                label: 'lobby.games.marriage'.tr(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48.0),
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MarriageTableScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.style),
                    label: Text(
                      '${'lobby.quick_match'.tr()}: ${'lobby.games.marriage'.tr()}',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              Semantics(
                button: true,
                label: 'lobby.games.teenpatti'.tr(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48.0),
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeenPattiTableScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.casino_outlined),
                    label: Text(
                      '${'lobby.quick_match'.tr()}: ${'lobby.games.teenpatti'.tr()}',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              Semantics(
                button: true,
                label: 'lobby.games.kitti'.tr(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48.0),
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const KittiTableScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.grid_view),
                    label: Text(
                      '${'lobby.quick_match'.tr()}: ${'lobby.games.kitti'.tr()}',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
