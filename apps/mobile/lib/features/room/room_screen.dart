import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/user_model.dart';
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

class RoomScreen extends ConsumerStatefulWidget {
  final String? initialCode;

  const RoomScreen({super.key, this.initialCode});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  String _selectedGame = 'callbreak';
  int _stake = 0;
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
      final gameId = data['gameId'] as String? ?? _currentRoom?.gameId ?? 'callbreak';
      _navigateToGameTable(gameId);
    });
  }

  void _navigateToGameTable(String gameId) {
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
        targetScreen = const CallbreakTableScreen();
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

  void _handleCreateRoom() {
    final socket = ref.read(socketServiceProvider);
    socket.createRoom(
      gameId: _selectedGame,
      rules: {},
      stake: _stake,
      seats: 4,
    );
  }

  void _handleJoinRoom() {
    final code = _codeController.text.trim();
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
    final link = 'https://patii.app/r/$code';
    Share.share(
      'Join my private table on Patii Card Games! Tap to enter: $link (Room Code: $code)',
      subject: 'Patii Private Table Invite',
    );
  }

  void _addBot() {
    if (_currentRoom == null) return;
    ref.read(socketServiceProvider).addBot(_currentRoom!.code);
    ToastBanner.show(context, 'Bot added to room', icon: Icons.smart_toy_outlined);
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
          style: PatiiTypography.display(fontSize: 18, fontWeight: FontWeight.bold),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'room.rules'.tr(),
            style: PatiiTypography.display(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: PatiiColors.goldLight,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _selectedGame,
            dropdownColor: PatiiColors.navyElevated,
            style: PatiiTypography.body(color: PatiiColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: PatiiColors.navySurface,
              labelText: 'Select Game',
              labelStyle: PatiiTypography.body(color: PatiiColors.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: PatiiColors.hairline),
              ),
            ),
            items: [
              'callbreak',
              'marriage',
              'teenpatti',
              'kitti',
              'dhumbal',
              'jutpatti',
              'rummy',
              'jokerrummy'
            ].map((id) {
              return DropdownMenuItem(
                value: id,
                child: Text('lobby.games.$id'.tr()),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedGame = val);
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Table Stake',
            style: PatiiTypography.body(fontSize: 13, color: PatiiColors.textSecondary),
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Friendly (0)')),
              ButtonSegment(value: 100, label: Text('100')),
              ButtonSegment(value: 500, label: Text('500')),
            ],
            selected: {_stake},
            onSelectionChanged: (set) => setState(() => _stake = set.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? PatiiColors.gold.withValues(alpha: 0.25)
                    : PatiiColors.navySurface,
              ),
            ),
          ),
          const SizedBox(height: 32),
          GoldButton(
            label: 'room.create'.tr(),
            icon: Icons.add_circle_outline_rounded,
            height: 50,
            onPressed: _handleCreateRoom,
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRoomTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'room.enter_code'.tr(),
            style: PatiiTypography.display(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: PatiiColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
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
                    hintStyle: PatiiTypography.body(letterSpacing: 2, color: PatiiColors.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: PatiiColors.hairline),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.paste_rounded, color: PatiiColors.gold),
                onPressed: _pasteFromClipboard,
                tooltip: 'Paste',
              ),
            ],
          ),
          const SizedBox(height: 24),
          GoldButton(
            label: 'room.join'.tr(),
            icon: Icons.login_rounded,
            height: 50,
            onPressed: _handleJoinRoom,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomLobby(RoomStateModel room) {
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
          style: PatiiTypography.display(fontSize: 17, fontWeight: FontWeight.bold),
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
                border: Border.all(color: PatiiColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('room.code_label'.tr(),
                            style: PatiiTypography.body(fontSize: 12, color: PatiiColors.textMuted)),
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
                    icon: const Icon(Icons.copy_rounded, color: PatiiColors.gold),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: room.code));
                      ToastBanner.show(context, 'Room code copied!', icon: Icons.copy_rounded);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: PatiiColors.info),
                    onPressed: () => _shareRoom(room.code),
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
                  final participant =
                      room.participants.firstWhere((p) => p.seat == index, orElse: () => const RoomParticipantModel(seat: -1, userId: '', displayName: ''));
                  final isOccupied = participant.seat != -1;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isOccupied ? PatiiColors.navyElevated : PatiiColors.navySurface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isOccupied ? PatiiColors.gold.withValues(alpha: 0.2) : PatiiColors.hairline),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isOccupied ? PatiiColors.gold.withValues(alpha: 0.15) : Colors.white10,
                          child: Icon(
                            isOccupied
                                ? (participant.isBot ? Icons.smart_toy_outlined : Icons.person)
                                : Icons.chair_alt_outlined,
                            color: isOccupied ? PatiiColors.goldLight : PatiiColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            isOccupied
                                ? '${participant.displayName} ${participant.isHost ? "👑" : ""}'
                                : 'Empty Seat ${index + 1}',
                            style: PatiiTypography.body(
                              fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
                              color: isOccupied ? PatiiColors.textPrimary : PatiiColors.textMuted,
                            ),
                          ),
                        ),
                        if (!isOccupied)
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16, color: PatiiColors.gold),
                            label: const Text('Add Bot', style: TextStyle(color: PatiiColors.gold, fontSize: 12)),
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
