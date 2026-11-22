import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patii/core/services/audio_service.dart';
import 'package:patii/core/widgets/audio_settings_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
  });

  group('AudioService Unit Tests', () {
    test('initial state defaults are enabled with proper volumes', () {
      final audio = AudioService.instance;
      expect(audio.soundEnabled, isTrue);
      expect(audio.musicEnabled, isTrue);
      expect(audio.vibrationEnabled, isTrue);
      expect(audio.sfxVolume, greaterThan(0.0));
      expect(audio.musicVolume, greaterThan(0.0));
      expect(audio.currentTrack, equals(PatiiBgmTrack.none));
    });

    test('mutators update state and notify listeners', () async {
      final audio = AudioService.instance;
      bool notified = false;
      void listener() => notified = true;

      audio.addListener(listener);

      await audio.setSoundEnabled(false);
      expect(audio.soundEnabled, isFalse);
      expect(notified, isTrue);

      notified = false;
      await audio.setSoundEnabled(true);
      expect(audio.soundEnabled, isTrue);

      notified = false;
      await audio.setMusicEnabled(false);
      expect(audio.musicEnabled, isFalse);
      expect(notified, isTrue);

      await audio.setMusicEnabled(true);
      expect(audio.musicEnabled, isTrue);

      notified = false;
      await audio.setSfxVolume(0.4);
      expect(audio.sfxVolume, closeTo(0.4, 0.001));
      expect(notified, isTrue);

      notified = false;
      await audio.setMusicVolume(0.65);
      expect(audio.musicVolume, closeTo(0.65, 0.001));
      expect(notified, isTrue);

      notified = false;
      await audio.setVibrationEnabled(false);
      expect(audio.vibrationEnabled, isFalse);
      expect(notified, isTrue);

      await audio.setVibrationEnabled(true);
      audio.removeListener(listener);
    });

    test('all SFX methods execute cleanly', () async {
      final audio = AudioService.instance;
      await expectLater(audio.playCardSnap(), completes);
      await expectLater(audio.playCardSlide(), completes);
      await expectLater(audio.playDeal(), completes);
      await expectLater(audio.playShuffle(), completes);
      await expectLater(audio.playCardFold(), completes);
      await expectLater(audio.playChip(), completes);
      await expectLater(audio.playChip(multi: true), completes);
      await expectLater(audio.playPotCollect(), completes);
      await expectLater(audio.playYourTurnChime(), completes);
      await expectLater(audio.playCountdownTick(urgent: false), completes);
      await expectLater(audio.playCountdownTick(urgent: true), completes);
      await expectLater(audio.playSpecialHand(), completes);
      await expectLater(audio.playWinJingle(), completes);
      await expectLater(audio.playLoseStinger(), completes);
      await expectLater(audio.playCoinsCollect(), completes);
      await expectLater(audio.playButtonClick(), completes);
      await expectLater(audio.playErrorBuzz(), completes);
    });

    test('BGM playback and stop transitions update state', () async {
      final audio = AudioService.instance;
      await audio.playLobbyMusic();
      expect(audio.currentTrack, equals(PatiiBgmTrack.lobby));

      await audio.playTableMusic();
      expect(audio.currentTrack, equals(PatiiBgmTrack.table));

      await audio.stopMusic();
      expect(audio.currentTrack, equals(PatiiBgmTrack.none));
    });
  });

  group('AudioSettingsSheet Widget Tests', () {
    testWidgets('renders controls, sliders, and preview buttons',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AudioSettingsSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Audio & Haptics'), findsOneWidget);
      expect(find.text('Sound Effects (SFX)'), findsOneWidget);
      expect(find.text('Background Music (BGM)'), findsOneWidget);
      expect(find.text('Haptic Feedback'), findsOneWidget);
      expect(find.text('AUDIO PREVIEW'), findsOneWidget);

      expect(find.text('Card Snap'), findsOneWidget);
      expect(find.text('Chips Clink'), findsOneWidget);
      expect(find.text('Turn Chime'), findsOneWidget);
      expect(find.text('Win Fanfare'), findsOneWidget);

      await tester.tap(find.text('Card Snap'));
      await tester.pump();
    });
  });
}
