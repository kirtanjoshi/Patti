import 'package:patii_engine/patii_engine.dart';
import 'kitti_evaluator.dart';

enum KittiPhase {
  arranging,
  revealing,
  roundOver,
}

class KittiPlayer {
  final int seatIndex;
  final String displayName;
  final bool isBot;
  final bool isReady;
  final bool isFolded;
  final int showWins;
  final List<List<Card>>? arrangedHands;

  const KittiPlayer({
    required this.seatIndex,
    required this.displayName,
    this.isBot = false,
    this.isReady = false,
    this.isFolded = false,
    this.showWins = 0,
    this.arrangedHands,
  });

  KittiPlayer copyWith({
    bool? isReady,
    bool? isFolded,
    int? showWins,
    List<List<Card>>? arrangedHands,
  }) {
    return KittiPlayer(
      seatIndex: seatIndex,
      displayName: displayName,
      isBot: isBot,
      isReady: isReady ?? this.isReady,
      isFolded: isFolded ?? this.isFolded,
      showWins: showWins ?? this.showWins,
      arrangedHands: arrangedHands ?? this.arrangedHands,
    );
  }
}

class KittiShowResult {
  final int showIndex; // 0, 1, 2
  final int? winnerSeat;
  final bool isVoid;
  final Map<int, KittiHandEvaluation> handEvaluations;

  const KittiShowResult({
    required this.showIndex,
    this.winnerSeat,
    this.isVoid = false,
    required this.handEvaluations,
  });
}

class KittiRoundSummary {
  final int? winnerSeat;
  final bool isKittiCarryover;
  final bool isSalami;
  final List<KittiShowResult> showResults;
  final int pot;

  const KittiRoundSummary({
    this.winnerSeat,
    required this.isKittiCarryover,
    required this.isSalami,
    required this.showResults,
    required this.pot,
  });
}
