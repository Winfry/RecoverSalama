import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { getPatient, dischargePatient } from '../../services/api';
import { C } from '../../theme';
import Section from '../common/Section';

export default function DischargeForm() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [saving, setSaving] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState('');

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

  const inputStyle = {
    width: "100%",
    background: C.navy,
    border: `1px solid ${C.border}`,
    borderRadius: 6,
    color: C.textMain,
    padding: "9px 12px",
    fontSize: 13,
    outline: "none",
    fontFamily: "inherit",
    boxSizing: "border-box",
  };
  const labelStyle = {
    display: "block",
    fontSize: 11,
    color: C.textMuted,
    marginBottom: 6,
    textTransform: "uppercase",
    letterSpacing: "0.6px",
    fontWeight: 500,
  };

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
      <div style={{ maxWidth:480, margin:"60px auto", textAlign:"center" }}>
        <div style={{ fontSize:40, marginBottom:16 }}>✓</div>
        <div style={{ fontSize:18, fontWeight:600, color:C.textMain, marginBottom:8 }}>Patient Discharged</div>
        <div style={{ fontSize:13, color:C.textMuted, marginBottom:24 }}>
          {patient?.name || 'Patient'} has been discharged. A WhatsApp notification has been sent to their phone.
        </div>
        <button
          onClick={() => navigate('/patients')}
          style={{ background:C.accent, border:"none", borderRadius:6, padding:"10px 24px", fontSize:13, fontWeight:600, color:"#fff", cursor:"pointer" }}
        >
          Back to Patients
        </button>
      </div>
    );
  }

  return (
    <div style={{ maxWidth:800, margin:"0 auto" }}>
      <div
        style={{ fontSize:12, color:C.textMuted, cursor:"pointer", marginBottom:14 }}
        onClick={() => navigate(id ? `/patients/${id}` : '/patients')}
      >
        ← Back
      </div>

      <div style={{ fontSize:18, fontWeight:600, color:C.textMain, marginBottom:20 }}>
        Discharge Patient{patient ? ` — ${patient.name}` : ''}
      </div>

      {error && (
        <div style={{ background:"rgba(192,57,43,0.15)", border:"1px solid rgba(192,57,43,0.3)", borderRadius:6, padding:"10px 14px", fontSize:12, color:"#E74C3C", marginBottom:16 }}>
          {error}
        </div>
      )}

      {patient?.is_discharged && (
        <div style={{ background:"rgba(45,125,210,0.1)", border:"1px solid rgba(45,125,210,0.3)", borderRadius:6, padding:"10px 14px", fontSize:12, color:C.accentLight, marginBottom:16 }}>
          This patient was already discharged on {patient.discharge_date} by Dr. {patient.assigned_doctor}.
        </div>
      )}

      <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:16 }}>
        <Section title="Discharge Details">
          <div style={{ display:"grid", gap:14 }}>
            <div>
              <label style={labelStyle}>Discharge Date</label>
              <input type="date" style={inputStyle} value={form.discharge_date} onChange={set('discharge_date')} />
            </div>
            <div>
              <label style={labelStyle}>Assigned Doctor</label>
              <input style={inputStyle} value={form.assigned_doctor} onChange={set('assigned_doctor')} placeholder="e.g. Dr. Kamau" />
            </div>
          </div>
        </Section>

        <Section title="Patient Summary">
          {patient ? (
            <div style={{ fontSize:12, color:C.textMuted, lineHeight:1.8 }}>
              <div><span style={{ color:C.textDim }}>Name:</span> {patient.name}</div>
              <div><span style={{ color:C.textDim }}>Surgery:</span> {patient.surgery_type}</div>
              <div><span style={{ color:C.textDim }}>Age:</span> {patient.age}</div>
              <div><span style={{ color:C.textDim }}>Phone:</span> {patient.phone || '—'}</div>
              <div><span style={{ color:C.textDim }}>Allergies:</span> {(patient.allergies||[]).join(', ') || 'None'}</div>
            </div>
          ) : (
            <div style={{ fontSize:12, color:C.textMuted }}>
              {id ? 'Loading patient...' : 'No patient selected. Go to a patient profile and click Discharge.'}
            </div>
          )}
        </Section>
      </div>

      <Section title="Discharge Instructions">
        <textarea
          style={{ ...inputStyle, minHeight:120, resize:"vertical" }}
          value={form.discharge_notes}
          onChange={set('discharge_notes')}
          placeholder="Enter discharge instructions, medications, follow-up appointments, warning signs to watch for..."
        />
      </Section>

      <div style={{ display:"flex", gap:10, justifyContent:"flex-end" }}>
        <button
          onClick={() => navigate(-1)}
          style={{ background:"transparent", border:`1px solid ${C.border}`, borderRadius:6, padding:"10px 20px", fontSize:13, color:C.textMuted, cursor:"pointer" }}
        >
          Cancel
        </button>
        <button
          onClick={handleSubmit}
          disabled={saving || patient?.is_discharged}
          style={{
            background: C.accent,
            border: "none",
            borderRadius: 6,
            padding: "10px 24px",
            fontSize: 13,
            fontWeight: 600,
            color: "#fff",
            cursor: saving || patient?.is_discharged ? "not-allowed" : "pointer",
            opacity: saving || patient?.is_discharged ? 0.6 : 1,
          }}
        >
          {saving ? 'Saving...' : 'Confirm Discharge'}
        </button>
      </div>
    </div>
  );
}
