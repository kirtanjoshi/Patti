import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patii/core/models/user_model.dart';
import 'package:patii/core/services/socket_service.dart';
import 'package:patii/features/friends/widgets/nearby_player_card.dart';
import 'package:patii/features/friends/widgets/radar_dome_widget.dart';
import 'package:patii/features/friends/widgets/shake_match_dialog.dart';
import 'package:patii/features/room/widgets/join_room_tab_view.dart';
import 'package:patii/features/room/widgets/qr_scanner_sheet.dart';
import 'package:patii/features/room/widgets/room_qr_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Same Wi-Fi & Voice PIN Models Tests', () {
    test('NearbyPlayerModel parses isSameWifi correctly', () {
      final jsonWithWifi = {
        'userId': 'usr_1',
        'displayName': 'Suman',
        'friendCode': 'PT-1234',
        'distanceMeters': 15,
        'distanceText': '15m away',
        'isSameWifi': true,
      };

      final playerWithWifi = NearbyPlayerModel.fromJson(jsonWithWifi);
      expect(playerWithWifi.isSameWifi, isTrue);
      expect(playerWithWifi.displayName, 'Suman');

      final jsonWithoutWifi = {
        'userId': 'usr_2',
        'displayName': 'Bikash',
        'friendCode': 'PT-5678',
        'distanceMeters': 120,
        'distanceText': '120m away',
      };
      final playerWithoutWifi = NearbyPlayerModel.fromJson(jsonWithoutWifi);
      expect(playerWithoutWifi.isSameWifi, isFalse);
    });

    test('RoomStateModel parses pin correctly', () {
      final jsonWithPin = {
        'code': 'PAT777',
        'pin': '5521',
        'gameId': 'callbreak',
        'hostUserId': 'host_1',
        'participants': [],
      };
      final room = RoomStateModel.fromJson(jsonWithPin);
      expect(room.code, 'PAT777');
      expect(room.pin, '5521');

      final jsonWithoutPin = {
        'code': 'PAT888',
        'gameId': 'marriage',
        'hostUserId': 'host_2',
        'participants': [],
      };
      final roomNoPin = RoomStateModel.fromJson(jsonWithoutPin);
      expect(roomNoPin.pin, isNull);
    });
  });

  group('SocketService Shake to Match Tests', () {
    test('SocketService shakeToMatch emits match on stream in mock mode',
        () async {
      final service = SocketService();
      expectLater(
        service.shakeMatchedStream,
        emits(predicate<Map<String, dynamic>>((map) =>
            map.containsKey('code') && map['gameId'] == 'callbreak')),
      );

      service.shakeToMatch('callbreak');
      await Future.delayed(const Duration(milliseconds: 1600));
      service.dispose();
    });
  });

  group('Same Wi-Fi Badge & Radar Dome Widgets Tests', () {
    testWidgets('NearbyPlayerCard renders Same Wi-Fi badge when isSameWifi is true',
        (tester) async {
      const wifiPlayer = NearbyPlayerModel(
        userId: 'p1',
        displayName: 'Aayush Shrestha',
        friendCode: 'PT-9999',
        distanceMeters: 8,
        distanceText: '8m away',
        isSameWifi: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NearbyPlayerCard(
              player: wifiPlayer,
              onAddFriend: () {},
              onInvite: () {},
            ),
          ),
        ),
      );

      expect(find.text('Aayush Shrestha'), findsOneWidget);
      expect(find.text('Same Wi-Fi Network'), findsOneWidget);
      expect(find.text('📶'), findsOneWidget);
    });

    testWidgets('RadarDomeWidget renders Wi-Fi glyph for same Wi-Fi player',
        (tester) async {
      final animController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 3),
      );

      const wifiPlayer = NearbyPlayerModel(
        userId: 'p1',
        displayName: 'Aayush',
        friendCode: 'PT-9999',
        distanceMeters: 8,
        distanceText: '8m away',
        isSameWifi: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadarDomeWidget(
              animation: animController,
              radiusKm: 5.0,
              players: const [wifiPlayer],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);
      animController.dispose();
    });
  });

  group('Room QR Dialog & Scanner Sheet Tests', () {
    testWidgets('RoomQrDialog renders room code, voice PIN, and share button',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoomQrDialog(
              roomCode: 'PAT999',
              pin: '8833',
            ),
          ),
        ),
      );

      expect(find.text('TABLE QR CODE'), findsOneWidget);
      expect(find.text('PAT999'), findsOneWidget);
      expect(find.text('8833'), findsOneWidget);
      expect(find.text('Share Table Link'), findsOneWidget);
    });

    testWidgets('QrScannerSheet renders viewfinder and instant scan button',
        (tester) async {
      String? scannedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrScannerSheet(
              onCodeScanned: (code) {
                scannedResult = code;
              },
            ),
          ),
        ),
      );

      expect(find.text('SCAN ROOM QR CODE'), findsOneWidget);
      expect(find.text('Instant Simulated Camera Scan'), findsOneWidget);

      await tester.tap(find.text('Instant Simulated Camera Scan'));
      await tester.pump();
      expect(scannedResult, 'PAT777');
    });
  });

  group('JoinRoomTabView & ShakeMatchDialog Tests', () {
    testWidgets('JoinRoomTabView toggles between Code and 4-digit PIN modes',
        (tester) async {
      final codeCtrl = TextEditingController();
      String? joinedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JoinRoomTabView(
              codeController: codeCtrl,
              onJoin: (v) => joinedValue = v,
              onPaste: () {},
            ),
          ),
        ),
      );

      expect(find.text('Room Code'), findsOneWidget);
      expect(find.text('4-Digit PIN'), findsOneWidget);

      // Switch to 4-Digit PIN tab
      await tester.tap(find.text('4-Digit PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Enter 4-Digit Voice PIN'), findsOneWidget);
      expect(find.text('Join with PIN'), findsOneWidget);

      // Enter digits
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(4));

      await tester.enterText(textFields.at(0), '5');
      await tester.enterText(textFields.at(1), '5');
      await tester.enterText(textFields.at(2), '2');
      await tester.enterText(textFields.at(3), '1');
      await tester.pumpAndSettle();

      expect(joinedValue, '5521');
    });

    testWidgets('ShakeMatchDialog renders sonar visual and action button',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ShakeMatchDialog(gameId: 'callbreak'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SHAKE TO MATCH'), findsWidgets);
      expect(find.byIcon(Icons.phone_android_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
