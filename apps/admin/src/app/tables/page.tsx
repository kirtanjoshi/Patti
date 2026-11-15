'use client';

import React, { useState } from 'react';

interface MockLiveTable {
  id: string;
  game: string;
  tier: string;
  seatsOccupied: number;
  totalSeats: number;
  round: number;
  status: 'PLAYING' | 'WAITING' | 'DEALING';
}

const INITIAL_TABLES: MockLiveTable[] = [
  { id: 'tbl_callbreak_01', game: 'Callbreak', tier: 'Silver (2,000)', seatsOccupied: 4, totalSeats: 4, round: 3, status: 'PLAYING' },
  { id: 'tbl_marriage_04', game: 'Marriage', tier: 'Gold (10,000)', seatsOccupied: 4, totalSeats: 4, round: 1, status: 'PLAYING' },
  { id: 'tbl_teenpatti_09', game: 'Teen Patti', tier: 'Bronze (500)', seatsOccupied: 5, totalSeats: 5, round: 4, status: 'PLAYING' },
  { id: 'tbl_kitti_02', game: 'Kitti', tier: 'Beginner (100)', seatsOccupied: 3, totalSeats: 4, round: 1, status: 'WAITING' },
];

export default function LiveTablesAdminPage() {
  const [tables, setTables] = useState<MockLiveTable[]>(INITIAL_TABLES);
  const [spectatorTable, setSpectatorTable] = useState<MockLiveTable | null>(null);

  const handleForceEnd = (tableId: string) => {
    setTables((prev) => prev.filter((t) => t.id !== tableId));
    if (spectatorTable?.id === tableId) setSpectatorTable(null);
  };

  return (
    <main className="p-8 max-w-7xl mx-auto">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-gray-900">Live Tables Monitor</h1>
          <p className="text-sm text-gray-500 mt-1">
            Real-time table states, admin spectator mode, and emergency force-end controls.
          </p>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200" aria-label="Live Active Tables">
          <thead className="bg-gray-50">
            <tr>
              <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Table ID
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Game / Tier
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Seats
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                State
              </th>
              <th scope="col" className="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Controls
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {tables.map((table) => (
              <tr key={table.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                  {table.id}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                  <span className="font-semibold text-gray-800">{table.game}</span> · {table.tier}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                  {table.seatsOccupied} / {table.totalSeats} seats
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                    {table.status} (Rnd {table.round})
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <button
                    onClick={() => setSpectatorTable(table)}
                    className="text-indigo-600 hover:text-indigo-900 mr-4 focus:ring-2 focus:ring-indigo-500 rounded px-2 py-1"
                    aria-label={`Open spectator view for ${table.id}`}
                  >
                    Spectate
                  </button>
                  <button
                    onClick={() => handleForceEnd(table.id)}
                    className="text-red-600 hover:text-red-900 focus:ring-2 focus:ring-red-500 rounded px-2 py-1"
                    aria-label={`Force end and refund table ${table.id}`}
                  >
                    Force End
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Spectator Modal */}
      {spectatorTable && (
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="spectator-headline"
          className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
        >
          <div className="bg-white rounded-lg max-w-xl w-full p-6 shadow-xl border border-gray-200">
            <div className="flex justify-between items-center pb-3 border-b">
              <h3 id="spectator-headline" className="text-lg font-bold text-gray-900">
                Spectator View: {spectatorTable.id} ({spectatorTable.game})
              </h3>
              <button
                onClick={() => setSpectatorTable(null)}
                className="text-gray-400 hover:text-gray-600 focus:ring-2 focus:ring-indigo-500 rounded"
                aria-label="Close spectator modal"
              >
                ✕
              </button>
            </div>
            <div className="mt-4 space-y-3">
              <div className="p-3 bg-gray-50 rounded-md border border-gray-200">
                <span className="text-xs font-semibold uppercase text-gray-500">Seat 0 (Lead)</span>
                <p className="text-sm font-mono mt-1 text-gray-800">A♠, Q♠, 7♠, K♥, 10♥, 5♥, A♦, 9♦, 3♦, J♣, 8♣, 6♣, 2♣</p>
              </div>
              <div className="p-3 bg-gray-50 rounded-md border border-gray-200">
                <span className="text-xs font-semibold uppercase text-gray-500">Seat 1 (Bot 1)</span>
                <p className="text-sm font-mono mt-1 text-gray-800">K♠, 10♠, 4♠, Q♥, 9♥, 6♥, K♦, 8♦, 2♦, Q♣, 9♣, 5♣, 3♣</p>
              </div>
              <div className="p-3 bg-gray-50 rounded-md border border-gray-200">
                <span className="text-xs font-semibold uppercase text-gray-500">Seat 2 (Bot 2)</span>
                <p className="text-sm font-mono mt-1 text-gray-800">J♠, 9♠, 6♠, A♥, J♥, 7♥, Q♦, 10♦, 4♦, A♣, 10♣, 7♣, 4♣</p>
              </div>
              <div className="p-3 bg-gray-50 rounded-md border border-gray-200">
                <span className="text-xs font-semibold uppercase text-gray-500">Seat 3 (Bot 3)</span>
                <p className="text-sm font-mono mt-1 text-gray-800">8♠, 5♠, 3♠, 2♠, 8♥, 3♥, 2♥, J♦, 7♦, 6♦, 5♦, K♣, 2♣</p>
              </div>
            </div>
            <div className="mt-6 flex justify-end">
              <button
                type="button"
                onClick={() => setSpectatorTable(null)}
                className="px-4 py-2 bg-gray-200 text-gray-800 rounded-md text-sm font-medium hover:bg-gray-300 focus:ring-2 focus:ring-gray-400"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
