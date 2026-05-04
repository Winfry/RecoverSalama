import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, CheckCircle } from 'lucide-react';
import { getPatient, dischargePatient } from '../../services/api';
import { C } from '../../theme';
import Section from '../common/Section';

const inputStyle = {
  width: '100%',
  border: `1px solid ${C.border}`,
  borderRadius: 8,
  padding: '10px 14px',
  fontSize: 13,
  color: C.textMain,
  background: C.bg,
  outline: 'none',
  fontFamily: 'inherit',
  boxSizing: 'border-box',
};

const labelStyle = {
  display: 'block',
  fontSize: 12,
  fontWeight: 500,
  color: C.textMain,
  marginBottom: 6,
};

export default function DischargeForm() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [saving, setSaving] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState('');
  const [sendWhatsapp, setSendWhatsapp] = useState(true);

  const [form, setForm] = useState({
    discharge_date: new Date().toISOString().slice(0, 10),
    assigned_doctor: '',
    discharge_notes: '',
  });

  const { data: patient } = useQuery({
    queryKey: ['patient', id],
    queryFn: () => getPatient(id).then((r) => r.data),
    enabled: !!id,
  });

  const set = (k) => (e) => setForm(f => ({ ...f, [k]: e.target.value }));

  const handleSubmit = async () => {
    if (!form.assigned_doctor.trim()) { setError('Doctor name is required.'); return; }
    if (!id) { setError('No patient selected.'); return; }
    setSaving(true);
    setError('');
    try {
      await dischargePatient(id, form);
      setDone(true);
    } catch (e) {
      setError(e.response?.data?.detail || 'Failed to discharge patient. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  if (done) {
    return (
      <div style={{ maxWidth: 480, margin: '80px auto', textAlign: 'center' }}>
        <div style={{
          width: 64, height: 64, borderRadius: '50%', background: C.greenLight,
          display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 20px',
        }}>
          <CheckCircle size={32} color={C.green} />
        </div>
        <div style={{ fontSize: 20, fontWeight: 700, color: C.textMain, marginBottom: 8 }}>Patient Discharged</div>
        <div style={{ fontSize: 14, color: C.textMuted, marginBottom: 28, lineHeight: 1.6 }}>
          {patient?.name || 'Patient'} has been successfully discharged.
          {sendWhatsapp && ' A WhatsApp summary has been sent to their phone.'}
        </div>
        <button
          onClick={() => navigate('/patients')}
          style={{
            background: C.primary, border: 'none', borderRadius: 8,
            padding: '11px 28px', fontSize: 14, fontWeight: 600, color: '#fff', cursor: 'pointer',
          }}
        >
          Back to Patients
        </button>
      </div>
    );
  }

  return (
    <div style={{ maxWidth: 860, margin: '0 auto' }}>
      {/* Back */}
      <button
        onClick={() => navigate(id ? `/patients/${id}` : '/patients')}
        style={{
          display: 'flex', alignItems: 'center', gap: 6, fontSize: 13,
          color: C.textMuted, cursor: 'pointer', background: 'transparent', border: 'none', padding: 0, marginBottom: 20,
        }}
      >
        <ArrowLeft size={14} /> Back
      </button>

      {/* Page header */}
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 20, fontWeight: 700, color: C.textMain, margin: 0 }}>
          Discharge Patient{patient ? ` — ${patient.name}` : ''}
        </h1>
        <p style={{ fontSize: 13, color: C.textMuted, margin: '4px 0 0' }}>
          Complete the form below to discharge the patient and send recovery instructions.
        </p>
      </div>

      {error && (
        <div style={{
          background: C.redLight, border: `1px solid #FEB2B2`,
          borderRadius: 8, padding: '10px 16px', fontSize: 13, color: C.red, marginBottom: 20,
        }}>
          {error}
        </div>
      )}

      {patient?.is_discharged && (
        <div style={{
          background: C.blueLight, border: `1px solid #BEE3F8`,
          borderRadius: 8, padding: '10px 16px', fontSize: 13, color: C.blue, marginBottom: 20,
        }}>
          This patient was already discharged on {patient.discharge_date} by Dr. {patient.assigned_doctor}.
        </div>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
        {/* Discharge details */}
        <Section title="Discharge Details">
          <div style={{ display: 'grid', gap: 16 }}>
            <div>
              <label style={labelStyle}>Discharge Date</label>
              <input type="date" style={inputStyle} value={form.discharge_date} onChange={set('discharge_date')} />
            </div>
            <div>
              <label style={labelStyle}>Assigned Doctor</label>
              <input
                style={inputStyle}
                value={form.assigned_doctor}
                onChange={set('assigned_doctor')}
                placeholder="e.g. Dr. Kamau"
              />
            </div>
          </div>
        </Section>

        {/* Patient summary */}
        <Section title="Patient Summary">
          {patient ? (
            <div style={{ display: 'grid', gap: 10 }}>
              {[
                ['Name',      patient.name],
                ['Surgery',   patient.surgery_type],
                ['Age',       patient.age],
                ['Phone',     patient.phone || '—'],
                ['Allergies', (patient.allergies || []).join(', ') || 'None'],
              ].map(([k, v]) => (
                <div key={k} style={{ display: 'flex', gap: 8 }}>
                  <span style={{ fontSize: 12, color: C.textMuted, width: 70, flexShrink: 0 }}>{k}</span>
                  <span style={{ fontSize: 13, color: C.textMain, fontWeight: 500 }}>{v}</span>
                </div>
              ))}
            </div>
          ) : (
            <div style={{ fontSize: 13, color: C.textMuted }}>
              {id ? 'Loading patient...' : 'No patient selected. Go to a patient profile and click Discharge.'}
            </div>
          )}
        </Section>
      </div>

      {/* Discharge instructions */}
      <Section title="Discharge Instructions">
        <textarea
          style={{ ...inputStyle, minHeight: 130, resize: 'vertical' }}
          value={form.discharge_notes}
          onChange={set('discharge_notes')}
          placeholder="Enter discharge instructions, medications, follow-up appointments, warning signs to watch for..."
        />
      </Section>

      {/* WhatsApp + actions */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 4 }}>
        <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: 13, color: C.textMuted }}>
          <input
            type="checkbox"
            checked={sendWhatsapp}
            onChange={e => setSendWhatsapp(e.target.checked)}
            style={{ width: 14, height: 14, accentColor: C.primary }}
          />
          Send WhatsApp recovery summary to patient
        </label>

        <div style={{ display: 'flex', gap: 10 }}>
          <button
            onClick={() => navigate(-1)}
            style={{
              border: `1px solid ${C.border}`, borderRadius: 8, padding: '10px 20px',
              fontSize: 13, color: C.textMuted, background: 'transparent', cursor: 'pointer',
            }}
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            disabled={saving || patient?.is_discharged}
            style={{
              background: C.primary, border: 'none', borderRadius: 8,
              padding: '10px 28px', fontSize: 13, fontWeight: 600, color: '#fff',
              cursor: saving || patient?.is_discharged ? 'not-allowed' : 'pointer',
              opacity: saving || patient?.is_discharged ? 0.6 : 1,
            }}
          >
            {saving ? 'Saving...' : 'Confirm Discharge'}
          </button>
        </div>
      </div>
    </div>
  );
}
