/**
 * Discharge Form (H7) — Record a patient's discharge from hospital.
 *
 * Reached from: PatientDetail → "Discharge Patient" button
 * Route: /patients/:id/discharge
 *
 * What it does:
 * 1. Shows patient name and surgery at the top (read-only)
 * 2. Doctor fills in: discharge date, their name, and recovery instructions
 * 3. On submit → updates DB + sends WhatsApp to patient
 * 4. Success screen confirms discharge was recorded
 */

import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getPatient, dischargePatient } from '../../services/api';

export default function DischargeForm() {
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const today = new Date().toISOString().split('T')[0]; // "YYYY-MM-DD"

  const [form, setForm] = useState({
    discharge_date: today,
    assigned_doctor: '',
    discharge_notes: '',
  });

  const [submitted, setSubmitted] = useState(false);

  // Load patient info to show at top of form
  const { data: patient, isLoading: patientLoading } = useQuery({
    queryKey: ['patient', id],
    queryFn: () => getPatient(id).then((r) => r.data),
  });

  // Discharge mutation
  const discharge = useMutation({
    mutationFn: () => dischargePatient(id, form),
    onSuccess: () => {
      // Invalidate cached patient data so PatientDetail refreshes
      queryClient.invalidateQueries({ queryKey: ['patient', id] });
      queryClient.invalidateQueries({ queryKey: ['patients'] });
      queryClient.invalidateQueries({ queryKey: ['analytics'] });
      setSubmitted(true);
    },
  });

  const handleChange = (e) => {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!form.assigned_doctor.trim()) return;
    discharge.mutate();
  };

  // ── Loading state ──
  if (patientLoading) {
    return (
      <div className="max-w-2xl mx-auto">
        <div className="bg-white rounded-xl border border-gray-200 p-10 text-center animate-pulse">
          <div className="h-6 bg-gray-200 rounded w-1/2 mx-auto mb-3" />
          <div className="h-4 bg-gray-100 rounded w-1/3 mx-auto" />
        </div>
      </div>
    );
  }

  // ── Already discharged ──
  if (patient?.is_discharged && !submitted) {
    return (
      <div className="max-w-2xl mx-auto">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">Discharge Patient</h1>
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-8 text-center">
          <p className="text-3xl mb-3">⚠️</p>
          <p className="text-amber-800 font-semibold text-lg">Already Discharged</p>
          <p className="text-amber-600 text-sm mt-2">
            {patient.name} was discharged on{' '}
            <strong>{patient.discharge_date}</strong> by Dr. {patient.assigned_doctor}.
          </p>
          <button
            onClick={() => navigate(`/patients/${id}`)}
            className="mt-6 px-5 py-2 bg-amber-600 text-white rounded-lg text-sm font-medium hover:bg-amber-700 transition-colors"
          >
            ← Back to Patient
          </button>
        </div>
      </div>
    );
  }

  // ── Success screen ──
  if (submitted) {
    return (
      <div className="max-w-2xl mx-auto">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">Discharge Patient</h1>
        <div className="bg-green-50 border border-green-200 rounded-xl p-10 text-center">
          <p className="text-5xl mb-4">✅</p>
          <p className="text-green-800 font-bold text-xl">Discharge Recorded</p>
          <p className="text-green-700 mt-2">
            <strong>{patient?.name}</strong> has been successfully discharged.
          </p>
          <div className="mt-4 text-sm text-green-600 space-y-1">
            <p>📅 Discharge date: <strong>{form.discharge_date}</strong></p>
            <p>👨‍⚕️ Assigned doctor: <strong>Dr. {form.assigned_doctor}</strong></p>
            <p>📱 WhatsApp sent to patient with recovery plan</p>
          </div>
          <div className="mt-6 flex justify-center gap-3">
            <button
              onClick={() => navigate(`/patients/${id}`)}
              className="px-5 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700 transition-colors"
            >
              View Patient Record
            </button>
            <button
              onClick={() => navigate('/patients')}
              className="px-5 py-2 border border-green-300 text-green-700 rounded-lg text-sm font-medium hover:bg-green-100 transition-colors"
            >
              Back to Patient List
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ── Discharge form ──
  return (
    <div className="max-w-2xl mx-auto">
      {/* Back link */}
      <button
        onClick={() => navigate(`/patients/${id}`)}
        className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-4 transition-colors"
      >
        ← Back to {patient?.name || 'Patient'}
      </button>

      <h1 className="text-2xl font-bold text-gray-900 mb-6">📋 Discharge Patient</h1>

      {/* Patient summary (read-only) */}
      <div className="bg-blue-50 border border-blue-200 rounded-xl p-5 mb-6">
        <p className="text-xs font-semibold text-blue-500 uppercase tracking-wide mb-2">Patient Being Discharged</p>
        <p className="text-lg font-bold text-blue-900">{patient?.name}</p>
        <div className="flex flex-wrap gap-4 mt-2 text-sm text-blue-700">
          <span>🏥 {patient?.surgery_type}</span>
          <span>📅 Surgery: {patient?.surgery_date || '—'}</span>
          {patient?.phone && <span>📞 {patient.phone}</span>}
        </div>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="bg-white rounded-xl border border-gray-200 p-6 space-y-5">

        {/* Discharge date */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Discharge Date <span className="text-red-500">*</span>
          </label>
          <input
            type="date"
            name="discharge_date"
            value={form.discharge_date}
            max={today}
            onChange={handleChange}
            required
            className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
          <p className="text-xs text-gray-400 mt-1">
            This starts the patient's 42-day home recovery countdown in the app.
          </p>
        </div>

        {/* Assigned doctor */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Discharging Doctor <span className="text-red-500">*</span>
          </label>
          <input
            type="text"
            name="assigned_doctor"
            value={form.assigned_doctor}
            onChange={handleChange}
            placeholder="e.g. Dr. Amina Wanjiku"
            required
            className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>

        {/* Discharge notes */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Discharge Instructions
          </label>
          <textarea
            name="discharge_notes"
            value={form.discharge_notes}
            onChange={handleChange}
            rows={6}
            placeholder={
              `Write specific instructions for this patient.\n\n` +
              `Examples:\n` +
              `• Keep the wound dry for 5 days\n` +
              `• Return to clinic on Day 10 for suture removal\n` +
              `• Avoid lifting anything heavier than 2 kg for 4 weeks\n` +
              `• Take amoxicillin 500mg three times daily for 7 days\n` +
              `• Call us if you develop fever above 38°C or the wound swells`
            }
            className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
          />
          <p className="text-xs text-gray-400 mt-1">
            These instructions appear word-for-word in the patient's SalamaRecover app — write them for the patient to read, not for other clinicians.
          </p>
        </div>

        {/* Error */}
        {discharge.isError && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-3 text-sm text-red-700">
            ⚠️ {discharge.error?.response?.data?.detail || 'Failed to record discharge. Please try again.'}
          </div>
        )}

        {/* Actions */}
        <div className="flex justify-end gap-3 pt-2 border-t border-gray-100">
          <button
            type="button"
            onClick={() => navigate(`/patients/${id}`)}
            className="px-5 py-2 border border-gray-300 text-gray-600 rounded-lg text-sm font-medium hover:bg-gray-50 transition-colors"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={discharge.isPending || !form.assigned_doctor.trim()}
            className="px-6 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
          >
            {discharge.isPending ? (
              <>
                <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                Recording...
              </>
            ) : (
              '✅ Confirm Discharge'
            )}
          </button>
        </div>
      </form>

      {/* What happens next */}
      <div className="mt-4 bg-gray-50 rounded-xl border border-gray-200 p-5">
        <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">What Happens After You Submit</p>
        <div className="space-y-2 text-sm text-gray-600">
          <p>📋 Discharge is recorded in the patient's hospital record</p>
          <p>📱 Patient receives a WhatsApp message with their recovery plan</p>
          <p>🗓️ Their 42-day recovery countdown starts from the discharge date</p>
          <p>💬 Their doctor's instructions appear in their SalamaRecover app</p>
          <p>🔔 The care team will receive daily check-in alerts if risk is HIGH</p>
        </div>
      </div>
    </div>
  );
}
