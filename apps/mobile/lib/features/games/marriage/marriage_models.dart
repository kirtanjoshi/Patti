import 'dart:math' as math;
import 'package:patii_engine/patii_engine.dart';

enum MeldType { pure, dublee }

enum MeldSlotStatus { empty, incomplete, pureSequence, tunnela, dublee, invalid }

class SpecialCardsInfo {
  final Card tiplu;
  final Card poplu;
  final Card jhiplu;
  final Card alter;

  const SpecialCardsInfo({
    required this.tiplu,
    required this.poplu,
    required this.jhiplu,
    required this.alter,
  });

  static int getRankAbove(int rank) {
    if (rank == 13) return 1;
    if (rank == 0) return 0;
    return rank + 1;
  }

  static int getRankBelow(int rank) {
    if (rank == 1) return 13;
    if (rank == 0) return 0;
    return rank - 1;
  }

  static Suit getAlterSuit(Suit suit) {
    switch (suit) {
      case Suit.C:
        return Suit.S;
      case Suit.S:
        return Suit.C;
      case Suit.H:
        return Suit.D;
      case Suit.D:
        return Suit.H;
      case Suit.X:
        return Suit.X;
    }
  }

  factory SpecialCardsInfo.fromMaal(Card maal) {
    final popluRank = getRankAbove(maal.rank);
    final jhipluRank = getRankBelow(maal.rank);
    final alterSuit = getAlterSuit(maal.suit);

    return SpecialCardsInfo(
      tiplu: maal,
      poplu: Card(suit: maal.suit, rank: popluRank, deck: 0, id: 'poplu_ref'),
      jhiplu: Card(suit: maal.suit, rank: jhipluRank, deck: 0, id: 'jhiplu_ref'),
      alter: Card(suit: alterSuit, rank: maal.rank, deck: 0, id: 'alter_ref'),
    );
  }
}

class MarriageMeldSlot {
  final int id;
  final MeldType type;
  final List<Card> cards;

  const MarriageMeldSlot({
    required this.id,
    required this.type,
    this.cards = const [],
  });

  int get requiredCardCount => type == MeldType.pure ? 3 : 2;

  bool get isFull => cards.length >= requiredCardCount;

  MarriageMeldSlot copyWith({
    int? id,
    MeldType? type,
    List<Card>? cards,
  }) {
    return MarriageMeldSlot(
      id: id ?? this.id,
      type: type ?? this.type,
      cards: cards ?? this.cards,
    );
  }

  MeldSlotStatus get status {
    if (cards.isEmpty) return MeldSlotStatus.empty;
    if (cards.length < requiredCardCount) return MeldSlotStatus.incomplete;

    if (type == MeldType.pure) {
      if (cards.length == 3) {
        if (isTunnela(cards)) return MeldSlotStatus.tunnela;
        if (isPureSequence(cards)) return MeldSlotStatus.pureSequence;
      }
      return MeldSlotStatus.invalid;
    } else {
      if (cards.length == 2 && isDublee(cards)) {
        return MeldSlotStatus.dublee;
      }
      return MeldSlotStatus.invalid;
    }
  }

  bool get isValid =>
      status == MeldSlotStatus.pureSequence ||
      status == MeldSlotStatus.tunnela ||
      status == MeldSlotStatus.dublee;

  static bool isTunnela(List<Card> cards) {
    if (cards.length != 3) return false;
    for (final c in cards) {
      if (c.suit == Suit.X || c.rank == 0) return false;
    }
    return cards[0].rank == cards[1].rank &&
        cards[1].rank == cards[2].rank &&
        cards[0].suit == cards[1].suit &&
        cards[1].suit == cards[2].suit;
  }

  static bool isPureSequence(List<Card> cards) {
    if (cards.length != 3) return false;
    for (final c in cards) {
      if (c.suit == Suit.X || c.rank == 0) return false;
    }
    if (cards[0].suit != cards[1].suit || cards[1].suit != cards[2].suit) {
      return false;
    }

    final ranks = cards.map((c) => c.rank).toList()..sort();
    // A-2-3
    if (ranks[0] == 1 && ranks[1] == 2 && ranks[2] == 3) return true;
    // Q-K-A
    if (ranks[0] == 1 && ranks[1] == 12 && ranks[2] == 13) return true;
    // Consecutive
    return ranks[1] == ranks[0] + 1 && ranks[2] == ranks[1] + 1;
  }

  static bool isDublee(List<Card> cards) {
    if (cards.length != 2) return false;
    for (final c in cards) {
      if (c.suit == Suit.X || c.rank == 0) return false;
    }
    return cards[0].rank == cards[1].rank && cards[0].suit == cards[1].suit;
  }
}

int calculateLiveMaalPoints({
  required List<Card> hand,
  required Card maal,
  bool alterEnabled = true,
  int manCardPoints = 5,
}) {
  final info = SpecialCardsInfo.fromMaal(maal);

  int tipluCount = 0;
  int popluCount = 0;
  int jhipluCount = 0;
  int alterCount = 0;
  int manCount = 0;

  for (final c in hand) {
    if (c.suit == Suit.X || c.rank == 0) {
      manCount++;
      continue;
    }
    if (c.suit == info.tiplu.suit && c.rank == info.tiplu.rank) {
      tipluCount++;
    } else if (c.suit == info.poplu.suit && c.rank == info.poplu.rank) {
      popluCount++;
    } else if (c.suit == info.jhiplu.suit && c.rank == info.jhiplu.rank) {
      jhipluCount++;
    } else if (alterEnabled &&
        c.suit == info.alter.suit &&
        c.rank == info.alter.rank) {
      alterCount++;
    }
  }

  final marriageSets = math.min(tipluCount, math.min(popluCount, jhipluCount));
  tipluCount -= marriageSets;
  popluCount -= marriageSets;
  jhipluCount -= marriageSets;

  int points = 0;

  // Marriage sets: 10 for single, 30 for double
  if (marriageSets == 1) {
    points += 10;
  } else if (marriageSets >= 2) {
    points += 30;
  }

  // Tiplu: 1 -> 3, 2 -> 8
  if (tipluCount == 1) {
    points += 3;
  } else if (tipluCount >= 2) {
    points += 8;
  }

  // Poplu: 1 -> 2, 2 -> 5, 3 -> 10
  if (popluCount == 1) {
    points += 2;
  } else if (popluCount == 2) {
    points += 5;
  } else if (popluCount >= 3) {
    points += 10;
  }

  // Jhiplu: 1 -> 2, 2 -> 5, 3 -> 10
  if (jhipluCount == 1) {
    points += 2;
  } else if (jhipluCount == 2) {
    points += 5;
  } else if (jhipluCount >= 3) {
    points += 10;
  }

  // Alter: 1 -> 5, 2 -> 15, 3 -> 25
  if (alterEnabled) {
    if (alterCount == 1) {
      points += 5;
    } else if (alterCount == 2) {
      points += 15;
    } else if (alterCount >= 3) {
      points += 25;
    }
  }

  points += manCount * manCardPoints;
  return points;
}

List<Card> sortCardsBySuit(List<Card> cards) {
  final copy = List<Card>.from(cards);
  final suitOrder = {
    Suit.S: 0,
    Suit.H: 1,
    Suit.D: 2,
    Suit.C: 3,
    Suit.X: 4,
  };

  copy.sort((a, b) {
    final orderA = suitOrder[a.suit] ?? 99;
    final orderB = suitOrder[b.suit] ?? 99;
    if (orderA != orderB) return orderA.compareTo(orderB);
    return a.rank.compareTo(b.rank);
  });
  return copy;
}

List<Card> sortCardsByRank(List<Card> cards) {
  final copy = List<Card>.from(cards);
  final suitOrder = {
    Suit.S: 0,
    Suit.H: 1,
    Suit.D: 2,
    Suit.C: 3,
    Suit.X: 4,
  };

  copy.sort((a, b) {
    if (a.rank != b.rank) return a.rank.compareTo(b.rank);
    final orderA = suitOrder[a.suit] ?? 99;
    final orderB = suitOrder[b.suit] ?? 99;
    return orderA.compareTo(orderB);
  });
  return copy;
}
