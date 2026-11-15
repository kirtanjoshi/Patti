'use client';

import React, { useState } from 'react';

interface AuditRecord {
  id: string;
  adminId: string;
  action: string;
  target: string;
  reason?: string;
  createdAt: string;
}

const mockAuditLogs: AuditRecord[] = [
  {
    id: 'aud_1',
    adminId: 'admin_owner_1',
    action: 'ADJUST_COINS',
    target: 'usr_201',
    reason: 'Compensating disconnected tournament match #304',
    createdAt: '2026-11-15T18:40:00Z',
  },
  {
    id: 'aud_2',
    adminId: 'admin_mod_2',
    action: 'BAN_USER',
    target: 'usr_402',
    reason: 'Repeated toxic chat and intentional stalling',
    createdAt: '2026-11-15T17:15:20Z',
  },
  {
    id: 'aud_3',
    adminId: 'admin_owner_1',
    action: 'FORCE_END_TABLE',
    target: 'tbl_callbreak_99',
    reason: 'Server maintenance restart',
    createdAt: '2026-11-15T16:00:00Z',
  },
  {
    id: 'aud_4',
    adminId: 'admin_support_3',
    action: 'ADJUST_COINS',
    target: 'usr_888',
    reason: 'Free chest claim timeout error compensation',
    createdAt: '2026-11-15T14:22:10Z',
  },
];

export default function AuditLogPage() {
  const [filterAction, setFilterAction] = useState<string>('ALL');
  const [searchTarget, setSearchTarget] = useState<string>('');

  const filteredLogs = mockAuditLogs.filter((log) => {
    if (filterAction !== 'ALL' && log.action !== filterAction) return false;
    if (searchTarget && !log.target.toLowerCase().includes(searchTarget.toLowerCase())) return false;
    return true;
  });

  return (
    <main className="p-8 max-w-6xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Audit Log</h1>
        <p className="text-sm text-gray-500 mt-1">
          Immutable historical log of all administrative interventions, coin grants, and moderation actions.
        </p>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4 items-center justify-between bg-white p-4 rounded-lg border border-gray-200 shadow-sm">
        <div className="flex items-center gap-3 w-full sm:w-auto">
          <label htmlFor="actionFilter" className="text-sm font-medium text-gray-700 whitespace-nowrap">
            Filter Action:
          </label>
          <select
            id="actionFilter"
            value={filterAction}
            onChange={(e) => setFilterAction(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md shadow-sm text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="ALL">All Actions</option>
            <option value="ADJUST_COINS">ADJUST_COINS</option>
            <option value="BAN_USER">BAN_USER</option>
            <option value="FORCE_END_TABLE">FORCE_END_TABLE</option>
          </select>
        </div>

        <div className="flex items-center gap-2 w-full sm:w-64">
          <label htmlFor="searchTarget" className="sr-only">
            Search Target
          </label>
          <input
            id="searchTarget"
            type="text"
            placeholder="Search target user / table..."
            value={searchTarget}
            onChange={(e) => setSearchTarget(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>
      </div>

      {/* Audit Log Table */}
      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden shadow-sm">
        <table className="min-w-full divide-y divide-gray-200 text-left text-sm">
          <thead className="bg-gray-50">
            <tr>
              <th scope="col" className="px-6 py-3 font-semibold text-gray-700">Timestamp</th>
              <th scope="col" className="px-6 py-3 font-semibold text-gray-700">Admin ID</th>
              <th scope="col" className="px-6 py-3 font-semibold text-gray-700">Action</th>
              <th scope="col" className="px-6 py-3 font-semibold text-gray-700">Target</th>
              <th scope="col" className="px-6 py-3 font-semibold text-gray-700">Reason / Notes</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {filteredLogs.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                  No audit logs matching query.
                </td>
              </tr>
            ) : (
              filteredLogs.map((log) => (
                <tr key={log.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-xs text-gray-500 font-mono">
                    {new Date(log.createdAt).toLocaleString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap font-medium text-gray-900">
                    {log.adminId}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`inline-flex px-2 py-0.5 rounded text-xs font-semibold ${
                        log.action === 'ADJUST_COINS'
                          ? 'bg-amber-100 text-amber-800'
                          : log.action === 'BAN_USER'
                          ? 'bg-red-100 text-red-800'
                          : 'bg-indigo-100 text-indigo-800'
                      }`}
                    >
                      {log.action}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-700">
                    {log.target}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {log.reason ?? '—'}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </main>
  );
}
