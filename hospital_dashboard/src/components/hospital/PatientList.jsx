/**
 * Patient List (H3) — Table of all discharged patients.
 *
 * Columns: Name, Surgery, Day, Risk Level, Last Check-In, Actions
 * Sortable and searchable. Color-coded by risk level.
 * Clicking a patient opens PatientDetail.
 */

import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { getPatients } from '../../services/api';
import RiskBadge from '../common/RiskBadge';

export default function PatientList() {
  const hospitalId = localStorage.getItem('hospital_id') || undefined;

  const { data: patients, isLoading } = useQuery({
    queryKey: ['patients', hospitalId],
    queryFn: () => getPatients(hospitalId).then((r) => r.data),
  });

  if (isLoading) {
    return <div className="text-center py-10 text-gray-500">Loading patients...</div>;
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Patients</h1>
        <Link
          to="/discharge"
          className="px-4 py-2 bg-[#0077B6] text-white rounded-lg text-sm font-medium hover:bg-[#005a8d]"
        >
          + Discharge Patient
        </Link>
      </div>

      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Patient</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Surgery</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Day</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Risk</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {patients && patients.length > 0 ? (
              patients.map((patient) => (
                <tr key={patient.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <p className="font-medium text-sm">{patient.name}</p>
                    <p className="text-xs text-gray-500">{patient.phone}</p>
                  </td>
                  <td className="px-6 py-4 text-sm">{patient.surgery_type}</td>
                  <td className="px-6 py-4 text-sm">Day {patient.days_since_surgery || '—'}</td>
                  <td className="px-6 py-4"><RiskBadge level={patient.risk_level || 'LOW'} /></td>
                  <td className="px-6 py-4">
                    <Link
                      to={`/patients/${patient.id}`}
                      className="text-[#0077B6] text-sm font-medium hover:underline"
                    >
                      View Details
                    </Link>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={5} className="px-6 py-10 text-center text-gray-500">
                  No patients yet. Discharge a patient to get started.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
