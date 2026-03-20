/**
 * Alert Centre (H5) — Real-time alert dashboard for hospital staff.
 *
 * When the ML risk classifier flags a patient as HIGH or EMERGENCY,
 * an alert appears here instantly (via Supabase Realtime).
 *
 * Staff can:
 * - See all active alerts sorted by severity
 * - Click to view patient details
 * - Acknowledge alerts (mark as reviewed)
 * - Resolve alerts (mark as handled)
 *
 * This is the most critical screen — it saves lives by ensuring
 * hospitals know when a discharged patient is in trouble.
 */

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { getAlerts, updateAlert } from '../../services/api';
import RiskBadge from '../common/RiskBadge';

export default function AlertCentre() {
  const queryClient = useQueryClient();

  const { data: alerts, isLoading } = useQuery({
    queryKey: ['alerts'],
    queryFn: () => getAlerts().then((r) => r.data),
    refetchInterval: 30000, // Poll every 30s as backup to realtime
  });

  const acknowledgeMutation = useMutation({
    mutationFn: (alertId) => updateAlert(alertId, 'acknowledged'),
    onSuccess: () => queryClient.invalidateQueries(['alerts']),
  });

  const resolveMutation = useMutation({
    mutationFn: (alertId) => updateAlert(alertId, 'resolved'),
    onSuccess: () => queryClient.invalidateQueries(['alerts']),
  });

  if (isLoading) {
    return <div className="text-center py-10 text-gray-500">Loading alerts...</div>;
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">
        🚨 Alert Centre
      </h1>

      {alerts && alerts.length > 0 ? (
        <div className="space-y-4">
          {alerts.map((alert) => (
            <div
              key={alert.id}
              className={`bg-white rounded-xl border p-5 ${
                alert.risk_level === 'EMERGENCY'
                  ? 'border-red-300 bg-red-50'
                  : alert.risk_level === 'HIGH'
                  ? 'border-red-200'
                  : 'border-gray-200'
              }`}
            >
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-3 mb-2">
                    <RiskBadge level={alert.risk_level} />
                    <span className="text-xs text-gray-500">
                      {new Date(alert.created_at).toLocaleString()}
                    </span>
                  </div>
                  <p className="font-medium">{alert.message}</p>
                  <p className="text-sm text-gray-500 mt-1">
                    Symptoms: {(alert.symptoms || []).join(', ')}
                  </p>
                </div>

                <div className="flex gap-2">
                  <Link
                    to={`/patients/${alert.patient_id}`}
                    className="px-3 py-1.5 text-xs font-medium text-[#0077B6] border border-[#0077B6] rounded-lg hover:bg-blue-50"
                  >
                    View Patient
                  </Link>
                  <button
                    onClick={() => acknowledgeMutation.mutate(alert.id)}
                    className="px-3 py-1.5 text-xs font-medium text-amber-700 border border-amber-300 rounded-lg hover:bg-amber-50"
                  >
                    Acknowledge
                  </button>
                  <button
                    onClick={() => resolveMutation.mutate(alert.id)}
                    className="px-3 py-1.5 text-xs font-medium text-green-700 border border-green-300 rounded-lg hover:bg-green-50"
                  >
                    Resolve
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 p-10 text-center">
          <span className="text-4xl">✅</span>
          <p className="text-gray-500 mt-2">No active alerts — all patients stable</p>
        </div>
      )}
    </div>
  );
}
