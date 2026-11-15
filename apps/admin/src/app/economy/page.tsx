'use client';

import React, { useState } from 'react';

interface RemoteConfigState {
  rakePercentage: number;
  freeChestReward: number;
  rescueReward: number;
  botFillDelaySeconds: number;
  dailyStreaks: number[];
  tierStakes: {
    bronze: number;
    silver: number;
    gold: number;
    platinum: number;
  };
}

export default function EconomyConfigPage() {
  const [config, setConfig] = useState<RemoteConfigState>({
    rakePercentage: 5,
    freeChestReward: 200,
    rescueReward: 2000,
    botFillDelaySeconds: 8,
    dailyStreaks: [500, 750, 1000, 1250, 1500, 2000, 3000],
    tierStakes: {
      bronze: 100,
      silver: 500,
      gold: 2500,
      platinum: 10000,
    },
  });

  const [savedMessage, setSavedMessage] = useState<string | null>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Simulate updating RemoteConfig via admin API
    setSavedMessage('RemoteConfig successfully saved and propagated without deploy!');
    setTimeout(() => setSavedMessage(null), 4000);
  };

  return (
    <main className="p-8 max-w-5xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Economy & RemoteConfig</h1>
          <p className="text-sm text-gray-500 mt-1">
            Dynamic live configuration for rewards, rake percentage, tiers, and timers stored in RemoteConfig.
          </p>
        </div>
      </div>

      {savedMessage && (
        <div
          role="status"
          className="p-4 rounded-lg bg-green-50 border border-green-200 text-green-800 text-sm font-medium transition-all"
        >
          {savedMessage}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Core Economy Parameters */}
        <section aria-labelledby="core-econ-heading" className="bg-white rounded-lg border border-gray-200 p-6 shadow-sm">
          <h2 id="core-econ-heading" className="text-base font-semibold text-gray-900 mb-4 border-b pb-2">
            Core Economy Parameters
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div>
              <label htmlFor="rakePercentage" className="block text-sm font-medium text-gray-700 mb-1">
                House Rake (%)
              </label>
              <input
                id="rakePercentage"
                type="number"
                min="0"
                max="20"
                value={config.rakePercentage}
                onChange={(e) => setConfig({ ...config, rakePercentage: Number(e.target.value) })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                required
              />
              <span className="text-xs text-gray-500 mt-1 block">Default is 5% settled to HOUSE_RAKE</span>
            </div>

            <div>
              <label htmlFor="freeChestReward" className="block text-sm font-medium text-gray-700 mb-1">
                Free Chest Reward (Coins)
              </label>
              <input
                id="freeChestReward"
                type="number"
                min="0"
                value={config.freeChestReward}
                onChange={(e) => setConfig({ ...config, freeChestReward: Number(e.target.value) })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                required
              />
              <span className="text-xs text-gray-500 mt-1 block">Cooldown: 4 hours</span>
            </div>

            <div>
              <label htmlFor="rescueReward" className="block text-sm font-medium text-gray-700 mb-1">
                Bankrupt Rescue (Coins)
              </label>
              <input
                id="rescueReward"
                type="number"
                min="0"
                value={config.rescueReward}
                onChange={(e) => setConfig({ ...config, rescueReward: Number(e.target.value) })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                required
              />
              <span className="text-xs text-gray-500 mt-1 block">Granted if balance &lt; 100</span>
            </div>
          </div>
        </section>

        {/* 7-Day Streak Rewards */}
        <section aria-labelledby="streak-heading" className="bg-white rounded-lg border border-gray-200 p-6 shadow-sm">
          <h2 id="streak-heading" className="text-base font-semibold text-gray-900 mb-4 border-b pb-2">
            7-Day Streak Rewards Calendar
          </h2>
          <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-7 gap-3">
            {config.dailyStreaks.map((amount, idx) => (
              <div key={idx} className="flex flex-col">
                <label htmlFor={`day-${idx + 1}`} className="text-xs font-semibold text-gray-600 mb-1">
                  Day {idx + 1}
                </label>
                <input
                  id={`day-${idx + 1}`}
                  type="number"
                  min="0"
                  value={amount}
                  onChange={(e) => {
                    const newStreaks = [...config.dailyStreaks];
                    newStreaks[idx] = Number(e.target.value);
                    setConfig({ ...config, dailyStreaks: newStreaks });
                  }}
                  className="w-full px-2 py-1.5 border border-gray-300 rounded-md shadow-sm text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  required
                />
              </div>
            ))}
          </div>
        </section>

        {/* Tier Stakes */}
        <section aria-labelledby="tier-heading" className="bg-white rounded-lg border border-gray-200 p-6 shadow-sm">
          <h2 id="tier-heading" className="text-base font-semibold text-gray-900 mb-4 border-b pb-2">
            Lobby Quick Match Tier Stakes
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
            {(['bronze', 'silver', 'gold', 'platinum'] as const).map((tier) => (
              <div key={tier}>
                <label htmlFor={`tier-${tier}`} className="block text-sm font-medium text-gray-700 capitalize mb-1">
                  {tier} (Coins)
                </label>
                <input
                  id={`tier-${tier}`}
                  type="number"
                  min="1"
                  value={config.tierStakes[tier]}
                  onChange={(e) =>
                    setConfig({
                      ...config,
                      tierStakes: {
                        ...config.tierStakes,
                        [tier]: Number(e.target.value),
                      },
                    })
                  }
                  className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  required
                />
              </div>
            ))}
          </div>
        </section>

        {/* Save Changes */}
        <div className="flex justify-end pt-2">
          <button
            type="submit"
            className="px-6 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-medium rounded-md shadow focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Save & Publish Configuration
          </button>
        </div>
      </form>
    </main>
  );
}
