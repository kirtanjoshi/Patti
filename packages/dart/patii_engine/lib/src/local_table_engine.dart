import '../patii_engine.dart';

class LocalTableEngine<S, M, R, V> {
  final GameModule<S, M, R, V> module;
  final List<String> playerIds;
  final String humanPlayerId;
  final R rules;

  late S _state;
  bool _isDisposed = false;

  LocalTableEngine({
    required this.module,
    required this.playerIds,
    required this.humanPlayerId,
    required this.rules,
    required String seed,
  }) {
    _state = module.setup(playerIds, rules, seed);
  }

  S get state => _state;
  bool get isGameOver => module.isGameOver(_state);
  bool get isRoundOver => module.isRoundOver(_state);
  String? get currentActor => module.currentActor(_state);
  bool get isHumanTurn => currentActor == humanPlayerId;

  V get humanView => module.viewFor(_state, humanPlayerId);
  List<M> get humanLegalMoves => module.legalMoves(_state, humanPlayerId);

  void playMove(M move) {
    if (!isHumanTurn) {
      throw StateError('Not human player turn');
    }
    _state = module.applyMove(_state, humanPlayerId, move);
    _advanceBotsIfNeeded();
  }

  void _advanceBotsIfNeeded() {
    while (!_isDisposed && !module.isRoundOver(_state) && !module.isGameOver(_state)) {
      final actor = module.currentActor(_state);
      if (actor == null || actor == humanPlayerId) break;

      final botMove = module.autoMove(_state, actor);
      _state = module.applyMove(_state, actor, botMove);
    }
  }

  void dispose() {
    _isDisposed = true;
  }
}
