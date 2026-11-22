import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/api_const.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/toast_banner.dart';
import '../games/callbreak/callbreak_table_screen.dart';
import '../games/dhumbal/dhumbal_table_screen.dart';
import '../games/jutpatti/jutpatti_table_screen.dart';
import '../games/kitti/kitti_table_screen.dart';
import '../games/marriage/marriage_table_screen.dart';
import '../games/rummy/rummy_table_screen.dart';
import '../games/teenpatti/teenpatti_table_screen.dart';
import 'widgets/create_room_tab_view.dart';
import 'widgets/join_room_tab_view.dart';
import 'widgets/room_qr_dialog.dart';

class RoomScreen extends ConsumerStatefulWidget {
  final String? initialCode;

  const RoomScreen({super.key, this.initialCode});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  RoomStateModel? _currentRoom;
  StreamSubscription? _roomSub;
  StreamSubscription? _startSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
      _tabController.index = 1; // Go to Join tab
    }
    _listenToRoomEvents();
  }

  void _listenToRoomEvents() {
    final socket = ref.read(socketServiceProvider);
    _roomSub = socket.roomStateStream.listen((room) {
      if (mounted) setState(() => _currentRoom = room);
    });

    _startSub = socket.roomStartedStream.listen((data) {
      if (!mounted) return;
      final gameId =
          data['gameId'] as String? ?? _currentRoom?.gameId ?? 'callbreak';
      final tableId = data['tableId'] as String?;
      final myUserId = ref.read(authProvider).user?.userId;
      final mySeat = _currentRoom?.participants
              .firstWhere(
                (p) => p.userId == myUserId,
                orElse: () => _currentRoom!.participants.first,
              )
              .seat ??
          0;
      _navigateToGameTable(
        gameId,
        tableId: tableId,
        mySeat: mySeat,
        participants: _currentRoom?.participants,
      );
    });
  }

  void _navigateToGameTable(
    String gameId, {
    String? tableId,
    int mySeat = 0,
    List<RoomParticipantModel>? participants,
  }) {
    Widget targetScreen;
    switch (gameId) {
      case 'marriage':
        targetScreen = const MarriageTableScreen();
        break;
      case 'teenpatti':
        targetScreen = const TeenPattiTableScreen();
        break;
      case 'kitti':
        targetScreen = const KittiTableScreen();
        break;
      case 'dhumbal':
        targetScreen = const DhumbalTableScreen();
        break;
      case 'jutpatti':
        targetScreen = const JutpattiTableScreen();
        break;
      case 'rummy':
        targetScreen = const RummyTableScreen();
        break;
      case 'jokerrummy':
        targetScreen = const RummyTableScreen(isJokerVariant: true);
        break;
      case 'callbreak':
      default:
        targetScreen = CallbreakTableScreen(
          tableId: tableId,
          mySeat: mySeat,
          participants: participants,
        );
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _startSub?.cancel();
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleCreateRoom({
    required String gameId,
    required int seats,
    required int stake,
  }) {
    final socket = ref.read(socketServiceProvider);
    socket.createRoom(
      gameId: gameId,
      rules: {},
      stake: stake,
      seats: seats,
    );
  }

  void _handleJoinRoom([String? customCode]) {
    final code = customCode ?? _codeController.text.trim();
    if (code.length < 4) return;
    final socket = ref.read(socketServiceProvider);
    socket.joinRoom(code);
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      String text = data!.text!.trim();
      if (text.contains('/r/')) {
        text = text.split('/r/').last;
      } else if (text.contains('room/')) {
        text = text.split('room/').last;
      }
      setState(() => _codeController.text = text.toUpperCase());
    }
  }

  void _shareRoom(String code) {
    HapticFeedback.lightImpact();
    final link = ApiConst.roomInviteUrl(code);
    Share.share(
      'Join my private table on Patii Card Games! Tap to enter: $link (Room Code: $code)',
      subject: 'Patii Private Table Invite',
    );
  }

  void _addBot() {
    if (_currentRoom == null) return;
    ref.read(socketServiceProvider).addBot(_currentRoom!.code);
    ToastBanner.show(context, 'Bot added to room',
        icon: Icons.smart_toy_outlined);
  }

  void _startGame() {
    if (_currentRoom == null) return;
    ref.read(socketServiceProvider).startRoom(_currentRoom!.code);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRoom != null) {
      return _buildRoomLobby(_currentRoom!);
    }

    return Scaffold(
      backgroundColor: PatiiColors.navy,
      appBar: AppBar(
        backgroundColor: PatiiColors.navyElevated,
        title: Text(
          'room.title'.tr(),
          style: PatiiTypography.display(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: PatiiColors.goldLight,
          unselectedLabelColor: PatiiColors.textMuted,
          indicatorColor: PatiiColors.gold,
          tabs: [
            Tab(text: 'room.create'.tr()),
            Tab(text: 'room.join'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateRoomTab(),
          _buildJoinRoomTab(),
        ],
      ),
    );
  }

  Widget _buildCreateRoomTab() {
    return CreateRoomTabView(onCreate: _handleCreateRoom);
  }

  Widget _buildJoinRoomTab() {
    return JoinRoomTabView(
      codeController: _codeController,
      onJoin: _handleJoinRoom,
      onPaste: _pasteFromClipboard,
    );
  }

  Widget _buildRoomLobby(RoomStateModel room) {
    final voicePin = room.pin ??
        (room.code.length >= 4
            ? room.code.substring(room.code.length - 4)
            : '5521');

    return Scaffold(
      backgroundColor: PatiiColors.navy,
      appBar: AppBar(
        backgroundColor: PatiiColors.navyElevated,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: PatiiColors.textPrimary),
          onPressed: () {
            ref.read(socketServiceProvider).leaveRoom(room.code);
            setState(() => _currentRoom = null);
          },
        ),
        title: Text(
          'Room Lobby · ${room.gameId.toUpperCase()}',
          style: PatiiTypography.display(
              fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Code & Share Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: PatiiColors.navySurface,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: PatiiColors.gold.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('room.code_label'.tr(),
                                style: PatiiTypography.body(
                                    fontSize: 12, color: PatiiColors.textMuted)),
                            const SizedBox(height: 2),
                            SelectableText(
                              room.code,
                              style: PatiiTypography.display(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: PatiiColors.goldLight,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            color: PatiiColors.gold),
                        tooltip: 'Copy Code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: room.code));
                          ToastBanner.show(context, 'Room code copied!',
                              icon: Icons.copy_rounded);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_2_rounded,
                            color: PatiiColors.gold),
                        tooltip: 'QR Code',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => RoomQrDialog(
                              roomCode: room.code,
                              pin: voicePin,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_rounded,
                            color: PatiiColors.info),
                        tooltip: 'Share',
                        onPressed: () => _shareRoom(room.code),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Voice PIN Prominent Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: PatiiColors.navyElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00E676).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.record_voice_over_rounded,
                              color: Color(0xFF00E676),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Voice PIN: ',
                              style: PatiiTypography.body(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: PatiiColors.textMuted,
                              ),
                            ),
                            SelectableText(
                              voicePin,
                              style: PatiiTypography.display(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF00E676),
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded,
                                  color: PatiiColors.gold, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Copy Voice PIN',
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: voicePin));
                                ToastBanner.show(
                                  context,
                                  'Voice PIN copied: $voicePin',
                                  icon: Icons.copy_rounded,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.volume_up_rounded,
                                size: 12, color: PatiiColors.goldLight),
                            const SizedBox(width: 4),
                            Text(
                              'Shout this 4-digit PIN to friends nearby',
                              style: PatiiTypography.body(
                                fontSize: 10.5,
                                color: PatiiColors.goldLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Seats list
            Expanded(
              child: ListView.separated(
                itemCount: room.maxSeats,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final participant = room.participants.firstWhere(
                      (p) => p.seat == index,
                      orElse: () => const RoomParticipantModel(
                          seat: -1, userId: '', displayName: ''));
                  final isOccupied = participant.seat != -1;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isOccupied
                          ? PatiiColors.navyElevated
                          : PatiiColors.navySurface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isOccupied
                              ? PatiiColors.gold.withValues(alpha: 0.2)
                              : PatiiColors.hairline),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isOccupied
                              ? PatiiColors.gold.withValues(alpha: 0.15)
                              : Colors.white10,
                          child: Icon(
                            isOccupied
                                ? (participant.isBot
                                    ? Icons.smart_toy_outlined
                                    : Icons.person)
                                : Icons.chair_alt_outlined,
                            color: isOccupied
                                ? PatiiColors.goldLight
                                : PatiiColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            isOccupied
                                ? '${participant.displayName} ${participant.isHost ? "👑" : ""}'
                                : 'Empty Seat ${index + 1}',
                            style: PatiiTypography.body(
                              fontWeight: isOccupied
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isOccupied
                                  ? PatiiColors.textPrimary
                                  : PatiiColors.textMuted,
                            ),
                          ),
                        ),
                        if (!isOccupied)
                          TextButton.icon(
                            icon: const Icon(Icons.add,
                                size: 16, color: PatiiColors.gold),
                            label: const Text('Add Bot',
                                style: TextStyle(
                                    color: PatiiColors.gold, fontSize: 12)),
                            onPressed: _addBot,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Start Game Button
            SizedBox(
              width: double.infinity,
              child: GoldButton(
                label: 'room.start_game'.tr(),
                icon: Icons.play_arrow_rounded,
                height: 52,
                isEnabled: room.participants.length >= 2,
                onPressed: _startGame,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
