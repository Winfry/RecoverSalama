import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, Activity, ClipboardList, FileText } from 'lucide-react';
import { getPatient, getPatientHistory } from '../../services/api';
import { C, painColor } from '../../theme';
import Section from '../common/Section';
import Badge from '../common/Badge';

const tabs = [
  { id: 'overview',  label: 'Overview',  icon: Activity },
  { id: 'history',   label: 'History',   icon: ClipboardList },
  { id: 'discharge', label: 'Discharge', icon: FileText },
];

export default function PatientDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('overview');

  const { data: patient, isLoading } = useQuery({
    queryKey: ['patient', id],
    queryFn: () => getPatient(id).then((r) => r.data),
  });

  const { data: history = [] } = useQuery({
    queryKey: ['patient-history', id],
    queryFn: () => getPatientHistory(id).then((r) => r.data),
    enabled: !!id,
  });

  if (isLoading) return <div style={{ textAlign: 'center', padding: '60px 0', color: C.textMuted }}>Loading...</div>;
  if (!patient) return <div style={{ textAlign: 'center', padding: '60px 0', color: C.textMuted }}>Patient not found</div>;

  const initials = patient.name?.split(' ').map(n => n[0]).join('').slice(0,2).toUpperCase() || '??';
  const latest = history[0];

  // Simple SVG pain chart from history
  const painPts = history.slice(0, 14).reverse().map(h => h.pain_level ?? 0);
  const W = 360, H = 80;
  const maxP = 10;
  const coords = painPts.map((v, i) => ({
    x: painPts.length > 1 ? 8 + i * ((W - 16) / (painPts.length - 1)) : W / 2,
    y: H - (v / maxP) * H + 4,
  }));
  const polyline = coords.map(c => `${c.x},${c.y}`).join(' ');
  const polygon = coords.length > 1
    ? `${coords[0].x},${H} ${polyline} ${coords[coords.length-1].x},${H}`
    : '';

  return (
    <div>
      {/* Back */}
      <button
        onClick={() => navigate('/patients')}
        style={{
          display: 'flex', alignItems: 'center', gap: 6,
          fontSize: 13, color: C.textMuted, cursor: 'pointer',
          background: 'transparent', border: 'none', padding: 0, marginBottom: 20,
        }}
      >
        <ArrowLeft size={14} /> Back to Patients
      </button>

      {/* Patient header */}
      <div style={{
        background: C.surface,
        border: `1px solid ${C.border}`,
        borderRadius: 12,
        padding: '24px',
        marginBottom: 20,
        display: 'flex',
        gap: 20,
        alignItems: 'flex-start',
      }}>
        <div style={{
          width: 56, height: 56, borderRadius: '50%',
          background: C.primaryLight,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 18, fontWeight: 700, color: C.primary, flexShrink: 0,
        }}>
          {initials}
        </div>

        <div style={{ flex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 4 }}>
            <div style={{ fontSize: 20, fontWeight: 700, color: C.textMain }}>{patient.name}</div>
            <Badge level={latest?.risk_level || 'LOW'} />
          </div>
          <div style={{ fontSize: 13, color: C.textMuted, marginBottom: 12 }}>
            {patient.age} years · {patient.gender || '—'} · {patient.phone || 'No phone'}
          </div>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {[
              patient.surgery_type,
              `Day ${patient.days_since_surgery ?? '?'}`,
              patient.surgery_date ? `Surgery: ${patient.surgery_date}` : null,
            ].filter(Boolean).map(t => (
              <span key={t} style={{
                background: C.bg, border: `1px solid ${C.border}`,
                borderRadius: 6, padding: '4px 10px', fontSize: 12, color: C.textMuted,
              }}>{t}</span>
            ))}
          </div>
        </div>

        {!patient.is_discharged && (
          <button
            onClick={() => navigate(`/patients/${id}/discharge`)}
            style={{
              background: C.primary, border: 'none', borderRadius: 8,
              padding: '9px 18px', fontSize: 13, fontWeight: 600, color: '#fff', cursor: 'pointer',
              flexShrink: 0,
            }}
          >
            Discharge Patient
          </button>
        )}
        {patient.is_discharged && (
          <div style={{ textAlign: 'right', flexShrink: 0 }}>
            <div style={{ fontSize: 11, color: C.textMuted, marginBottom: 4 }}>Discharged by</div>
            <div style={{ fontSize: 13, fontWeight: 600, color: C.textMain }}>Dr. {patient.assigned_doctor || '—'}</div>
            <div style={{ fontSize: 11, color: C.textMuted, marginTop: 4 }}>{patient.discharge_date}</div>
          </div>
        )}
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 20 }}>
        {tabs.map(({ id: tid, label, icon: Icon }) => (
          <button
            key={tid}
            onClick={() => setActiveTab(tid)}
            style={{
              display: 'flex', alignItems: 'center', gap: 7,
              padding: '9px 16px', borderRadius: 8, fontSize: 13,
              fontWeight: activeTab === tid ? 600 : 400,
              background: activeTab === tid ? C.primaryLight : C.surface,
              color: activeTab === tid ? C.primary : C.textMuted,
              border: `1px solid ${activeTab === tid ? C.primary : C.border}`,
              cursor: 'pointer',
            }}
          >
            <Icon size={14} />
            {label}
          </button>
        ))}
      </div>

      {/* Tab content */}
      {activeTab === 'overview' && (
        <div>
          {/* Pain chart */}
          {painPts.length > 0 && (
            <Section title="Pain Trend">
              <svg viewBox={`0 0 ${W} ${H + 20}`} style={{ width: '100%', overflow: 'visible' }}>
                {[2,4,6,8,10].map(v => (
                  <line key={v} x1={0} y1={H - (v/maxP)*H + 4} x2={W} y2={H - (v/maxP)*H + 4}
                    stroke={C.border} strokeWidth={1} strokeDasharray="4 4"/>
                ))}
                {polygon && <polygon points={polygon} fill={`${C.primary}15`} />}
                <polyline points={polyline} fill="none" stroke={C.primary} strokeWidth={2} strokeLinejoin="round" strokeLinecap="round" />
                {coords.map((c, i) => (
                  <circle key={i} cx={c.x} cy={c.y} r={3.5}
                    fill={painColor(painPts[i])} stroke="#fff" strokeWidth={1.5}/>
                ))}
              </svg>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
                <span style={{ fontSize: 11, color: C.textDim }}>14 days ago</span>
                <span style={{ fontSize: 11, color: C.textDim }}>Today</span>
              </div>
            </Section>
          )}

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
            <Section title="Latest Check-in">
              {latest ? (
                <div>
                  <div style={{ display: 'flex', gap: 24, marginBottom: 16 }}>
                    <div style={{ textAlign: 'center' }}>
                      <div style={{ fontSize: 11, color: C.textMuted, marginBottom: 4 }}>PAIN</div>
                      <div style={{ fontSize: 28, fontWeight: 700, color: painColor(latest.pain_level), lineHeight: 1 }}>
                        {latest.pain_level}
                        <span style={{ fontSize: 13, color: C.textDim, fontWeight: 400 }}>/10</span>
                      </div>
                    </div>
                    <div style={{ textAlign: 'center' }}>
                      <div style={{ fontSize: 11, color: C.textMuted, marginBottom: 4 }}>MOOD</div>
                      <div style={{ fontSize: 22, fontWeight: 700, color: C.amber, lineHeight: 1 }}>
                        {latest.mood || '—'}
                      </div>
                    </div>
                  </div>
                  <div style={{ fontSize: 11, color: C.textMuted, marginBottom: 6 }}>SYMPTOMS REPORTED</div>
                  <div style={{ fontSize: 13, color: C.textMain }}>
                    {(latest.symptoms || []).join(', ') || 'None reported'}
                  </div>
                </div>
              ) : (
                <div style={{ fontSize: 13, color: C.textMuted }}>No check-ins yet.</div>
              )}
            </Section>

            <Section title="Discharge Instructions">
              <div style={{ fontSize: 13, color: C.textMuted, lineHeight: 1.7 }}>
                {patient.discharge_notes || 'No discharge instructions recorded yet.'}
              </div>
            </Section>
          </div>
        </div>
      )}

      {activeTab === 'history' && (
        <Section title={`Recovery History (${history.length} check-ins)`} noPadBody>
          {history.length > 0 ? (
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
              <thead>
                <tr style={{ background: C.bg }}>
                  {['Day', 'Date', 'Pain', 'Mood', 'Symptoms', 'Risk'].map(h => (
                    <th key={h} style={{
                      textAlign: 'left', padding: '10px 16px',
                      fontSize: 11, fontWeight: 600, color: C.textMuted,
                      textTransform: 'uppercase', letterSpacing: '0.5px',
                      borderBottom: `1px solid ${C.border}`,
                    }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {history.map((row, i) => (
                  <tr key={i} style={{ background: i % 2 === 0 ? C.surface : C.bg }}>
                    <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMuted }}>{row.days_since_surgery ?? '—'}</td>
                    <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMuted }}>
                      {new Date(row.created_at).toLocaleDateString('en-KE', { day: '2-digit', month: 'short' })}
                    </td>
                    <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, fontWeight: 700, color: painColor(row.pain_level) }}>
                      {row.pain_level}/10
                    </td>
                    <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMain }}>{row.mood || '—'}</td>
                    <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMuted, fontSize: 12 }}>
                      {(row.symptoms || []).join(', ') || 'None'}
                    </td>
                    <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}` }}>
                      <Badge level={row.risk_level} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div style={{ textAlign: 'center', padding: '40px 0', color: C.textMuted, fontSize: 13 }}>
              No check-ins yet.
            </div>
          )}
        </Section>
      )}

      {activeTab === 'discharge' && (
        <div style={{ textAlign: 'center', padding: '48px 0' }}>
          {patient.is_discharged ? (
            <div>
              <div style={{ fontSize: 16, fontWeight: 600, color: C.green, marginBottom: 8 }}>Patient Discharged</div>
              <div style={{ fontSize: 13, color: C.textMuted }}>
                Discharged on {patient.discharge_date} by Dr. {patient.assigned_doctor}
              </div>
            </div>
          ) : (
            <div>
              <div style={{ fontSize: 14, color: C.textMuted, marginBottom: 16 }}>
                Ready to discharge this patient?
              </div>
              <button
                onClick={() => navigate(`/patients/${id}/discharge`)}
                style={{
                  background: C.primary, border: 'none', borderRadius: 8,
                  padding: '11px 24px', fontSize: 14, fontWeight: 600, color: '#fff', cursor: 'pointer',
                }}
              >
                Start Discharge Process
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
