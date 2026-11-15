export default function AdminDashboardPage() {
  return (
    <main className="p-8 max-w-7xl mx-auto">
      <h1 className="text-3xl font-bold tracking-tight text-gray-900">
        Patii Admin Dashboard
      </h1>
      <p className="mt-2 text-sm text-gray-600">
        Live table management, economy tracking, fraud detection, and player support.
      </p>
      <div className="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-sm font-medium text-gray-500">Live Tables</h2>
          <p className="mt-2 text-3xl font-bold text-gray-900">0</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-sm font-medium text-gray-500">Online Players</h2>
          <p className="mt-2 text-3xl font-bold text-gray-900">0</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-sm font-medium text-gray-500">24h Pot Volume</h2>
          <p className="mt-2 text-3xl font-bold text-gray-900">0</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-sm font-medium text-gray-500">System Status</h2>
          <p className="mt-2 text-3xl font-bold text-green-600">Healthy</p>
        </div>
      </div>
    </main>
  );
}
