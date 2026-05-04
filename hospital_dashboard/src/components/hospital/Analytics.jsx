import { useQuery } from '@tanstack/react-query';
import { Users, TrendingUp, AlertTriangle, Activity } from 'lucide-react';
import { getAnalytics } from '../../services/api';
import { C } from '../../theme';
import StatCard from '../common/StatCard';
import Section from '../common/Section';

export default function Analytics() {
  const hospitalId = localStorage.getItem('hospital_id') || undefined;

  const { data, isLoading, error } = useQuery({
    queryKey: ['analytics', hospitalId],
    queryFn: () => getAnalytics(hospitalId).then((r) => r.data),
    refetchInterval: 60000,
  });

  if (isLoading) return <LoadingState />;
  if (error) return <ErrorState message={error.message} />;

  const riskBreakdown = data.risk_breakdown || {};
  const total = Object.values(riskBreakdown).reduce((a,b) => a+b, 0) || 1;

  // SVG pain trend line chart
  const pts = (data.pain_trend || []).map(d => d.avg_pain ?? 0);
  const days = (data.pain_trend || []).map(d => d.day || '');
  const W = 320, H = 100;
  const maxP = Math.max(...pts, 10);
  const coords = pts.map((v, i) => ({
    x: 8 + i * ((W - 16) / Math.max(pts.length - 1, 1)),
    y: H - (v / maxP) * (H - 8) + 4,
  }));
  const polyline = coords.map(c => `${c.x},${c.y}`).join(' ');
  const polygon = coords.length > 1
    ? `${coords[0].x},${H} ${polyline} ${coords[coords.length-1].x},${H}`
    : '';

  const surgeryRows = [
    { label: 'Appendectomy',     widths: [44, 28, 17, 11] },
    { label: 'C-Section',        widths: [60, 25, 10, 5]  },
    { label: 'Knee Replacement', widths: [36, 27, 27, 10] },
    { label: 'Hernia Repair',    widths: [55, 22, 23, 0]  },
  ];

  const riskColors = [C.green, C.blue, C.amber, C.red];
  const riskBgs    = [C.greenLight, C.blueLight, C.amberLight, C.redLight];

  return (
    <div>
      {/* Page header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
        <div>
          <h1 style={{ fontSize: 20, fontWeight: 700, color: C.textMain, margin: 0 }}>Analytics</h1>
          <p style={{ fontSize: 13, color: C.textMuted, margin: '4px 0 0' }}>Refreshes every 60s</p>
        </div>
      </div>

      {/* Stat cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 16, marginBottom: 24 }}>
        <StatCard
          label="Total Patients"
          value={data.total_patients}
          delta="Active in system"
          icon={Users}
        />
        <StatCard
          label="Check-in Rate"
          value={`${data.compliance_rate ?? 0}%`}
          delta={`${data.checkins_today} checked in today`}
          accent={C.green}
          icon={TrendingUp}
        />
        <StatCard
          label="High Risk"
          value={data.high_risk_count}
          delta="Emergency + High"
          accent={C.red}
          icon={AlertTriangle}
        />
        <StatCard
          label="Avg Pain"
          value={data.avg_pain_this_week > 0 ? `${data.avg_pain_this_week}/10` : '—'}
          delta="7-day average"
          accent={C.amber}
          icon={Activity}
        />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
        {/* Risk by surgery type */}
        <Section title="Risk Distribution by Surgery Type">
          {surgeryRows.map(({ label, widths }) => (
            <div key={label} style={{ marginBottom: 16 }}>
              <div style={{ fontSize: 12, fontWeight: 500, color: C.textMain, marginBottom: 6 }}>{label}</div>
              <div style={{ display: 'flex', height: 16, borderRadius: 4, overflow: 'hidden', gap: 2 }}>
                {widths.map((w, i) => w > 0 && (
                  <div
                    key={i}
                    title={['Low','Medium','High','Emergency'][i]}
                    style={{ width: `${w}%`, background: riskBgs[i], border: `1px solid ${riskColors[i]}30` }}
                  />
                ))}
              </div>
            </div>
          ))}
          <div style={{ display: 'flex', gap: 16, marginTop: 12, paddingTop: 12, borderTop: `1px solid ${C.border}`, flexWrap: 'wrap' }}>
            {['Low','Medium','High','Emergency'].map((label, i) => (
              <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 11, color: C.textMuted }}>
                <div style={{ width: 10, height: 10, borderRadius: 2, background: riskBgs[i], border: `1px solid ${riskColors[i]}50` }} />
                {label}
              </div>
            ))}
          </div>
        </Section>

        {/* Pain trend */}
        <Section title="7-Day Average Pain Trend">
          {coords.length > 0 ? (
            <>
              <svg viewBox={`0 0 ${W} ${H + 24}`} style={{ width: '100%', overflow: 'visible' }}>
                {[2,4,6,8,10].map(v => (
                  <line key={v}
                    x1={0} y1={H - (v/maxP)*(H-8)+4} x2={W} y2={H - (v/maxP)*(H-8)+4}
                    stroke={C.border} strokeWidth={1} strokeDasharray="4 4"/>
                ))}
                {polygon && <polygon points={polygon} fill={`${C.primary}15`} />}
                <polyline points={polyline} fill="none" stroke={C.primary} strokeWidth={2.5}
                  strokeLinejoin="round" strokeLinecap="round" />
                {coords.map((c, i) => (
                  <circle key={i} cx={c.x} cy={c.y} r={4} fill={C.primary} stroke="#fff" strokeWidth={2}/>
                ))}
                {days.map((d, i) => (
                  <text key={d} x={coords[i]?.x} y={H + 18} fontSize={9} fill={C.textDim} textAnchor="middle">{d}</text>
                ))}
              </svg>
              <div style={{ fontSize: 11, color: C.textMuted, marginTop: 4 }}>
                Mean daily pain score across all patients
              </div>
            </>
          ) : (
            <div style={{ textAlign: 'center', padding: '32px 0', color: C.textMuted, fontSize: 12 }}>No data yet</div>
          )}
        </Section>
      </div>

      {/* Readmission risk table */}
      <Section title="Top 5 Readmission Risk Patients" noPadBody>
        {data.readmission_risks?.length > 0 ? (
          <>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
              <thead>
                <tr style={{ background: C.bg }}>
                  {['Patient','Surgery','Recovery Day','Risk Score','Risk Bar'].map(h => (
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
                {data.readmission_risks.map((r, i) => {
                  const pct = Math.round(r.probability * 100);
                  const color = pct >= 70 ? C.red : pct >= 40 ? C.amber : C.green;
                  const bg    = pct >= 70 ? C.redLight : pct >= 40 ? C.amberLight : C.greenLight;
                  return (
                    <tr key={r.patient_id} style={{ background: i % 2 === 0 ? C.surface : C.bg }}>
                      <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, fontWeight: 600, color: C.textMain }}>{r.patient_name}</td>
                      <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMuted }}>{r.surgery_type || '—'}</td>
                      <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMuted }}>Day {r.days_since_surgery}</td>
                      <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}` }}>
                        <span style={{ fontWeight: 700, color, background: bg, padding: '3px 10px', borderRadius: 6, fontSize: 12 }}>{pct}%</span>
                      </td>
                      <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, width: 140 }}>
                        <div style={{ height: 8, borderRadius: 4, background: C.bg, overflow: 'hidden', border: `1px solid ${C.border}` }}>
                          <div style={{ height: '100%', width: `${pct}%`, background: color, borderRadius: 4 }} />
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
            <div style={{ padding: '14px 20px', borderTop: `1px solid ${C.border}`, display: 'flex', gap: 20, flexWrap: 'wrap' }}>
              {[
                { label: 'Low (<40%)',         color: C.green, note: 'Routine monitoring' },
                { label: 'Medium (40–70%)',     color: C.amber, note: 'Follow up 3–5 days' },
                { label: 'High (70%+)',         color: C.red,   note: 'Call within 48 hrs' },
              ].map(({ label, color, note }) => (
                <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, color: C.textMuted }}>
                  <div style={{ width: 8, height: 8, borderRadius: '50%', background: color }} />
                  <strong style={{ color }}>{label}</strong> — {note}
                </div>
              ))}
            </div>
          </>
        ) : (
          <div style={{ textAlign: 'center', padding: '40px 0', color: C.textMuted, fontSize: 13 }}>
            No patient data yet — check-in data will appear here once patients start using the app.
          </div>
        )}
      </Section>
    </div>
  );
}

function LoadingState() {
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 16, marginBottom: 24 }}>
        {[1,2,3,4].map(i => (
          <div key={i} style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, padding: 20, height: 100, opacity: 0.4 }} />
        ))}
      </div>
    </div>
  );
}

function ErrorState({ message }) {
  return (
    <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, padding: 40, textAlign: 'center' }}>
      <div style={{ fontSize: 14, color: C.red, fontWeight: 600, marginBottom: 6 }}>Could not load analytics</div>
      <div style={{ fontSize: 13, color: C.textMuted }}>{message}</div>
    </div>
  );
}
