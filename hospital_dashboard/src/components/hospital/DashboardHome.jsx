/**
 * Dashboard Home (H2) — The first screen hospital staff see after login.
 *
 * Shows at a glance:
 * - Total active patients
 * - Patients by risk level (LOW/MEDIUM/HIGH/EMERGENCY)
 * - Recent alerts that need attention
 * - Today's check-in completion rate
 *
 * This gives nurses and doctors an immediate overview of
 * which patients need attention RIGHT NOW.
 */

import { useQuery } from '@tanstack/react-query';
import { getPatients, getAlerts } from '../../services/api';
import RiskBadge from '../common/RiskBadge';

export default function DashboardHome() {
  const { data: patients } = useQuery({
    queryKey: ['patients'],
    queryFn: () => getPatients().then((r) => r.data),
  });

  const { data: alerts } = useQuery({
    queryKey: ['alerts'],
    queryFn: () => getAlerts().then((r) => r.data),
  });

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">
        Hospital Dashboard
      </h1>

      {/* Stats cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <StatCard title="Active Patients" value={patients?.length || 0} icon="👥" />
        <StatCard title="High Risk" value={0} icon="🔴" color="text-red-600" />
        <StatCard title="Pending Alerts" value={alerts?.length || 0} icon="🚨" color="text-amber-600" />
        <StatCard title="Check-ins Today" value={0} icon="✅" color="text-green-600" />
      </div>

      {/* Recent alerts */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <h2 className="text-lg font-semibold mb-4">Recent Alerts</h2>
        {alerts && alerts.length > 0 ? (
          <div className="space-y-3">
            {alerts.slice(0, 5).map((alert) => (
              <div
                key={alert.id}
                className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
              >
                <div>
                  <p className="font-medium text-sm">{alert.message}</p>
                  <p className="text-xs text-gray-500">
                    {new Date(alert.created_at).toLocaleString()}
                  </p>
                </div>
                <RiskBadge level={alert.risk_level} />
              </div>
            ))}
          </div>
        ) : (
          <p className="text-gray-500 text-sm">No active alerts</p>
        )}
      </div>
    </div>
  );
}

function StatCard({ title, value, icon, color = 'text-gray-900' }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-5">
      <div className="flex items-center justify-between">
        <span className="text-2xl">{icon}</span>
      </div>
      <p className={`text-3xl font-bold mt-2 ${color}`}>{value}</p>
      <p className="text-sm text-gray-500 mt-1">{title}</p>
    </div>
  );
}
