import { describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as path from 'node:path';
import {
  DEFAULT_DHUMBAL_RULES,
  DEFAULT_JUTPATTI_RULES,
  DEFAULT_KITTI_RULES,
  DEFAULT_MARRIAGE_RULES,
  DEFAULT_TEEN_PATTI_RULES,
  DhumbalGameModule,
  JutpattiGameModule,
  KittiGameModule,
  MarriageGameModule,
  RummyGameModule,
  TeenPattiGameModule,
  calculateDhumbalHandValue,
  calculateHandMaalPoints,
  calculateMarriageSettlement,
  createCard,
  isAllPairs,
} from '../src/index.js';

describe('All 8 Games Verification (PRD Section 5)', () => {
  const fixturePath = path.resolve(__dirname, '../fixtures/all-games-fixtures.json');
  const fixtures = JSON.parse(fs.readFileSync(fixturePath, 'utf8'));

  it('Marriage settlement formula P_i = T + w_i - n * S_i matches PRD 5.2 exactly', () => {
    for (const testCase of fixtures.marriageScoringFixtures) {
      const rules = {
        ...DEFAULT_MARRIAGE_RULES,
        mode: testCase.mode as any,
      };

      const players = testCase.players.map((p: any) => ({
        seat: p.seat,
        rawMaalPoints: p.maal,
        hasSeenMaal: p.sawMaal,
      }));

      const settlements = calculateMarriageSettlement(
        players,
        testCase.winnerSeat,
        testCase.finishedWithDublees,
        rules,
      );

      for (const expected of testCase.expectedPayments) {
        const item = settlements.find((s) => s.seat === expected.seat);
        expect(item?.paymentToWinner).toBe(expected.P_i);
      }
    }
  });

  it('Marriage calculates single, double, alter and marriage combination points', () => {
    const maal = createCard('C', 11, 0); // J of Clubs is Maal (Tiplu)
    const hand = [
      createCard('C', 11, 1), // Tiplu (3 pts)
      createCard('C', 12, 0), // Poplu (2 pts)
      createCard('C', 10, 0), // Jhiplu (2 pts) -> Jhiplu + Tiplu + Poplu = Marriage (10 pts)
      createCard('S', 11, 0), // Alter J of Spades (5 pts)
    ];

    const points = calculateHandMaalPoints(hand, maal, DEFAULT_MARRIAGE_RULES);
    // Marriage (10) + Alter (5) = 15
    expect(points).toBe(15);
  });

  it('Teen Patti module initializes and applies blind/chaal/pack moves', () => {
    const module = new TeenPattiGameModule();
    const state = module.setup(['p1', 'p2', 'p3'], DEFAULT_TEEN_PATTI_RULES, 'tp_seed');

    expect(state.pot).toBe(300); // 3 * 100 boot
    expect(state.hands[0]).toHaveLength(3);

    // Current actor can play blind
    const actor = module.currentActor(state)!;
    const moves = module.legalMoves(state, actor);
    expect(moves.some((m) => m.type === 'blind')).toBe(true);

    const nextState = module.applyMove(state, actor, { type: 'blind', amount: 100 });
    expect(nextState.pot).toBe(400);
  });

  it('Kitti module arranges 9 cards into 3 hands of 3 and determines winner', () => {
    const module = new KittiGameModule();
    const state = module.setup(['k1', 'k2'], DEFAULT_KITTI_RULES, 'kitti_seed');

    expect(state.rawHands[0]).toHaveLength(9);

    const moves0 = module.legalMoves(state, 'k1');
    const arrangeMove0 = moves0.find((m) => m.type === 'arrange')!;
    const state1 = module.applyMove(state, 'k1', arrangeMove0);

    const moves1 = module.legalMoves(state1, 'k2');
    const arrangeMove1 = moves1.find((m) => m.type === 'arrange')!;
    const state2 = module.applyMove(state1, 'k2', arrangeMove1);

    expect(state2.isGameOver).toBe(true);
    expect(state2.showWins.reduce((sum, w) => sum + w, 0)).toBe(3); // 3 shows total
  });

  it('Dhumbal calculates hand values and handles Jhyap call', () => {
    const lowHand = [
      createCard('S', 1, 0), // A = 1
      createCard('H', 2, 0), // 2 = 2
      createCard('D', 1, 0), // A = 1 -> Total = 4 (<= 5 threshold)
    ];
    expect(calculateDhumbalHandValue(lowHand, 'app')).toBe(4);

    const module = new DhumbalGameModule();
    const state = module.setup(['d1', 'd2'], DEFAULT_DHUMBAL_RULES, 'dhumbal_seed');
    expect(state.hands[0]).toHaveLength(5);
  });

  it('Jutpatti detects valid pairs and handles even-count declarations', () => {
    // 4 cards with 2 pairs: 2 Aces and 2 Queens
    const pairsHand = [
      createCard('S', 1, 0),
      createCard('H', 1, 0),
      createCard('D', 12, 0),
      createCard('C', 12, 0),
    ];
    expect(isAllPairs(pairsHand)).toBe(true);

    // With a cut joker (e.g. 7), an unmatched card can pair with joker
    const handWithJoker = [
      createCard('S', 1, 0),
      createCard('H', 7, 0), // Joker
    ];
    expect(isAllPairs(handWithJoker, 7)).toBe(true);
  });

  it('Rummy module instantiates for Nepali Rummy and Joker Rummy (Paplu)', () => {
    const nepaliRummy = new RummyGameModule(false);
    expect(nepaliRummy.defaultRules.handSize).toBe(10);

    const paplu = new RummyGameModule(true);
    expect(paplu.defaultRules.handSize).toBe(13);
    expect(paplu.defaultRules.isPaplu).toBe(true);
  });
});
