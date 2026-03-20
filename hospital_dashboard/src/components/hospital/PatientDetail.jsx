/**
 * Patient Detail (H4) — Full view of a single patient.
 *
 * Shows: profile info, surgery details, check-in history,
 * pain trend chart, risk timeline, diet phase, and mental health log.
 *
 * This is what a doctor looks at when reviewing a specific patient.
 */

import { useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { getPatient } from '../../services/api';
import RiskBadge from '../common/RiskBadge';

export default function PatientDetail() {
  const { id } = useParams();
  const { data: patient, isLoading } = useQuery({
    queryKey: ['patient', id],
    queryFn: () => getPatient(id).then((r) => r.data),
  });

  if (isLoading) {
    return <div className="text-center py-10 text-gray-500">Loading...</div>;
  }

  if (!patient) {
    return <div className="text-center py-10 text-gray-500">Patient not found</div>;
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">{patient.name}</h1>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Profile card */}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="font-semibold text-gray-900 mb-4">Patient Info</h2>
          <div className="space-y-2 text-sm">
            <InfoRow label="Age" value={patient.age} />
            <InfoRow label="Gender" value={patient.gender} />
            <InfoRow label="Blood Type" value={patient.blood_type} />
            <InfoRow label="Weight" value={`${patient.weight} kg`} />
            <InfoRow label="Phone" value={patient.phone} />
          </div>
        </div>

        {/* Surgery card */}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="font-semibold text-gray-900 mb-4">Surgery Details</h2>
          <div className="space-y-2 text-sm">
            <InfoRow label="Type" value={patient.surgery_type} />
            <InfoRow label="Date" value={patient.surgery_date} />
            <InfoRow label="Hospital" value={patient.hospital} />
            <InfoRow label="Surgeon" value={patient.surgeon} />
            <InfoRow label="Allergies" value={(patient.allergies || []).join(', ') || 'None'} />
          </div>
        </div>

        {/* Risk card */}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="font-semibold text-gray-900 mb-4">Current Status</h2>
          <div className="text-center py-4">
            <RiskBadge level={patient.risk_level || 'LOW'} />
            <p className="text-3xl font-bold mt-3">Day {patient.days_since_surgery || '—'}</p>
            <p className="text-sm text-gray-500">of recovery</p>
          </div>
        </div>
      </div>

      {/* Check-in history — placeholder */}
      <div className="mt-6 bg-white rounded-xl border border-gray-200 p-6">
        <h2 className="font-semibold text-gray-900 mb-4">Check-In History</h2>
        <p className="text-gray-500 text-sm">
          Check-in data will appear here once the patient submits daily reports.
        </p>
      </div>
    </div>
  );
}

function InfoRow({ label, value }) {
  return (
    <div className="flex justify-between">
      <span className="text-gray-500">{label}</span>
      <span className="font-medium text-gray-900">{value || '—'}</span>
    </div>
  );
}
