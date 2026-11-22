import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sound and Music track identifiers for Patii.
enum PatiiBgmTrack {
  none,
  lobby,
  table,
}

/// Professional Audio & Sound Design Director for Patii Card Games Suite.
///
/// Features:
/// - Polyphonic SFX voice pool: Multiple sound players so rapid card deals,
///   chip tosses, and countdown ticks never cut each other off.
/// - Dedicated looping BGM player with independent volume & state management.
/// - Micro-interaction debouncer to prevent audio distortion from button spam.
/// - Granular persistent settings (Master, SFX, BGM, Haptics) via SharedPreferences.
/// - High-fidelity acoustic events for all 7 card games & casino lobby.
/// - Resilient lazy-initialization that works gracefully in both production and test environments.
class AudioService extends ChangeNotifier {
  AudioService._();

  static final AudioService instance = AudioService._();

  // --- Configuration Keys ---
  static const String _kSoundEnabled = 'patii_audio_sound_enabled';
  static const String _kMusicEnabled = 'patii_audio_music_enabled';
  static const String _kVibrationEnabled = 'patii_audio_vibration_enabled';
  static const String _kSfxVolume = 'patii_audio_sfx_volume';
  static const String _kMusicVolume = 'patii_audio_music_volume';

  // --- Audio State ---
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  double _sfxVolume = 0.85;
  double _musicVolume = 0.50;
  PatiiBgmTrack _currentTrack = PatiiBgmTrack.none;
  bool _isInitialized = false;

  // --- Voice Pool & Players (Lazy initialized for safety) ---
  static const int _voicePoolSize = 6;
  final List<AudioPlayer> _sfxPool = [];
  int _nextVoiceIndex = 0;
  AudioPlayer? _bgmPlayer;

  // --- Debounce Timers ---
  int _lastButtonClickTime = 0;
  int _lastCardSlideTime = 0;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  double get sfxVolume => _sfxVolume;
  double get musicVolume => _musicVolume;
  PatiiBgmTrack get currentTrack => _currentTrack;

  AudioPlayer? _getSfxPlayer(int index) {
    try {
      while (_sfxPool.length <= index && _sfxPool.length < _voicePoolSize) {
        final p = AudioPlayer();
        _sfxPool.add(p);
      }
      if (index < _sfxPool.length) {
        return _sfxPool[index];
      }
      return _sfxPool.isNotEmpty ? _sfxPool.first : null;
    } catch (_) {
      return null;
    }
  }

  AudioPlayer? _getBgmPlayer() {
    try {
      _bgmPlayer ??= AudioPlayer();
      return _bgmPlayer;
    } catch (_) {
      return null;
    }
  }

  /// Initializes persisted preferences from storage.
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_kSoundEnabled) ?? true;
      _musicEnabled = prefs.getBool(_kMusicEnabled) ?? true;
      _vibrationEnabled = prefs.getBool(_kVibrationEnabled) ?? true;
      _sfxVolume = prefs.getDouble(_kSfxVolume) ?? 0.85;
      _musicVolume = prefs.getDouble(_kMusicVolume) ?? 0.50;
      final bgm = _getBgmPlayer();
      if (bgm != null) {
        await bgm.setVolume(_musicEnabled ? _musicVolume : 0.0);
      }
    } catch (_) {
      // Graceful fallback for test or mock environments
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // --- Settings Mutators ---

  Future<void> setSoundEnabled(bool enabled) async {
    if (_soundEnabled == enabled) return;
    _soundEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSoundEnabled, enabled);
    } catch (_) {}
  }

  Future<void> setMusicEnabled(bool enabled) async {
    if (_musicEnabled == enabled) return;
    _musicEnabled = enabled;
    final bgm = _getBgmPlayer();
    if (bgm != null) {
      try {
        await bgm.setVolume(enabled ? _musicVolume : 0.0);
        if (!enabled) {
          await bgm.pause();
        } else if (_currentTrack != PatiiBgmTrack.none) {
          await _resumeCurrentTrack();
        }
      } catch (_) {}
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kMusicEnabled, enabled);
    } catch (_) {}
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    if (_vibrationEnabled == enabled) return;
    _vibrationEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kVibrationEnabled, enabled);
    } catch (_) {}
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kSfxVolume, _sfxVolume);
    } catch (_) {}
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    final bgm = _getBgmPlayer();
    if (bgm != null && _musicEnabled) {
      try {
        await bgm.setVolume(_musicVolume);
      } catch (_) {}
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kMusicVolume, _musicVolume);
    } catch (_) {}
  }

  // --- Internal Polyphonic Sound Dispatch ---

  Future<void> _playSound(String assetName, {double volumeScale = 1.0}) async {
    if (!_soundEnabled || _sfxVolume <= 0.0) return;
    try {
      final player = _getSfxPlayer(_nextVoiceIndex);
      _nextVoiceIndex = (_nextVoiceIndex + 1) % _voicePoolSize;
      if (player == null) return;

      await player.stop();
      await player.setVolume((_sfxVolume * volumeScale).clamp(0.0, 1.0));
      await player.play(AssetSource('audio/$assetName'));
    } catch (_) {
      // Gracefully silent in environments without audio device / test headless
    }
  }

  // --- Music (BGM) Channel ---

  Future<void> playLobbyMusic() async {
    if (_currentTrack == PatiiBgmTrack.lobby) return;
    _currentTrack = PatiiBgmTrack.lobby;
    if (!_musicEnabled) return;
    try {
      final bgm = _getBgmPlayer();
      if (bgm == null) return;
      await bgm.setReleaseMode(ReleaseMode.loop);
      await bgm.stop();
      await bgm.setVolume(_musicVolume);
      await bgm.play(AssetSource('audio/lobby_ambient.wav'));
    } catch (_) {}
  }

  Future<void> playTableMusic() async {
    if (_currentTrack == PatiiBgmTrack.table) return;
    _currentTrack = PatiiBgmTrack.table;
    if (!_musicEnabled) return;
    try {
      final bgm = _getBgmPlayer();
      if (bgm == null) return;
      await bgm.setReleaseMode(ReleaseMode.loop);
      await bgm.stop();
      await bgm.setVolume(_musicVolume * 0.75); // Sits gently beneath game SFX
      await bgm.play(AssetSource('audio/table_ambient.wav'));
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    _currentTrack = PatiiBgmTrack.none;
    try {
      final bgm = _getBgmPlayer();
      if (bgm != null) {
        await bgm.stop();
      }
    } catch (_) {}
  }

  Future<void> pauseMusic() async {
    try {
      final bgm = _getBgmPlayer();
      if (bgm != null) {
        await bgm.pause();
      }
    } catch (_) {}
  }

  Future<void> resumeMusic() async {
    if (!_musicEnabled || _currentTrack == PatiiBgmTrack.none) return;
    await _resumeCurrentTrack();
  }

  Future<void> _resumeCurrentTrack() async {
    try {
      final bgm = _getBgmPlayer();
      if (bgm == null) return;
      if (_currentTrack == PatiiBgmTrack.lobby) {
        await bgm.play(AssetSource('audio/lobby_ambient.wav'));
      } else if (_currentTrack == PatiiBgmTrack.table) {
        await bgm.play(AssetSource('audio/table_ambient.wav'));
      }
    } catch (_) {}
  }

  // --- Sound Effects: Cards ---

  Future<void> playShuffle() async {
    hapticLight();
    await _playSound('shuffle.wav', volumeScale: 0.9);
  }

  Future<void> playDeal() async {
    await _playSound('deal.wav', volumeScale: 0.75);
  }

  Future<void> playCardSnap() async {
    hapticCardPlay();
    await _playSound('card_snap.wav', volumeScale: 0.95);
  }

  Future<void> playCardSlide() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastCardSlideTime < 45) return;
    _lastCardSlideTime = now;
    hapticSelection();
    await _playSound('card_slide.wav', volumeScale: 0.7);
  }

  Future<void> playCardFold() async {
    hapticFold();
    await _playSound('card_fold.wav', volumeScale: 0.85);
  }

  // --- Sound Effects: Chips & Pots ---

  Future<void> playChip({bool multi = false}) async {
    hapticSelection();
    if (multi) {
      await _playSound('chip_multi.wav', volumeScale: 0.95);
    } else {
      await _playSound('chip.wav', volumeScale: 0.85);
    }
  }

  Future<void> playChipMulti() => playChip(multi: true);

  Future<void> playPotCollect() async {
    hapticLight();
    await _playSound('pot_collect.wav', volumeScale: 0.95);
  }

  // --- Sound Effects: Game State & Turns ---

  Future<void> playYourTurnChime() async {
    hapticYourTurn();
    await _playSound('your_turn.wav', volumeScale: 1.0);
  }

  Future<void> playCountdownTick({bool urgent = false}) async {
    if (urgent) {
      hapticMedium();
      await _playSound('countdown_urgent.wav', volumeScale: 0.9);
    } else {
      hapticLight();
      await _playSound('countdown_tick.wav', volumeScale: 0.7);
    }
  }

  Future<void> playSpecialHand() async {
    hapticWin();
    await _playSound('special_hand.wav', volumeScale: 1.0);
  }

  // --- Sound Effects: Outcomes & Economy ---

  Future<void> playWinJingle() async {
    hapticWin();
    await _playSound('win_jingle.wav', volumeScale: 1.0);
  }

  Future<void> playLoseStinger() async {
    hapticLight();
    await _playSound('lose_stinger.wav', volumeScale: 0.8);
  }

  Future<void> playCoinsCollect() async {
    hapticLight();
    await _playSound('coins_collect.wav', volumeScale: 0.95);
  }

  // --- Sound Effects: UI Micro-Interactions ---

  Future<void> playButtonClick() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastButtonClickTime < 40) return;
    _lastButtonClickTime = now;
    await _playSound('button_click.wav', volumeScale: 0.65);
  }

  Future<void> playErrorBuzz() async {
    hapticError();
    await _playSound('error_buzz.wav', volumeScale: 0.85);
  }

  // --- Haptic Feedback Subsystem ---

  void hapticLight() {
    if (!_vibrationEnabled) return;
    HapticFeedback.lightImpact();
  }

  void hapticMedium() {
    if (!_vibrationEnabled) return;
    HapticFeedback.mediumImpact();
  }

  void hapticSelection() {
    if (!_vibrationEnabled) return;
    HapticFeedback.selectionClick();
  }

  void hapticCardPlay() {
    if (!_vibrationEnabled) return;
    HapticFeedback.lightImpact();
  }

  void hapticFold() {
    if (!_vibrationEnabled) return;
    HapticFeedback.lightImpact();
  }

  void hapticYourTurn() {
    if (!_vibrationEnabled) return;
    HapticFeedback.mediumImpact();
  }

  void hapticWin() {
    if (!_vibrationEnabled) return;
    HapticFeedback.heavyImpact();
  }

  void hapticError() {
    if (!_vibrationEnabled) return;
    HapticFeedback.vibrate();
  }

  @override
  void dispose() {
    for (final player in _sfxPool) {
      try {
        player.dispose();
      } catch (_) {}
    }
    _sfxPool.clear();
    try {
      _bgmPlayer?.dispose();
    } catch (_) {}
    super.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService.instance;
});
