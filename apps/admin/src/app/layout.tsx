import type { Metadata } from 'next';
import Link from 'next/link';
import './globals.css';

export const metadata: Metadata = {
  title: 'Patii Admin Panel',
  description: 'Operations, live table monitoring, and economy management for Patii',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased bg-gray-50 text-gray-900 min-h-screen flex">
        {/* Accessible Admin Sidebar */}
        <nav
          aria-label="Admin Navigation"
          className="w-64 bg-slate-900 text-white flex flex-col justify-between p-4 shrink-0"
        >
          <div>
            <div className="flex items-center gap-3 px-2 py-4">
              <span className="text-xl font-bold tracking-tight text-white">
                Patii Admin
              </span>
            </div>
            <div className="mt-6 flex flex-col gap-1">
              <Link
                href="/"
                className="px-3 py-2 rounded-md text-sm font-medium hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 text-slate-200"
              >
                Dashboard
              </Link>
              <Link
                href="/users"
                className="px-3 py-2 rounded-md text-sm font-medium hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 text-slate-200"
              >
                Users & Wallets
              </Link>
              <Link
                href="/tables"
                className="px-3 py-2 rounded-md text-sm font-medium hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 text-slate-200"
              >
                Live Tables
              </Link>
              <Link
                href="/economy"
                className="px-3 py-2 rounded-md text-sm font-medium hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 text-slate-200"
              >
                Economy & Config
              </Link>
              <Link
                href="/audit"
                className="px-3 py-2 rounded-md text-sm font-medium hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 text-slate-200"
              >
                Audit Log
              </Link>
            </div>
          </div>
          <div className="px-2 py-4 text-xs text-slate-400 border-t border-slate-800">
            Role: <span className="font-semibold text-white">Owner</span>
          </div>
        </nav>

        {/* Main Content Area */}
        <div className="flex-1 flex flex-col min-w-0">
          <header className="h-16 border-b border-gray-200 bg-white flex items-center justify-between px-8">
            <h2 className="text-lg font-semibold text-gray-800">Operational Console</h2>
            <div className="flex items-center gap-3">
              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                Server Online
              </span>
            </div>
          </header>
          <div className="flex-1 overflow-auto">{children}</div>
        </div>
      </body>
    </html>
  );
}
