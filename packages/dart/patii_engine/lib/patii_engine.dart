/// Pure deterministic Dart game engine abstractions for Patii.
library;

export 'src/prng.dart';
export 'src/callbreak.dart';
export 'src/marriage.dart';
export 'src/local_table_engine.dart';

enum Suit { S, H, D, C, X }

class Card {
  final Suit suit;
  final int rank; // 1..13 or 0 for joker
  final int deck; // 0..2
  final String id;

  const Card({
    required this.suit,
    required this.rank,
    required this.deck,
    required this.id,
  });

  bool get isJoker => suit == Suit.X || rank == 0;

  bool sameRankAndSuit(Card other) =>
      suit == other.suit && rank == other.rank;

  bool isExactCard(Card other) => id == other.id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Card &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

abstract class GameModule<S, M, R, V> {
  String get id;
  R get defaultRules;
  R validateRules(R rules);
  S setup(List<String> players, R rules, String seed);
  List<M> legalMoves(S state, String player);
  S applyMove(S state, String player, M move);
  String? currentActor(S state);
  bool isRoundOver(S state);
  bool isGameOver(S state);
  V viewFor(S state, String player);
  M autoMove(S state, String player);
}
