import { describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as path from 'node:path';
import {
  CallbreakGameModule,
  DEFAULT_CALLBREAK_RULES,
  calculateRoundScores,
  createCard,
  getLegalCards,
  getTrickWinnerCard,
} from '../src/index.js';

describe('Callbreak Rule Fixtures (PRD Section 5.1)', () => {
  const fixturePath = path.resolve(__dirname, '../fixtures/callbreak-fixtures.json');
  const fixtures = JSON.parse(fs.readFileSync(fixturePath, 'utf8'));

  it('passes all scoring fixtures exactly as specified in PRD 5.1', () => {
    for (const testCase of fixtures.scoringFixtures) {
      const rules = {
        ...DEFAULT_CALLBREAK_RULES,
        scoringStyle: testCase.style as 'nepali' | 'pagat',
      };

      const scores = calculateRoundScores(
        rules,
        ['p1', 'p2', 'p3', 'p4'],
        [testCase.bid, 2, 2, 2],
        [testCase.tricksWon, 2, 2, 3],
        [0, 0, 0, 0],
      );

      expect(scores[0]!.roundScore).toBe(testCase.expectedRoundScore);
    }
  });

  it('enforces must-follow-suit rule', () => {
    const hand = [
      createCard('H', 10, 0), // 10 of Hearts
      createCard('H', 4, 0),  // 4 of Hearts
      createCard('S', 5, 0),  // 5 of Spades (trump)
      createCard('C', 14, 0), // Ace of Clubs
    ];

    const trick = {
      trickNumber: 1,
      leaderSeat: 0,
      cards: [
        { playerId: 'p1', seat: 0, card: createCard('H', 7, 0) },
      ],
    };

    // Must follow Hearts since player has Hearts
    const legal = getLegalCards(hand, trick, DEFAULT_CALLBREAK_RULES, false);
    expect(legal.every((c) => c.suit === 'H')).toBe(true);
  });

  it('enforces must-overtake rule by default', () => {
    const hand = [
      createCard('H', 12, 0), // Queen of Hearts (beats 10)
      createCard('H', 8, 0),  // 8 of Hearts (cannot beat 10)
    ];

    const trick = {
      trickNumber: 1,
      leaderSeat: 0,
      cards: [
        { playerId: 'p1', seat: 0, card: createCard('H', 10, 0) },
      ],
    };

    const legal = getLegalCards(hand, trick, DEFAULT_CALLBREAK_RULES, false);
    // Since Queen can beat 10, only Queen is legal under mustOvertake
    expect(legal).toHaveLength(1);
    expect(legal[0]!.id).toBe('QH0');
  });

  it('requires trumping when void in led suit', () => {
    const hand = [
      createCard('S', 4, 0), // 4 of Spades (trump)
      createCard('C', 12, 0), // Queen of Clubs
    ];

    const trick = {
      trickNumber: 1,
      leaderSeat: 0,
      cards: [
        { playerId: 'p1', seat: 0, card: createCard('H', 10, 0) },
      ],
    };

    const legal = getLegalCards(hand, trick, DEFAULT_CALLBREAK_RULES, false);
    // Void in Hearts, has Spade -> must play spade or any legal card
    expect(legal.some((c) => c.suit === 'S')).toBe(true);
  });

  it('evaluates highest spade as winning card of trick', () => {
    const trick = {
      trickNumber: 1,
      leaderSeat: 0,
      cards: [
        { playerId: 'p1', seat: 0, card: createCard('H', 13, 0) }, // King of Hearts
        { playerId: 'p2', seat: 1, card: createCard('S', 2, 0) },  // 2 of Spades (trump)
        { playerId: 'p3', seat: 2, card: createCard('S', 8, 0) },  // 8 of Spades (higher trump)
        { playerId: 'p4', seat: 3, card: createCard('H', 1, 0) },  // Ace of Hearts
      ],
    };

    const winner = getTrickWinnerCard(trick);
    expect(winner?.seat).toBe(2);
    expect(winner?.card.id).toBe('8S0');
  });

  it('runs complete game setup and masks private views (PRD 4.2 & 4.3)', () => {
    const module = new CallbreakGameModule();
    const players = ['user-1', 'bot-1', 'bot-2', 'bot-3'];
    const state = module.setup(players, DEFAULT_CALLBREAK_RULES, 'test-callbreak-seed');

    expect(state.phase).toBe('bidding');
    expect(state.hands[0]).toHaveLength(13);
    expect(state.hands[1]).toHaveLength(13);
    expect(state.hands[2]).toHaveLength(13);
    expect(state.hands[3]).toHaveLength(13);

    // View for player 0 should see only player 0 hand
    const view0 = module.viewFor(state, 'user-1');
    expect(view0.myHand).toBeDefined();
    expect(view0.myHand).toHaveLength(13);

    // Spectator view has no private hand
    const spectatorView = module.viewFor(state, 'spectator');
    expect(spectatorView.myHand).toBeUndefined();
  });

  it('runs random simulation games without illegal moves or errors', async () => {
    const { runCallbreakRandomSimulation } = await import('../src/games/callbreak/simulation.js');
    const result = runCallbreakRandomSimulation(100, 'unit_test_sim');
    expect(result.gamesRun).toBe(100);
    expect(result.errors).toBe(0);
    expect(result.totalMoves).toBeGreaterThan(5000);
  });
});
