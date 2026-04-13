/**
 * Patient Detail (H4) — Full view of a single patient.
 *
 * Shows: profile, surgery details, discharge status, check-in history,
 * and a Discharge Patient button for patients not yet discharged.
 */

import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { getPatient, getPatientHistory } from '../../services/api';
import RiskBadge from '../common/RiskBadge';

export default function PatientDetail() {
  const { id } = useParams();
  const navigate = useNavigate();

  const { data: patient, isLoading } = useQuery({
    queryKey: ['patient', id],
    queryFn: () => getPatient(id).then((r) => r.data),
  });

  const { data: history = [] } = useQuery({
    queryKey: ['patient-history', id],
    queryFn: () => getPatientHistory(id).then((r) => r.data),
    enabled: !!id,
  });

  if (isLoading) {
    return <div className="text-center py-10 text-gray-500">Loading...</div>;
  }

  if (!patient) {
    return <div className="text-center py-10 text-gray-500">Patient not found</div>;
  }

  return (
    <div>
      {/* Header with name and discharge button */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <button
            onClick={() => navigate('/patients')}
            className="text-sm text-gray-400 hover:text-gray-600 mb-1 block transition-colors"
          >
            ← All Patients
          </button>
          <h1 className="text-2xl font-bold text-gray-900">{patient.name}</h1>
        </div>

        {patient.is_discharged ? (
          <div className="text-right">
            <span className="inline-flex items-center gap-1 px-3 py-1 bg-green-100 text-green-700 rounded-full text-sm font-semibold">
              ✅ Discharged
            </span>
            <p className="text-xs text-gray-400 mt-1">
              {patient.discharge_date} · Dr. {patient.assigned_doctor}
            </p>
          </div>
        ) : (
          <button
            onClick={() => navigate(`/patients/${id}/discharge`)}
            className="px-5 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors flex items-center gap-2"
          >
            📋 Discharge Patient
          </button>
        )}
      </div>

      {/* Top 3 cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Profile card */}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="font-semibold text-gray-900 mb-4">Patient Info</h2>
          <div className="space-y-2 text-sm">
            <InfoRow label="Age" value={patient.age} />
            <InfoRow label="Gender" value={patient.gender} />
            <InfoRow label="Blood Type" value={patient.blood_type} />
            <InfoRow label="Weight" value={patient.weight ? `${patient.weight} kg` : null} />
            <InfoRow label="Phone" value={patient.phone} />
          </div>
        </div>

        {/* Surgery card */}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="font-semibold text-gray-900 mb-4">Surgery Details</h2>
          <div className="space-y-2 text-sm">
            <InfoRow label="Type" value={patient.surgery_type} />
            <InfoRow label="Surgery Date" value={patient.surgery_date} />
            <InfoRow label="Discharge Date" value={patient.discharge_date} />
            <InfoRow label="Hospital" value={patient.hospital} />
            <InfoRow label="Surgeon" value={patient.surgeon} />
            <InfoRow
              label="Allergies"
              value={(patient.allergies || []).join(', ') || 'None'}
            />
          </div>
        </div>

        {/* Status card */}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="font-semibold text-gray-900 mb-4">Current Status</h2>
          <div className="text-center py-2">
            <RiskBadge level={history[0]?.risk_level || 'LOW'} />
            <p className="text-3xl font-bold mt-3">
              Day {history[0]?.days_since_surgery || '—'}
            </p>
            <p className="text-sm text-gray-500">of recovery</p>
            {history.length > 0 && (
              <p className="text-xs text-gray-400 mt-2">
                Last check-in: {new Date(history[0].created_at).toLocaleDateString()}
              </p>
            )}
          </div>
        </div>
      </div>

      {/* Discharge notes (shown if discharged) */}
      {patient.is_discharged && patient.discharge_notes && (
        <div className="mt-6 bg-blue-50 border border-blue-200 rounded-xl p-5">
          <p className="text-sm font-semibold text-blue-800 mb-2">
            📋 Discharge Instructions — Dr. {patient.assigned_doctor}
          </p>
          <p className="text-sm text-blue-700 whitespace-pre-line leading-relaxed">
            {patient.discharge_notes}
          </p>
        </div>
      )}

      {/* Check-in history */}
      <div className="mt-6 bg-white rounded-xl border border-gray-200 p-6">
        <h2 className="font-semibold text-gray-900 mb-4">
          Check-In History
          {history.length > 0 && (
            <span className="ml-2 text-sm font-normal text-gray-400">
              ({history.length} records)
            </span>
          )}
        </h2>

        {history.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-gray-500 border-b border-gray-100">
                  <th className="pb-3 font-medium pr-4">Date</th>
                  <th className="pb-3 font-medium pr-4">Day</th>
                  <th className="pb-3 font-medium pr-4">Pain</th>
                  <th className="pb-3 font-medium pr-4">Mood</th>
                  <th className="pb-3 font-medium pr-4">Symptoms</th>
                  <th className="pb-3 font-medium">Risk</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {history.map((log, i) => (
                  <tr key={i} className="hover:bg-gray-50 transition-colors">
                    <td className="py-2 pr-4 text-gray-500 tabular-nums">
                      {new Date(log.created_at).toLocaleDateString('en-KE', {
                        day: '2-digit', month: 'short',
                      })}
                    </td>
                    <td className="py-2 pr-4 text-gray-500">
                      Day {log.days_since_surgery}
                    </td>
                    <td className="py-2 pr-4">
                      <PainPill level={log.pain_level} />
                    </td>
                    <td className="py-2 pr-4 text-gray-600">
                      {log.mood || '—'}
                    </td>
                    <td className="py-2 pr-4 text-gray-500 text-xs max-w-xs truncate">
                      {(log.symptoms || []).join(', ') || 'None'}
                    </td>
                    <td className="py-2">
                      <RiskBadge level={log.risk_level} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="text-center py-8 text-gray-400">
            <p className="text-2xl mb-2">📭</p>
            <p className="text-sm">
              No check-ins yet.
              {!patient.is_discharged && ' Discharge the patient first to start the recovery countdown.'}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Sub-components ──────────────────────────────────────────────────────────

function InfoRow({ label, value }) {
  return (
    <div className="flex justify-between">
      <span className="text-gray-500">{label}</span>
      <span className="font-medium text-gray-900">{value || '—'}</span>
    </div>
  );
}

function PainPill({ level }) {
  if (level == null) return <span className="text-gray-400">—</span>;
  const color =
    level >= 7 ? 'bg-red-100 text-red-700' :
    level >= 4 ? 'bg-amber-100 text-amber-700' :
    'bg-green-100 text-green-700';
  return (
    <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${color}`}>
      {level}/10
    </span>
  );
}
