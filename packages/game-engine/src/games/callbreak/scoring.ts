import { CallbreakRoundScore, CallbreakRules } from './types.js';
import { PlayerId, SeatIndex } from '../../core/types.js';

export function calculateRoundScores(
  rules: CallbreakRules,
  players: readonly PlayerId[],
  bids: readonly (number | null)[],
  tricksWon: readonly number[],
  previousCumulative: readonly number[],
): CallbreakRoundScore[] {
  const result: CallbreakRoundScore[] = [];

  for (let seat = 0; seat < 4; seat++) {
    const bid = bids[seat] ?? 1;
    const tricks = tricksWon[seat] ?? 0;
    let roundScore = 0;

    if (rules.scoringStyle === 'nepali') {
      if (tricks >= bid) {
        // +call, plus 0.1 per extra trick
        const extra = tricks - bid;
        roundScore = Number((bid + extra * 0.1).toFixed(1));
      } else {
        // missed call -> -call
        roundScore = -bid;
      }
    } else {
      // Pagat classic:
      // Minimum call 2. Any call 8+ that succeeds scores 13.
      // Success requires exactly call or call+1.
      if (bid >= 8 && tricks >= bid) {
        roundScore = 13;
      } else if (tricks === bid) {
        roundScore = bid;
      } else if (tricks === bid + 1) {
        roundScore = Number((bid + 0.1).toFixed(1));
      } else {
        // Missed or over-tricks beyond call+1 count as failure
        roundScore = -bid;
      }
    }

    const cumulativeScore = Number(((previousCumulative[seat] ?? 0) + roundScore).toFixed(1));

    result.push({
      seat: seat as SeatIndex,
      playerId: players[seat]!,
      bid,
      tricksWon: tricks,
      roundScore,
      cumulativeScore,
    });
  }

  return result;
}
