import 'package:flutter_test/flutter_test.dart';
import 'package:patii_engine/patii_engine.dart';
import 'package:patii_protocol/patii_protocol.dart';

void main() {
  test('Patii engine and protocol imports succeed in mobile', () {
    const card = Card(suit: Suit.S, rank: 12, deck: 0, id: 'QS0');
    expect(card.id, 'QS0');
    expect(card.isJoker, false);

    const payload = QueueJoinPayload(
      gameId: GameId.callbreak,
      tier: StakeTier.beginner,
    );
    expect(payload.gameId, GameId.callbreak);
    expect(payload.tier, StakeTier.beginner);
  });
}
