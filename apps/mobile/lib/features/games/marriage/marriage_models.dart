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

List<MarriageMeldSlot> createInitialMeldSlots(MeldType type) {
  final count = type == MeldType.pure ? 3 : 7;
  return List.generate(
    count,
    (index) => MarriageMeldSlot(id: index, type: type),
  );
}

List<List<Card>> findAutoGroupPureCombinations(List<Card> hand) {
  final combinations = <List<Card>>[];
  final remaining = List<Card>.from(hand);

  // Check for tunnelas
  final groupedByRankAndSuit = <String, List<Card>>{};
  for (final c in remaining) {
    final key = '${c.rank}_${c.suit}';
    groupedByRankAndSuit.putIfAbsent(key, () => []).add(c);
  }
  for (final group in groupedByRankAndSuit.values) {
    if (group.length >= 3 && combinations.length < 3) {
      final tunnela = group.take(3).toList();
      combinations.add(tunnela);
      for (final c in tunnela) {
        remaining.removeWhere((x) => x.id == c.id);
      }
    }
  }

  // Check for pure sequences in remaining
  final suits = [Suit.S, Suit.H, Suit.D, Suit.C];
  bool found = true;
  while (found && combinations.length < 3) {
    found = false;
    for (final suit in suits) {
      final suitCards = remaining.where((c) => c.suit == suit).toList();
      if (suitCards.length < 3) continue;
      for (int i = 0; i < suitCards.length; i++) {
        for (int j = i + 1; j < suitCards.length; j++) {
          for (int k = j + 1; k < suitCards.length; k++) {
            final trio = [suitCards[i], suitCards[j], suitCards[k]];
            if (MarriageMeldSlot.isPureSequence(trio)) {
              combinations.add(trio);
              for (final c in trio) {
                remaining.removeWhere((x) => x.id == c.id);
              }
              found = true;
              break;
            }
          }
          if (found) break;
        }
        if (found) break;
      }
      if (found) break;
    }
  }

  return combinations;
}

List<Card> createInitialStockPile() => [
      const Card(suit: Suit.S, rank: 1, deck: 1, id: 'AS1'),
      const Card(suit: Suit.H, rank: 4, deck: 1, id: '4H1'),
      const Card(suit: Suit.D, rank: 12, deck: 1, id: 'QD1'),
      const Card(suit: Suit.C, rank: 9, deck: 1, id: '9C1'),
      const Card(suit: Suit.S, rank: 3, deck: 1, id: '3S1'),
    ];

List<Card> createInitialDiscardPile() => [
      const Card(suit: Suit.H, rank: 2, deck: 0, id: '2H0'),
    ];

List<Card> createInitialMarriageHand() => [
      // Pure Sequence 1 (also Marriage with cut joker)
      const Card(suit: Suit.C, rank: 10, deck: 0, id: '10C0'),
      const Card(suit: Suit.C, rank: 11, deck: 1, id: 'JC1'),
      const Card(suit: Suit.C, rank: 12, deck: 0, id: 'QC0'),
      // Pure Sequence 2
      const Card(suit: Suit.S, rank: 4, deck: 0, id: '4S0'),
      const Card(suit: Suit.S, rank: 5, deck: 0, id: '5S0'),
      const Card(suit: Suit.S, rank: 6, deck: 0, id: '6S0'),
      // Tunnela (3 identical 7 of diamonds)
      const Card(suit: Suit.D, rank: 7, deck: 0, id: '7D0'),
      const Card(suit: Suit.D, rank: 7, deck: 1, id: '7D1'),
      const Card(suit: Suit.D, rank: 7, deck: 2, id: '7D2'),
      // Alter card
      const Card(suit: Suit.S, rank: 11, deck: 0, id: 'JS0'),
      // Dublees and other cards
      const Card(suit: Suit.C, rank: 2, deck: 0, id: '2C0'),
      const Card(suit: Suit.C, rank: 2, deck: 1, id: '2C1'),
      const Card(suit: Suit.S, rank: 13, deck: 0, id: 'KS0'),
      const Card(suit: Suit.S, rank: 13, deck: 1, id: 'KS1'),
      const Card(suit: Suit.H, rank: 8, deck: 0, id: '8H0'),
      const Card(suit: Suit.H, rank: 9, deck: 0, id: '9H0'),
      const Card(suit: Suit.H, rank: 10, deck: 0, id: '10H0'),
      const Card(suit: Suit.D, rank: 3, deck: 0, id: '3D0'),
      const Card(suit: Suit.D, rank: 5, deck: 0, id: '5D0'),
      const Card(suit: Suit.S, rank: 9, deck: 0, id: '9S0'),
      const Card(suit: Suit.D, rank: 1, deck: 0, id: 'AD0'),
    ];
