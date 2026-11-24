import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/toast_banner.dart';
import '../../room/room_screen.dart';

/// Shared helper to invite a friend to the current room, or create a new room
/// and send the invitation in one flow.
class InviteToRoomHelper {
  static Future<void> inviteFriend(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required String displayName,
  }) async {
    final socket = ref.read(socketServiceProvider);
    final activeRoom = socket.currentRoom;

    if (activeRoom != null) {
      socket.inviteFriendToRoom(activeRoom.code, userId);
      ToastBanner.show(
        context,
        'Invited $displayName to room ${activeRoom.code}!',
        icon: Icons.send_rounded,
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _QuickCreateAndInviteSheet(
        targetUserId: userId,
        targetDisplayName: displayName,
      ),
    );
  }
}

class _QuickCreateAndInviteSheet extends ConsumerStatefulWidget {
  final String targetUserId;
  final String targetDisplayName;

  const _QuickCreateAndInviteSheet({
    required this.targetUserId,
    required this.targetDisplayName,
  });

  @override
  ConsumerState<_QuickCreateAndInviteSheet> createState() =>
      _QuickCreateAndInviteSheetState();
}

class _QuickCreateAndInviteSheetState
    extends ConsumerState<_QuickCreateAndInviteSheet> {
  String _selectedGame = 'callbreak';
  int _seats = 4;
  bool _isCreating = false;
  StreamSubscription<RoomStateModel>? _roomSub;

  static const _games = [
    ('callbreak', 'Callbreak', 4),
    ('marriage', 'Marriage', 4),
    ('teenpatti', 'Teen Patti', 5),
    ('kitti', 'Kitti', 4),
    ('dhumbal', 'Dhumbal', 4),
    ('jutpatti', 'Jutpatti', 4),
    ('rummy', 'Nepali Rummy', 4),
  ];

  @override
  void dispose() {
    _roomSub?.cancel();
    super.dispose();
  }

  void _createAndInvite() {
    if (_isCreating) return;
    HapticFeedback.mediumImpact();
    setState(() => _isCreating = true);

    final socket = ref.read(socketServiceProvider);
    _roomSub?.cancel();
    _roomSub = socket.roomStateStream.listen((room) {
      if (!mounted) return;
      _roomSub?.cancel();
      socket.inviteFriendToRoom(room.code, widget.targetUserId);

      Navigator.of(context).pop();
      ToastBanner.show(
        context,
        'Room ${room.code} created & ${widget.targetDisplayName} invited!',
        icon: Icons.send_rounded,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoomScreen(initialRoom: room),
        ),
      );
    });

    socket.createRoom(
      gameId: _selectedGame,
      rules: {},
      stake: 0,
      seats: _seats,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PatiiColors.navyElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: PatiiColors.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Invite ${widget.targetDisplayName} to Room',
            style: PatiiTypography.display(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: PatiiColors.goldLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a game to create a private room and send an invite.',
            style: PatiiTypography.body(
              fontSize: 12,
              color: PatiiColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _games.map((g) {
              final (id, label, defaultSeats) = g;
              final selected = _selectedGame == id;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                selectedColor: PatiiColors.gold,
                backgroundColor: PatiiColors.navySurface,
                labelStyle: TextStyle(
                  color: selected ? PatiiColors.navy : PatiiColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedGame = id;
                      _seats = defaultSeats;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          GoldButton(
            label: _isCreating
                ? 'Creating Room...'
                : 'Create Room & Invite',
            icon: Icons.send_rounded,
            height: 48,
            isEnabled: !_isCreating,
            onPressed: _createAndInvite,
          ),
        ],
      ),
    );
  }
}
