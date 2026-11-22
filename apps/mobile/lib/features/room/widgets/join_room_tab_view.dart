import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';
import 'qr_scanner_sheet.dart';

/// Join Room Tab View supporting both:
/// 1. Standard 6-character alphanumeric code with clipboard paste
/// 2. 4-Digit Quick Voice PIN with large digit boxes & auto-focus
/// 3. Instant QR Code scanning sheet trigger
class JoinRoomTabView extends StatefulWidget {
  final TextEditingController codeController;
  final ValueChanged<String> onJoin;
  final VoidCallback onPaste;

  const JoinRoomTabView({
    super.key,
    required this.codeController,
    required this.onJoin,
    required this.onPaste,
  });

  @override
  State<JoinRoomTabView> createState() => _JoinRoomTabViewState();
}

class _JoinRoomTabViewState extends State<JoinRoomTabView> {
  int _inputMode = 0; // 0: 6-char Code, 1: 4-digit Voice PIN
  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
      List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onPinDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      HapticFeedback.selectionClick();
      if (index < 3) {
        _pinFocusNodes[index + 1].requestFocus();
      } else {
        _pinFocusNodes[index].unfocus();
        // Check if all 4 filled
        final pin = _pinControllers.map((c) => c.text.trim()).join();
        if (pin.length == 4) {
          widget.onJoin(pin);
        }
      }
    } else if (value.isEmpty && index > 0) {
      _pinFocusNodes[index - 1].requestFocus();
    }
  }

  void _submitPin() {
    final pin = _pinControllers.map((c) => c.text.trim()).join();
    if (pin.length == 4) {
      widget.onJoin(pin);
    }
  }

  Future<void> _openQrScanner() async {
    final scanned = await QrScannerSheet.show(context);
    if (scanned != null && scanned.isNotEmpty && mounted) {
      widget.codeController.text = scanned;
      widget.onJoin(scanned);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input Mode Segmented Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: PatiiColors.navySurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PatiiColors.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Pressable(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _inputMode = 0);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _inputMode == 0
                            ? PatiiColors.gold
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.keyboard_rounded,
                            size: 16,
                            color: _inputMode == 0
                                ? PatiiColors.navy
                                : PatiiColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Room Code',
                            style: PatiiTypography.body(
                              fontSize: 12,
                              fontWeight: _inputMode == 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _inputMode == 0
                                  ? PatiiColors.navy
                                  : PatiiColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Pressable(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _inputMode = 1);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _inputMode == 1
                            ? PatiiColors.gold
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.record_voice_over_rounded,
                            size: 16,
                            color: _inputMode == 1
                                ? PatiiColors.navy
                                : PatiiColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '4-Digit PIN',
                            style: PatiiTypography.body(
                              fontSize: 12,
                              fontWeight: _inputMode == 1
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _inputMode == 1
                                  ? PatiiColors.navy
                                  : PatiiColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Alphanumeric Mode
          if (_inputMode == 0) ...[
            Text(
              'room.enter_code'.tr(),
              style: PatiiTypography.display(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: PatiiColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.codeController,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    style: PatiiTypography.display(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: PatiiColors.goldLight,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: PatiiColors.navySurface,
                      hintText: 'e.g. 7X8K2M',
                      hintStyle: PatiiTypography.body(
                        letterSpacing: 2,
                        color: PatiiColors.textMuted,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: PatiiColors.hairline),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon:
                      const Icon(Icons.paste_rounded, color: PatiiColors.gold),
                  onPressed: widget.onPaste,
                  tooltip: 'Paste',
                ),
              ],
            ),
            const SizedBox(height: 20),
            GoldButton(
              label: 'room.join'.tr(),
              icon: Icons.login_rounded,
              height: 48,
              onPressed: () =>
                  widget.onJoin(widget.codeController.text.trim()),
            ),
          ] else ...[
            // 4-Digit Voice PIN Mode
            Text(
              'Enter 4-Digit Voice PIN',
              style: PatiiTypography.display(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: PatiiColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Quick join via 4 numbers shouted by the host nearby',
              style: PatiiTypography.body(
                fontSize: 12,
                color: PatiiColors.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            // 4 Large Digit Input Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return Container(
                  width: 58,
                  height: 64,
                  decoration: BoxDecoration(
                    color: PatiiColors.navySurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _pinControllers[index].text.isNotEmpty
                          ? const Color(0xFF00E676)
                          : PatiiColors.hairline,
                      width: _pinControllers[index].text.isNotEmpty ? 1.8 : 1.2,
                    ),
                    boxShadow: _pinControllers[index].text.isNotEmpty
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E676)
                                  .withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: TextField(
                      controller: _pinControllers[index],
                      focusNode: _pinFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: PatiiTypography.display(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF00E676),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        setState(() {});
                        _onPinDigitChanged(index, val);
                      },
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
            GoldButton(
              label: 'Join with PIN',
              icon: Icons.check_circle_rounded,
              height: 48,
              onPressed: _submitPin,
            ),
          ],

          const SizedBox(height: 24),
          // Divider with 'OR'
          Row(
            children: [
              const Expanded(child: Divider(color: PatiiColors.hairline)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: PatiiTypography.body(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: PatiiColors.textMuted,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: PatiiColors.hairline)),
            ],
          ),
          const SizedBox(height: 20),

          // Scan QR Code Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: PatiiColors.goldLight,
              side: BorderSide(
                color: PatiiColors.gold.withValues(alpha: 0.45),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: PatiiColors.navyElevated,
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded,
                color: PatiiColors.gold),
            label: Text(
              'Scan QR Code',
              style: PatiiTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: PatiiColors.goldLight,
              ),
            ),
            onPressed: _openQrScanner,
          ),
        ],
      ),
    );
  }
}
