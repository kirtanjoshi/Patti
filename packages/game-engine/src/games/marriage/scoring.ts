import { MarriageMode, MarriageRules } from './types.js';

export interface SettlementPlayer {
  readonly seat: number;
  readonly rawMaalPoints: number;
  readonly hasSeenMaal: boolean;
}

export interface SettlementResult {
  readonly seat: number;
  readonly paymentToWinner: number;
  readonly coinDelta: number;
}

/**
 * Calculates Marriage settlements using the exact formula from PRD Section 5.2:
 * P_i = T + w_i - n * S_i
 */
export function calculateMarriageSettlement(
  players: readonly SettlementPlayer[],
  winnerSeat: number,
  finishedWithDublees: boolean,
  rules: MarriageRules,
): SettlementResult[] {
  const n = players.length;

  // 1. Adjust maal points based on game mode (Classic, Murder, Kidnap)
  let adjustedMaal = players.map((p) => p.rawMaalPoints);
  let kidnappedPoints = 0;

  if (rules.mode === 'murder') {
    // Non-seers' maal points become 0
    adjustedMaal = players.map((p) => (p.hasSeenMaal ? p.rawMaalPoints : 0));
  } else if (rules.mode === 'kidnap') {
    // Non-seers' maal points become 0 and are transferred to winner
    adjustedMaal = players.map((p, idx) => {
      if (idx === winnerSeat) return p.rawMaalPoints;
      if (!p.hasSeenMaal) {
        kidnappedPoints += p.rawMaalPoints;
        return 0;
      }
      return p.rawMaalPoints;
    });
    adjustedMaal[winnerSeat] += kidnappedPoints;
  }

  // T = sum of adjusted maal points
  const T = adjustedMaal.reduce((sum, s) => sum + s, 0);

  // Calculate payment P_i for each non-winner to winner
  const results: SettlementResult[] = [];
  let winnerTotalGain = 0;

  for (let i = 0; i < n; i++) {
    if (i === winnerSeat) continue;

    const player = players[i]!;
    // w_i = 3 if saw maal or 10 if not, +5 if winner finished with 8 dublees
    let w_i = player.hasSeenMaal ? rules.seenPenalty : rules.unseenPenalty;
    if (finishedWithDublees) {
      w_i += 5;
    }

    const S_i = adjustedMaal[i]!;
    const P_i = T + w_i - n * S_i;
    const coinDelta = -P_i * rules.pointRate;

    winnerTotalGain += P_i * rules.pointRate;

    results.push({
      seat: i,
      paymentToWinner: P_i,
      coinDelta,
    });
  }

  // Winner entry
  results.push({
    seat: winnerSeat,
    paymentToWinner: 0,
    coinDelta: winnerTotalGain,
  });

  return results.sort((a, b) => a.seat - b.seat);
}
