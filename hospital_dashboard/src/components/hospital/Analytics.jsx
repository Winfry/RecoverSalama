/**
 * Analytics Dashboard (H6) — Phase 2
 *
 * Hospital-level analytics showing:
 * - Readmission rates over time
 * - Average recovery duration by surgery type
 * - Check-in compliance rates
 * - Risk level distribution across patients
 *
 * Uses Recharts for data visualization.
 */

export default function Analytics() {
  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">📈 Analytics</h1>
      <div className="bg-white rounded-xl border border-gray-200 p-10 text-center">
        <span className="text-4xl">📊</span>
        <p className="text-gray-500 mt-3 text-lg">Analytics Dashboard</p>
        <p className="text-gray-400 text-sm mt-1">
          Coming in Phase 2 — readmission rates, recovery trends, compliance metrics
        </p>
      </div>
    </div>
  );
}
