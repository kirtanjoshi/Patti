import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  String _selectedGame = 'callbreak';
  int _rounds = 5;
  String? _generatedCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleCreateRoom() {
    setState(() {
      _generatedCode = 'PAT777'; // Mock room code
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('room.title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          tabs: [
            Tab(text: 'room.create'.tr()),
            Tab(text: 'room.join'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Create Room Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0), // 8-pt spacing
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'room.rules'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGame,
                  decoration: InputDecoration(
                    labelText: 'lobby.games.callbreak'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'callbreak',
                      child: Text('lobby.games.callbreak'.tr()),
                    ),
                    DropdownMenuItem(
                      value: 'marriage',
                      child: Text('lobby.games.marriage'.tr()),
                    ),
                    DropdownMenuItem(
                      value: 'teenpatti',
                      child: Text('lobby.games.teenpatti'.tr()),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedGame = val);
                  },
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('table.round'.tr(), style: theme.textTheme.bodyLarge),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1')),
                        ButtonSegment(value: 3, label: Text('3')),
                        ButtonSegment(value: 5, label: Text('5')),
                      ],
                      selected: {_rounds},
                      onSelectionChanged: (set) {
                        setState(() => _rounds = set.first);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32.0),
                Semantics(
                  button: true,
                  label: 'room.create'.tr(),
                  child: SizedBox(
                    height: 48.0, // min 48px tap target
                    child: FilledButton(
                      onPressed: _handleCreateRoom,
                      child: Text('room.create'.tr()),
                    ),
                  ),
                ),
                if (_generatedCode != null) ...[
                  const SizedBox(height: 32.0),
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      children: [
                        Text('room.code_label'.tr(), style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8.0),
                        SelectableText(
                          _generatedCode!,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4.0,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Semantics(
                          button: true,
                          label: 'room.start_game'.tr(),
                          child: SizedBox(
                            height: 48.0,
                            child: FilledButton.tonal(
                              onPressed: () {},
                              child: Text('room.start_game'.tr()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Join Room Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'room.enter_code'.tr(),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _codeController,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'room.code_label'.tr(),
                    border: const OutlineInputBorder(),
                    hintText: 'e.g. 7X8K2M',
                  ),
                ),
                const SizedBox(height: 16.0),
                Semantics(
                  button: true,
                  label: 'room.join'.tr(),
                  child: SizedBox(
                    height: 48.0, // min 48px tap target
                    child: FilledButton(
                      onPressed: () {
                        // join logic
                      },
                      child: Text('room.join'.tr()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
