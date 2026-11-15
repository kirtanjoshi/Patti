'use client';

import React, { useState } from 'react';

interface MockUser {
  id: string;
  displayName: string;
  level: number;
  rating: number;
  balance: number;
  status: 'ACTIVE' | 'MUTED' | 'BANNED';
}

const INITIAL_USERS: MockUser[] = [
  { id: 'usr_101', displayName: 'Aayush Shrestha', level: 12, rating: 1450, balance: 45000, status: 'ACTIVE' },
  { id: 'usr_102', displayName: 'Pooja Thapa', level: 8, rating: 1320, balance: 18500, status: 'ACTIVE' },
  { id: 'usr_103', displayName: 'Suman Gurung', level: 3, rating: 1190, balance: 4200, status: 'ACTIVE' },
  { id: 'usr_104', displayName: 'Suspicious_Player', level: 1, rating: 1200, balance: 500, status: 'BANNED' },
];

export default function UsersAdminPage() {
  const [users, setUsers] = useState<MockUser[]>(INITIAL_USERS);
  const [selectedUser, setSelectedUser] = useState<MockUser | null>(null);
  const [adjustAmount, setAdjustAmount] = useState<number>(1000);
  const [reason, setReason] = useState<string>('');
  const [showModal, setShowModal] = useState<boolean>(false);

  const handleAdjustCoins = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser || !reason.trim()) return;

    setUsers((prev) =>
      prev.map((u) =>
        u.id === selectedUser.id ? { ...u, balance: Math.max(0, u.balance + adjustAmount) } : u,
      ),
    );
    setShowModal(false);
    setReason('');
  };

  const handleToggleBan = (userId: string) => {
    setUsers((prev) =>
      prev.map((u) =>
        u.id === userId
          ? { ...u, status: u.status === 'BANNED' ? 'ACTIVE' : 'BANNED' }
          : u,
      ),
    );
  };

  return (
    <main className="p-8 max-w-7xl mx-auto">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-gray-900">User Management</h1>
          <p className="text-sm text-gray-500 mt-1">
            Search, adjust wallet coins, inspect match history, and manage bans.
          </p>
        </div>
      </div>

      {/* Users Data Table */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200" aria-label="Registered Players Table">
          <thead className="bg-gray-50">
            <tr>
              <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                User
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Level / Rating
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Coin Balance
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th scope="col" className="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm font-medium text-gray-900">{user.displayName}</div>
                  <div className="text-xs text-gray-500">{user.id}</div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                  Lvl {user.level} · {user.rating} Elo
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-semibold text-gray-900">
                  {user.balance.toLocaleString()}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span
                    className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      user.status === 'ACTIVE'
                        ? 'bg-green-100 text-green-800'
                        : 'bg-red-100 text-red-800'
                    }`}
                  >
                    {user.status}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <button
                    onClick={() => {
                      setSelectedUser(user);
                      setShowModal(true);
                    }}
                    className="text-indigo-600 hover:text-indigo-900 mr-4 focus:ring-2 focus:ring-indigo-500 rounded px-2 py-1"
                    aria-label={`Adjust coins for ${user.displayName}`}
                  >
                    Adjust Coins
                  </button>
                  <button
                    onClick={() => handleToggleBan(user.id)}
                    className={`${
                      user.status === 'BANNED' ? 'text-green-600' : 'text-red-600'
                    } hover:underline focus:ring-2 focus:ring-red-500 rounded px-2 py-1`}
                    aria-label={`${user.status === 'BANNED' ? 'Unban' : 'Ban'} ${user.displayName}`}
                  >
                    {user.status === 'BANNED' ? 'Unban' : 'Ban'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Adjust Coins Modal */}
      {showModal && selectedUser && (
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="modal-headline"
          className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
        >
          <div className="bg-white rounded-lg max-w-md w-full p-6 shadow-xl border border-gray-200">
            <h3 id="modal-headline" className="text-lg font-bold text-gray-900">
              Adjust Coins: {selectedUser.displayName}
            </h3>
            <p className="text-xs text-gray-500 mt-1">
              Current Balance: {selectedUser.balance.toLocaleString()} coins
            </p>
            <form onSubmit={handleAdjustCoins} className="mt-4 space-y-4">
              <div>
                <label htmlFor="adjust-amount" className="block text-sm font-medium text-gray-700">
                  Adjustment Amount (+/-)
                </label>
                <input
                  id="adjust-amount"
                  type="number"
                  value={adjustAmount}
                  onChange={(e) => setAdjustAmount(parseInt(e.target.value, 10))}
                  required
                  className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label htmlFor="adjust-reason" className="block text-sm font-medium text-gray-700">
                  Reason (Strictly Required for AuditLog)
                </label>
                <textarea
                  id="adjust-reason"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  placeholder="e.g. Compensation for network disconnect on match tbl_98"
                  required
                  rows={3}
                  className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50 focus:ring-2 focus:ring-indigo-500"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={!reason.trim()}
                  className="px-4 py-2 bg-indigo-600 text-white rounded-md text-sm font-medium hover:bg-indigo-700 disabled:opacity-50 focus:ring-2 focus:ring-indigo-500"
                >
                  Apply & Log
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </main>
  );
}
