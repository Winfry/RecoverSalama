import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { getPatient, getPatientHistory } from '../../services/api';
import { C, painColor } from '../../theme';
import Section from '../common/Section';
import Badge from '../common/Badge';

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

  if (isLoading) return <div style={{ textAlign:"center", padding:"40px 0", color:C.textMuted }}>Loading...</div>;
  if (!patient)  return <div style={{ textAlign:"center", padding:"40px 0", color:C.textMuted }}>Patient not found</div>;

  const initials = patient.name?.split(' ').map(n => n[0]).join('').slice(0,2).toUpperCase() || '??';
  const latest = history[0];

  return (
    <div>
      {/* Back */}
      <div
        style={{ display:"flex", alignItems:"center", gap:6, fontSize:12, color:C.textMuted, cursor:"pointer", marginBottom:14 }}
        onClick={() => navigate('/patients')}
      >
        ← Back to Patient List
      </div>

      {/* Patient header card */}
      <div style={{ background:C.surface, border:`1px solid ${C.border}`, borderRadius:8, padding:20, marginBottom:16, display:"flex", gap:20 }}>
        <div style={{
          width:52, height:52, borderRadius:"50%",
          background: C.navyLight,
          display:"flex", alignItems:"center", justifyContent:"center",
          fontSize:16, fontWeight:600, color:C.accentLight, flexShrink:0,
        }}>
          {initials}
        </div>
        <div style={{ flex:1 }}>
          <div style={{ fontSize:18, fontWeight:600, color:C.textMain }}>{patient.name}</div>
          <div style={{ fontSize:13, color:C.textMuted, marginTop:2 }}>
            {patient.age} years · {patient.gender || '—'} · {patient.phone || 'No phone'}
          </div>
          <div style={{ display:"flex", gap:8, flexWrap:"wrap", marginTop:10 }}>
            {[patient.surgery_type, `Day ${patient.days_since_surgery ?? '?'}`, 'App Channel'].map(t => (
              <span key={t} style={{ background:C.navy, border:`1px solid ${C.border}`, borderRadius:4, padding:"3px 8px", fontSize:11, color:C.textMuted }}>{t}</span>
            ))}
            <Badge level={latest?.risk_level || 'LOW'} />
          </div>
        </div>
        <div style={{ textAlign:"right" }}>
          {patient.is_discharged ? (
            <>
              <div style={{ fontSize:11, color:C.textMuted, marginBottom:6 }}>Discharging Doctor</div>
              <div style={{ fontSize:13, fontWeight:500, color:C.textMain }}>Dr. {patient.assigned_doctor || '—'}</div>
              <div style={{ fontSize:11, color:C.textMuted, marginTop:8 }}>
                Discharged: {patient.discharge_date || '—'}
              </div>
            </>
          ) : (
            <button
              onClick={() => navigate(`/patients/${id}/discharge`)}
              style={{
                background: C.accent,
                border: "none",
                borderRadius: 6,
                padding: "8px 16px",
                fontSize: 12,
                fontWeight: 600,
                color: "#fff",
                cursor: "pointer",
              }}
            >
              + Discharge Patient
            </button>
          )}
        </div>
      </div>

      {/* Two-column info */}
      <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:16, marginBottom:16 }}>
        <Section title="Discharge Instructions">
          <div style={{ fontSize:12, color:C.textMuted, lineHeight:1.7 }}>
            {patient.discharge_notes || "No discharge instructions recorded yet."}
          </div>
        </Section>

        <Section title="Today's Check-in">
          {latest ? (
            <div style={{ display:"flex", gap:20 }}>
              <div style={{ textAlign:"center" }}>
                <div style={{ fontSize:10, color:C.textMuted, marginBottom:4 }}>PAIN</div>
                <div style={{ fontSize:22, fontWeight:600, fontFamily:"monospace", color:painColor(latest.pain_level) }}>
                  {latest.pain_level}/10
                </div>
              </div>
              <div style={{ textAlign:"center" }}>
                <div style={{ fontSize:10, color:C.textMuted, marginBottom:4 }}>MOOD</div>
                <div style={{ fontSize:22, fontWeight:600, fontFamily:"monospace", color:C.amber }}>
                  {latest.mood || '—'}
                </div>
              </div>
              <div style={{ flex:1 }}>
                <div style={{ fontSize:10, color:C.textMuted, marginBottom:4 }}>SYMPTOMS REPORTED</div>
                <div style={{ fontSize:12, color:C.textMain }}>
                  {(latest.symptoms || []).join(', ') || 'None reported'}
                </div>
              </div>
            </div>
          ) : (
            <div style={{ fontSize:12, color:C.textMuted }}>No check-ins yet.</div>
          )}
        </Section>
      </div>

      {/* Recovery history table */}
      <Section title={`Recovery History (${history.length} check-ins)`} noPadBody>
        {history.length > 0 ? (
          <table style={{ width:"100%", borderCollapse:"collapse", fontSize:12 }}>
            <thead>
              <tr>
                {["Day","Date","Pain (0–10)","Mood","Symptoms","Risk Score"].map(h => (
                  <th key={h} style={{ textAlign:"left", padding:"0 12px 10px", fontSize:10, fontWeight:600, color:C.textDim, textTransform:"uppercase", letterSpacing:"0.8px" }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {history.map((row, i) => (
                <tr key={i}>
                  <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, fontFamily:"monospace", color:C.textMain }}>{row.days_since_surgery}</td>
                  <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, color:C.textMain }}>
                    {new Date(row.created_at).toLocaleDateString('en-KE', { day:'2-digit', month:'short' })}
                  </td>
                  <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, fontWeight:600, fontFamily:"monospace", color:painColor(row.pain_level) }}>
                    {row.pain_level}
                  </td>
                  <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, color:C.textMain }}>{row.mood || '—'}</td>
                  <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, color:C.textMuted }}>
                    {(row.symptoms || []).join(', ') || 'None'}
                  </td>
                  <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}` }}>
                    <Badge level={row.risk_level} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <div style={{ textAlign:"center", padding:"32px 0", color:C.textMuted, fontSize:13 }}>
            No check-ins yet.
          </div>
        )}
      </Section>
    </div>
  );
}
