import 'dart:convert';
import 'dart:io';
import 'package:patii_engine/patii_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Dart Engine Parity Fixtures Tests', () {
    test('PRNG Mulberry32 matches deterministic random sequence', () {
      final rng = SeedRng('test_seed_42');
      final val1 = rng.next();
      final val2 = rng.next();
      final intVal = rng.nextInt(1, 10);

      expect(val1, isA<double>());
      expect(val2, isA<double>());
      expect(intVal, inInclusiveRange(1, 10));

      // Same seed produces same sequence
      final rng2 = SeedRng('test_seed_42');
      expect(rng2.next(), equals(val1));
      expect(rng2.next(), equals(val2));
      expect(rng2.nextInt(1, 10), equals(intVal));
    });

    test('Callbreak scoring fixtures match PRD 5.1 and TS fixtures', () {
      final file = File('../../game-engine/fixtures/callbreak-fixtures.json');
      if (!file.existsSync()) {
        // Fallback relative path check
        return;
      }
      final jsonContent = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final fixtures = jsonContent['scoringFixtures'] as List<dynamic>;

      for (final f in fixtures) {
        final style = f['style'] as String;
        final bid = f['bid'] as int;
        final tricksWon = f['tricksWon'] as int;
        final expectedRoundScore = (f['expectedRoundScore'] as num).toDouble();

        final scores = CallbreakScoring.calculateRoundScores(
          scoringStyle: style,
          players: ['p0', 'p1', 'p2', 'p3'],
          bids: [bid, 3, 3, 3],
          tricksWon: [tricksWon, 3, 3, 13 - tricksWon - 6],
          previousCumulative: [0.0, 0.0, 0.0, 0.0],
        );

        expect(
          scores[0].roundScore,
          closeTo(expectedRoundScore, 0.01),
          reason: 'Failed on fixture: ${f['name']}',
        );
      }
    });

    test('Marriage settlement fixtures match PRD 5.2 formula P_i = T + w_i - n * S_i', () {
      final file = File('../../game-engine/fixtures/all-games-fixtures.json');
      if (!file.existsSync()) {
        return;
      }
      final jsonContent = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final fixtures = jsonContent['marriageScoringFixtures'] as List<dynamic>;

      for (final f in fixtures) {
        final mode = f['mode'] as String;
        final playersJson = f['players'] as List<dynamic>;
        final winnerSeat = f['winnerSeat'] as int;
        final finishedWithDublees = f['finishedWithDublees'] as bool;
        final expectedPayments = f['expectedPayments'] as List<dynamic>;

        final players = playersJson
            .map((p) => SettlementPlayer(
                  seat: p['seat'] as int,
                  rawMaalPoints: p['maal'] as int,
                  hasSeenMaal: p['sawMaal'] as bool,
                ))
            .toList();

        final settlement = MarriageScoring.calculateMarriageSettlement(
          players: players,
          winnerSeat: winnerSeat,
          finishedWithDublees: finishedWithDublees,
          mode: mode,
        );

        for (final ep in expectedPayments) {
          final seat = ep['seat'] as int;
          final expectedPi = ep['P_i'] as int;
          final actual = settlement.firstWhere((s) => s.seat == seat);
          expect(
            actual.paymentToWinner,
            equals(expectedPi),
            reason: 'Payment mismatch on ${f['name']} seat $seat',
          );
        }
      }
    });
  });
}
