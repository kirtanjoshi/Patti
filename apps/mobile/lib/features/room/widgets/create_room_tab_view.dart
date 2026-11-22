import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';

/// Create Room tab for configuring game rules, player count, and table stake.
class CreateRoomTabView extends StatefulWidget {
  final void Function({
    required String gameId,
    required int seats,
    required int stake,
  }) onCreate;

  const CreateRoomTabView({
    super.key,
    required this.onCreate,
  });

  @override
  State<CreateRoomTabView> createState() => _CreateRoomTabViewState();
}

class _CreateRoomTabViewState extends State<CreateRoomTabView> {
  String _selectedGame = 'callbreak';
  int _stake = 0;
  int _seats = 2;

  List<int> _getAllowedSeats(String gameId) {
    switch (gameId) {
      case 'callbreak':
        return [2, 4];
      case 'teenpatti':
      case 'rummy':
      case 'jokerrummy':
        return [2, 3, 4, 5, 6];
      default:
        return [2, 3, 4, 5];
    }
  }

  void _submitCreate() {
    widget.onCreate(
      gameId: _selectedGame,
      seats: _seats,
      stake: _stake,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              if (val != null) {
                setState(() {
                  _selectedGame = val;
                  final allowed = _getAllowedSeats(val);
                  if (!allowed.contains(_seats)) {
                    _seats = allowed.first;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Number of Players',
            style: PatiiTypography.body(
                fontSize: 13, color: PatiiColors.textSecondary),
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: _getAllowedSeats(_selectedGame).map((s) {
              return ButtonSegment<int>(
                value: s,
                label: Text(
                  _selectedGame == 'callbreak' && s == 2
                    ? '2 (1v1 + 2 Bots)'
                    : '$s Players',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
            selected: {_seats},
            onSelectionChanged: (set) => setState(() => _seats = set.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? PatiiColors.gold.withValues(alpha: 0.25)
                    : PatiiColors.navySurface,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Table Stake',
            style: PatiiTypography.body(
                fontSize: 13, color: PatiiColors.textSecondary),
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
            onPressed: _submitCreate,
          ),
        ],
      ),
    );
  }
}
