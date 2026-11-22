import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/toast_banner.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthScreen({super.key, this.onAuthSuccess});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _showGuestPrompt() {
    showDialog(
      context: context,
      barrierColor: PatiiColors.scrim,
      builder: (ctx) => AlertDialog(
        backgroundColor: PatiiColors.navyElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: PatiiColors.hairline),
        ),
        title: Row(
          children: [
            const Icon(Icons.person_outline_rounded, color: PatiiColors.gold),
            const SizedBox(width: 8),
            Text(
              'auth.guest_prompt_title'.tr(),
              style: PatiiTypography.display(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: PatiiColors.goldLight,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'auth.guest_prompt_hint'.tr(),
              style: PatiiTypography.body(
                fontSize: 13,
                color: PatiiColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              autofocus: true,
              style: PatiiTypography.body(color: PatiiColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: PatiiColors.navySurface,
                hintText: 'e.g. Biratnagar King',
                hintStyle: PatiiTypography.body(color: PatiiColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: PatiiColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: PatiiColors.gold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'actions.cancel'.tr(),
              style: PatiiTypography.body(color: PatiiColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PatiiColors.gold,
              foregroundColor: PatiiColors.navy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _handleGuestLogin(_nicknameController.text);
            },
            child: Text('actions.play'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGuestLogin([String? name]) async {
    final success = await ref.read(authProvider.notifier).loginGuest(name);
    if (success && mounted) {
      ToastBanner.show(
        context,
        'Logged in as Guest · 10,000 Coins Added!',
        icon: Icons.check_circle_rounded,
      );
      widget.onAuthSuccess?.call();
    }
  }

  Future<void> _handleGoogleLogin() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      ToastBanner.show(
        context,
        'Signed in with Google!',
        icon: Icons.verified_user_rounded,
      );
      widget.onAuthSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: PatiiColors.navy,
      body: Stack(
        children: [
          // Background gradient & soft ambient glow
          const Positioned.fill(
            child: DecoratedBox(
                decoration: BoxDecoration(gradient: PatiiColors.backdrop)),
          ),
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    PatiiColors.crimson.withValues(alpha: 0.35),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    PatiiColors.gold.withValues(alpha: 0.25),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon / Logo
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              PatiiColors.goldLight,
                              PatiiColors.goldDark
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: PatiiColors.gold.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '♠',
                            style: TextStyle(
                              fontSize: 52,
                              color: PatiiColors.navy,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title & Tagline
                      Text(
                        'app_name'.tr(),
                        style: PatiiTypography.display(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: PatiiColors.goldLight,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'auth.welcome_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: PatiiTypography.body(
                          fontSize: 14,
                          color: PatiiColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 48),

                      if (authState.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                              color: PatiiColors.gold),
                        )
                      else ...[
                        // 1. Primary Action: Continue with Google
                        SizedBox(
                          width: double.infinity,
                          child: GoldButton(
                            label: 'auth.continue_google'.tr(),
                            icon: Icons.g_mobiledata_rounded,
                            height: 52,
                            onPressed: _handleGoogleLogin,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. Secondary Action: Play as Guest
                        SizedBox(
                          width: double.infinity,
                          child: GhostButton(
                            label: 'auth.play_guest'.tr(),
                            icon: Icons.person_rounded,
                            height: 50,
                            onPressed: _showGuestPrompt,
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_outlined,
                              size: 14, color: PatiiColors.textMuted),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '10,000 Free Starting Coins · 100% Virtual',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PatiiTypography.body(
                                fontSize: 11.5,
                                color: PatiiColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
