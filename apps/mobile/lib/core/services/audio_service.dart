import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Audio and Haptics Service for Patii Casino Card Games.
/// Handles dealing, card snapping, chip tossing, win jingles, and turn chimes.
/// Respects user sound and vibration settings.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool soundEnabled = true;
  bool vibrationEnabled = true;

  final AudioPlayer _player = AudioPlayer();

  Future<void> _playSound(String assetName) async {
    if (!soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/$assetName'));
    } catch (_) {
      // Gracefully silent in environments without audio device / test headless
    }
  }

  // --- Sound Effects ---

  Future<void> playShuffle() => _playSound('shuffle.wav');

  Future<void> playDeal() => _playSound('deal.wav');

  Future<void> playCardSnap() async {
    hapticCardPlay();
    await _playSound('card_snap.wav');
  }

  Future<void> playChip() => _playSound('chip.wav');

  Future<void> playWinJingle() async {
    hapticWin();
    await _playSound('win_jingle.wav');
  }

  Future<void> playYourTurnChime() async {
    hapticYourTurn();
    await _playSound('your_turn.wav');
  }

  // --- Haptic Feedback ---

  void hapticCardPlay() {
    if (!vibrationEnabled) return;
    HapticFeedback.lightImpact();
  }

  void hapticYourTurn() {
    if (!vibrationEnabled) return;
    HapticFeedback.mediumImpact();
  }

  void hapticWin() {
    if (!vibrationEnabled) return;
    HapticFeedback.heavyImpact();
  }

  void dispose() {
    _player.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService.instance;
});
