/**
 * Analytics Dashboard (H6) — Hospital-level insights.
 *
 * Four sections:
 * 1. Summary cards  — total patients, high risk, avg pain, compliance
 * 2. Risk distribution bar chart — how many patients at each risk level
 * 3. Pain trend line chart — 7-day daily averages across all patients
 * 4. Readmission risk table — top 5 patients by 30-day readmission probability
 */

import { useQuery } from '@tanstack/react-query';
import {
  BarChart, Bar, LineChart, Line,
  XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, Cell,
} from 'recharts';
import { getAnalytics } from '../../services/api';

// ── Colour maps ────────────────────────────────────────────────────────────
const RISK_BAR_COLORS = {
  LOW: '#22c55e',
  MEDIUM: '#f59e0b',
  HIGH: '#ef4444',
  EMERGENCY: '#7f1d1d',
};

const READMISSION_BADGE = {
  LOW:    'bg-green-100 text-green-700',
  MEDIUM: 'bg-amber-100 text-amber-700',
  HIGH:   'bg-red-100 text-red-700',
};

const PROB_BAR_COLOR = (prob) =>
  prob >= 0.6 ? '#ef4444' : prob >= 0.3 ? '#f59e0b' : '#22c55e';

// ── Custom tooltip for line chart ─────────────────────────────────────────
function PainTooltip({ active, payload, label }) {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-white border border-gray-200 rounded-lg px-3 py-2 shadow text-sm">
      <p className="font-semibold text-gray-700">{label}</p>
      {payload[0].value !== null ? (
        <p className="text-indigo-600">{payload[0].value}/10 avg pain</p>
      ) : (
        <p className="text-gray-400">No check-ins</p>
      )}
    </div>
  );
}

// ── Main component ─────────────────────────────────────────────────────────
export default function Analytics() {
  const { data, isLoading, error, dataUpdatedAt } = useQuery({
    queryKey: ['analytics'],
    queryFn: () => getAnalytics().then((r) => r.data),
    refetchInterval: 60_000,   // refresh every 60 s
  });

  if (isLoading) return <LoadingState />;
  if (error)     return <ErrorState message={error.message} />;

  const riskData = Object.entries(data.risk_breakdown).map(([level, count]) => ({
    level,
    count,
  }));

  const lastUpdated = new Date(dataUpdatedAt).toLocaleTimeString('en-KE', {
    hour: '2-digit',
    minute: '2-digit',
  });

  return (
    <div>
      {/* ── Header ── */}
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">📈 Analytics</h1>
        <p className="text-xs text-gray-400">Last updated {lastUpdated} · refreshes every minute</p>
      </div>

      {/* ── 1. Summary cards ── */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <StatCard
          icon="👥"
          title="Total Patients"
          value={data.total_patients}
        />
        <StatCard
          icon="🔴"
          title="High / Emergency"
          value={data.high_risk_count}
          color="text-red-600"
          highlight={data.high_risk_count > 0}
        />
        <StatCard
          icon="📊"
          title="Avg Pain This Week"
          value={data.avg_pain_this_week > 0 ? `${data.avg_pain_this_week}/10` : '—'}
          color={data.avg_pain_this_week >= 6 ? 'text-red-600' : 'text-amber-600'}
        />
        <StatCard
          icon="✅"
          title="Checked In Today"
          value={`${data.compliance_rate}%`}
          subtitle={`${data.checkins_today} of ${data.total_patients} patients`}
          color={data.compliance_rate >= 70 ? 'text-green-600' : 'text-amber-600'}
        />
      </div>

      {/* ── 2. Charts row ── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* Risk distribution */}
        <ChartCard
          title="Risk Distribution"
          subtitle="Current risk level of each patient (latest check-in)"
        >
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={riskData} margin={{ top: 5, right: 10, bottom: 5, left: -20 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
              <XAxis dataKey="level" tick={{ fontSize: 12, fill: '#6b7280' }} />
              <YAxis allowDecimals={false} tick={{ fontSize: 12, fill: '#6b7280' }} />
              <Tooltip
                formatter={(v) => [v, 'Patients']}
                contentStyle={{ borderRadius: 8, border: '1px solid #e5e7eb', fontSize: 13 }}
              />
              <Bar dataKey="count" radius={[6, 6, 0, 0]}>
                {riskData.map((entry) => (
                  <Cell key={entry.level} fill={RISK_BAR_COLORS[entry.level]} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>

        {/* Pain trend */}
        <ChartCard
          title="Average Pain — Last 7 Days"
          subtitle="Daily average across all patients (scale 0–10)"
        >
          <ResponsiveContainer width="100%" height={220}>
            <LineChart
              data={data.pain_trend}
              margin={{ top: 5, right: 10, bottom: 5, left: -20 }}
            >
              <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
              <XAxis dataKey="day" tick={{ fontSize: 12, fill: '#6b7280' }} />
              <YAxis domain={[0, 10]} tick={{ fontSize: 12, fill: '#6b7280' }} />
              <Tooltip content={<PainTooltip />} />
              <Line
                type="monotone"
                dataKey="avg_pain"
                stroke="#6366f1"
                strokeWidth={2.5}
                dot={{ r: 4, fill: '#6366f1', strokeWidth: 0 }}
                activeDot={{ r: 6 }}
                connectNulls={false}
              />
            </LineChart>
          </ResponsiveContainer>
        </ChartCard>
      </div>

      {/* ── 3. Readmission risk table ── */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <div className="mb-5">
          <h2 className="text-lg font-semibold text-gray-900">⚠️ 30-Day Readmission Risk</h2>
          <p className="text-sm text-gray-400 mt-1">
            Patients most likely to return to hospital — ranked by AI prediction score.
            Call or visit HIGH-risk patients within 48 hours.
          </p>
        </div>

        {data.readmission_risks?.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-gray-500 border-b border-gray-100">
                  <th className="pb-3 font-medium pr-4">Patient</th>
                  <th className="pb-3 font-medium pr-4">Surgery</th>
                  <th className="pb-3 font-medium pr-4">Recovery Day</th>
                  <th className="pb-3 font-medium pr-4">Risk Level</th>
                  <th className="pb-3 font-medium">30-Day Probability</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {data.readmission_risks.map((p, i) => (
                  <tr key={p.patient_id} className="hover:bg-gray-50 transition-colors">
                    <td className="py-3 pr-4">
                      <div className="flex items-center gap-2">
                        {i === 0 && p.risk_category === 'HIGH' && (
                          <span className="text-red-500 text-xs font-bold">TOP</span>
                        )}
                        <span className="font-medium text-gray-900">{p.patient_name}</span>
                      </div>
                    </td>
                    <td className="py-3 pr-4 text-gray-500 text-xs">
                      {p.surgery_type || '—'}
                    </td>
                    <td className="py-3 pr-4 text-gray-500">
                      Day {p.days_since_surgery}
                    </td>
                    <td className="py-3 pr-4">
                      <span
                        className={`px-2 py-1 rounded-full text-xs font-semibold ${
                          READMISSION_BADGE[p.risk_category] ?? 'bg-gray-100 text-gray-600'
                        }`}
                      >
                        {p.risk_category}
                      </span>
                    </td>
                    <td className="py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-28 bg-gray-100 rounded-full h-2 overflow-hidden">
                          <div
                            className="h-2 rounded-full transition-all duration-500"
                            style={{
                              width: `${Math.round(p.probability * 100)}%`,
                              backgroundColor: PROB_BAR_COLOR(p.probability),
                            }}
                          />
                        </div>
                        <span className="text-gray-700 font-medium tabular-nums w-9">
                          {Math.round(p.probability * 100)}%
                        </span>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="text-center py-12 text-gray-400">
            <p className="text-3xl mb-2">📭</p>
            <p>No patient data yet — check-in data will appear here once patients start using the app.</p>
          </div>
        )}

        {/* Legend */}
        <div className="mt-5 pt-4 border-t border-gray-100 flex flex-wrap gap-4 text-xs text-gray-500">
          <span className="flex items-center gap-1">
            <span className="w-2 h-2 rounded-full bg-green-500 inline-block" /> LOW — routine monitoring
          </span>
          <span className="flex items-center gap-1">
            <span className="w-2 h-2 rounded-full bg-amber-500 inline-block" /> MEDIUM — follow up in 3–5 days
          </span>
          <span className="flex items-center gap-1">
            <span className="w-2 h-2 rounded-full bg-red-500 inline-block" /> HIGH — call or visit within 48 hrs
          </span>
        </div>
      </div>
    </div>
  );
}

// ── Sub-components ─────────────────────────────────────────────────────────

function StatCard({ icon, title, value, subtitle, color = 'text-gray-900', highlight = false }) {
  return (
    <div
      className={`bg-white rounded-xl border p-5 transition-shadow ${
        highlight ? 'border-red-300 shadow-sm shadow-red-100' : 'border-gray-200'
      }`}
    >
      <span className="text-2xl">{icon}</span>
      <p className={`text-3xl font-bold mt-2 ${color}`}>{value}</p>
      <p className="text-sm text-gray-500 mt-1">{title}</p>
      {subtitle && <p className="text-xs text-gray-400 mt-0.5">{subtitle}</p>}
    </div>
  );
}

function ChartCard({ title, subtitle, children }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-6">
      <h2 className="text-base font-semibold text-gray-900">{title}</h2>
      {subtitle && <p className="text-xs text-gray-400 mt-1 mb-4">{subtitle}</p>}
      <div className="mt-3">{children}</div>
    </div>
  );
}

function LoadingState() {
  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">📈 Analytics</h1>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="bg-white rounded-xl border border-gray-200 p-5 animate-pulse">
            <div className="h-6 w-6 bg-gray-200 rounded mb-3" />
            <div className="h-8 bg-gray-200 rounded mb-2" />
            <div className="h-4 bg-gray-100 rounded w-2/3" />
          </div>
        ))}
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {[1, 2].map((i) => (
          <div key={i} className="bg-white rounded-xl border border-gray-200 p-6 animate-pulse h-64" />
        ))}
      </div>
      <div className="bg-white rounded-xl border border-gray-200 p-6 animate-pulse h-48" />
    </div>
  );
}

function ErrorState({ message }) {
  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">📈 Analytics</h1>
      <div className="bg-red-50 border border-red-200 rounded-xl p-8 text-center">
        <p className="text-3xl mb-3">⚠️</p>
        <p className="text-red-700 font-semibold">Could not load analytics</p>
        <p className="text-red-500 text-sm mt-1">{message}</p>
        <p className="text-gray-500 text-xs mt-3">
          Make sure the backend server is running and you are connected.
        </p>
      </div>
    </div>
  );
}
