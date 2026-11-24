import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/social_provider.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/toast_banner.dart';
import '../../room/room_screen.dart';

/// Modal dialog for 'Shake to Match' near-field player discovery.
/// Features animated shaking phone visual, expanding sonar ripples,
/// and live socket matching via [socketServiceProvider].
class ShakeMatchDialog extends ConsumerStatefulWidget {
  final String gameId;

  const ShakeMatchDialog({
    super.key,
    this.gameId = 'callbreak',
  });

  static Future<void> show(
    BuildContext context, {
    String gameId = 'callbreak',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: PatiiColors.scrim,
      builder: (_) => ShakeMatchDialog(gameId: gameId),
    );
  }

  @override
  ConsumerState<ShakeMatchDialog> createState() => _ShakeMatchDialogState();
}

class _ShakeMatchDialogState extends ConsumerState<ShakeMatchDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  StreamSubscription? _shakeSubscription;
  StreamSubscription? _timeoutSubscription;
  bool _isSearching = false;
  bool _isMatched = false;
  bool _timedOut = false;
  String? _matchedRoomCode;
  String? _matchedPlayerName;
  String? _matchedUserId;
  String? _matchedFriendCode;
  bool _isSendingFriendRequest = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _listenToShakeEvents();
    // Automatically trigger initial shake search on dialog open
    _triggerShakeSearch();
  }

  void _listenToShakeEvents() {
    final socketService = ref.read(socketServiceProvider);
    _shakeSubscription = socketService.shakeMatchedStream.listen((data) {
      if (!mounted) return;
      final code = data['code'] as String? ?? 'PAT777';
      final matchedUser = data['matchedUser'] is Map
          ? Map<String, dynamic>.from(data['matchedUser'] as Map)
          : null;
      final peerUserId = matchedUser?['userId'] as String?;
      final friendCode = matchedUser?['friendCode'] as String?;
      final friendName = matchedUser?['displayName'] as String? ??
          data['matchedWith'] as String? ??
          'Nearby Card Player';

      if (peerUserId != null && peerUserId.isNotEmpty) {
        ref.read(socialProvider.notifier).markDeviceConnected(peerUserId);
      }

      HapticFeedback.heavyImpact();
      setState(() {
        _isSearching = false;
        _isMatched = true;
        _timedOut = false;
        _matchedRoomCode = code;
        _matchedPlayerName = friendName;
        _matchedUserId = peerUserId;
        _matchedFriendCode = friendCode;
      });
    });

    _timeoutSubscription = socketService.shakeTimeoutStream.listen((_) {
      if (!mounted || _isMatched) return;
      setState(() {
        _isSearching = false;
        _timedOut = true;
      });
    });
  }

  void _triggerShakeSearch() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSearching = true;
      _isMatched = false;
      _timedOut = false;
    });
    ref.read(socketServiceProvider).shakeToMatch(widget.gameId);
  }

  Future<void> _sendFriendRequest() async {
    final target = _matchedFriendCode?.isNotEmpty == true
        ? _matchedFriendCode!
        : (_matchedUserId ?? '');
    if (target.isEmpty) return;

    setState(() => _isSendingFriendRequest = true);
    final err = await ref.read(socialProvider.notifier).sendFriendRequest(
          target,
          knownUserId: _matchedUserId,
          knownDisplayName: _matchedPlayerName,
          knownFriendCode: _matchedFriendCode,
        );
    if (!mounted) return;
    setState(() => _isSendingFriendRequest = false);

    ToastBanner.show(
      context,
      err ?? 'Friend request sent to ${_matchedPlayerName ?? 'player'}!',
      icon: err != null ? Icons.info_outline_rounded : Icons.person_add_rounded,
    );
  }

  void _enterMatchedRoom() {
    final code = _matchedRoomCode;
    Navigator.of(context, rootNavigator: true).pop();
    if (code != null && code.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoomScreen(initialCode: code),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeSubscription?.cancel();
    _timeoutSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        decoration: BoxDecoration(
          color: PatiiColors.navyElevated,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _isMatched
                ? const Color(0xFF00E676)
                : PatiiColors.gold.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (_isMatched ? const Color(0xFF00E676) : PatiiColors.gold)
                  .withValues(alpha: 0.25),
              blurRadius: 28,
              spreadRadius: 4,
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: PatiiColors.gold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.screen_rotation_rounded,
                        color: PatiiColors.gold,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SHAKE TO MATCH',
                      style: PatiiTypography.display(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: PatiiColors.goldLight,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: PatiiColors.textMuted, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sonar Pulse Ring Animation with Phone Icon
            SizedBox(
              height: 170,
              width: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sonar Ripples
                  if (_isSearching && !_isMatched) ...[
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(170, 170),
                          painter: _SonarRipplePainter(
                            progress: _pulseController.value,
                            color: PatiiColors.gold,
                          ),
                        );
                      },
                    ),
                  ],

                  // Matched Green Glow Rings
                  if (_isMatched) ...[
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00E676).withValues(alpha: 0.15),
                        border: Border.all(
                          color: const Color(0xFF00E676).withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                    ),
                  ],

                  // Phone Icon
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isMatched
                          ? const Color(0xFF064E3B)
                          : PatiiColors.navySurface,
                      border: Border.all(
                        color: _isMatched
                            ? const Color(0xFF00E676)
                            : PatiiColors.gold,
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isMatched
                                  ? const Color(0xFF00E676)
                                  : PatiiColors.gold)
                              .withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isMatched
                          ? const Icon(
                              Icons.check_circle_rounded,
                              size: 46,
                              color: Color(0xFF00E676),
                            )
                          : const Icon(
                              Icons.phone_android_rounded,
                              size: 44,
                              color: PatiiColors.gold,
                            )
                              .animate(
                                onPlay: (c) => c.repeat(reverse: true),
                              )
                              .rotate(
                                begin: -0.12,
                                end: 0.12,
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeInOut,
                              ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status Text
            if (_isMatched) ...[
              Text(
                'Devices Connected!',
                style: PatiiTypography.display(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF00E676),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Connected with ${_matchedPlayerName ?? "Nearby Player"}',
                style: PatiiTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: PatiiColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You can add them as a friend or jump straight into room ${_matchedRoomCode ?? ""}.',
                style: PatiiTypography.body(
                  fontSize: 11.5,
                  color: PatiiColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Builder(
                builder: (context) {
                  final social = ref.watch(socialProvider);
                  final peerId = _matchedUserId ?? '';
                  final friendStatus = peerId.isNotEmpty
                      ? social.friendStatusFor(peerId)
                      : NearbyFriendStatus.none;

                  if (friendStatus == NearbyFriendStatus.accepted) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF00E676)
                                .withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 16, color: Color(0xFF00E676)),
                          SizedBox(width: 6),
                          Text(
                            'Already Friends',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (friendStatus == NearbyFriendStatus.outgoingPending) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: PatiiColors.navySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PatiiColors.hairline),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_top_rounded,
                              size: 16, color: PatiiColors.gold),
                          SizedBox(width: 6),
                          Text(
                            'Friend Request Sent',
                            style: TextStyle(
                              color: PatiiColors.goldLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    child: GoldButton(
                      label: _isSendingFriendRequest
                          ? 'Sending Request...'
                          : 'Add Friend',
                      icon: Icons.person_add_alt_1_rounded,
                      height: 46,
                      isEnabled: !_isSendingFriendRequest &&
                          (_matchedUserId != null ||
                              _matchedFriendCode != null),
                      onPressed: _sendFriendRequest,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: GhostButton(
                  label: 'Enter Room (${_matchedRoomCode ?? ""})',
                  icon: Icons.meeting_room_rounded,
                  height: 44,
                  onPressed: _enterMatchedRoom,
                ),
              ),
            ] else ...[
              Text(
                _timedOut ? 'No Devices Found' : 'Shake Phone or Tap Button',
                style: PatiiTypography.display(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: PatiiColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _timedOut
                    ? 'Make sure both phones shake at the same time on the same Wi-Fi.'
                    : 'Shake your phone or tap the button to connect with a nearby player!',
                style: PatiiTypography.body(
                  fontSize: 12,
                  color: PatiiColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: GoldButton(
                  label: _isSearching
                      ? 'SEARCHING NEARBY...'
                      : 'SHAKE TO CONNECT',
                  icon: Icons.vibration_rounded,
                  height: 48,
                  onPressed: _triggerShakeSearch,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SonarRipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _SonarRipplePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i / 3)) % 1.0;
      final radius = 48.0 + (maxRadius - 48.0) * ringProgress;
      final opacity = (1.0 - ringProgress).clamp(0.0, 1.0) * 0.45;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SonarRipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
