import { useQuery } from '@tanstack/react-query';
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
  if (error)     return <ErrorState message={error.message} />;

  const riskBreakdown = data.risk_breakdown || {};
  const total = Object.values(riskBreakdown).reduce((a,b) => a+b, 0) || 1;

  // SVG line chart for pain trend
  const pts = (data.pain_trend || []).map(d => d.avg_pain ?? 0);
  const days = (data.pain_trend || []).map(d => d.day || '');
  const W = 280, H = 90;
  const maxP = Math.max(...pts, 10);
  const coords = pts.map((v, i) => ({ x: 16 + i * 40, y: H - (v / maxP) * H }));
  const polyline = coords.map(c => `${c.x},${c.y}`).join(" ");
  const polygon = coords.length > 0
    ? `${coords[0].x},${H} ${polyline} ${coords[coords.length-1].x},${H}`
    : '';

  // Surgery risk breakdown rows
  const surgeryRows = [
    ["Appendectomy",    [44,28,17,11]],
    ["C-Section",       [60,25,10,5]],
    ["Knee Replacement",[36,27,27,10]],
    ["Hernia Repair",   [55,22,23,0]],
  ];

  return (
    <div>
      <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", marginBottom:22 }}>
        <div style={{ fontSize:18, fontWeight:600, color:C.textMain }}>Analytics</div>
        <div style={{ fontSize:11, color:C.textDim }}>Refreshes every 60s</div>
      </div>

      <div style={{ display:"grid", gridTemplateColumns:"repeat(4,1fr)", gap:14, marginBottom:22 }}>
        <StatCard label="Total Patients"       value={data.total_patients}                                                  delta="Active in system"                                                    borderColor={C.accent} />
        <StatCard label="7-Day Check-in Rate"  value={`${data.compliance_rate ?? 0}%`}                                     delta={`${data.checkins_today} checked in today`}                          accent="#58D68D" borderColor={C.green} />
        <StatCard label="High Risk Patients"   value={data.high_risk_count}                                                 delta="Emergency + High"                                                    accent="#E74C3C" borderColor={C.red} />
        <StatCard label="Avg Pain This Week"   value={data.avg_pain_this_week > 0 ? `${data.avg_pain_this_week}/10` : '—'} delta="Across all check-ins"                                                accent="#F39C12" borderColor={C.amber} />
      </div>

      <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:16, marginBottom:18 }}>
        {/* Risk by surgery type */}
        <Section title="Risk Distribution by Surgery Type">
          {surgeryRows.map(([label, widths]) => (
            <div key={label} style={{ marginBottom:14 }}>
              <div style={{ fontSize:11, color:C.textMuted, marginBottom:6 }}>{label}</div>
              <div style={{ display:"flex", height:14, borderRadius:3, overflow:"hidden", gap:2 }}>
                {[
                  ["rgba(39,174,96,0.5)",  widths[0]],
                  ["rgba(45,125,210,0.5)", widths[1]],
                  ["rgba(230,126,34,0.5)", widths[2]],
                  ["rgba(192,57,43,0.6)",  widths[3]],
                ].map(([bg, w], i) => w > 0 && (
                  <div key={i} style={{ width:`${w}%`, background:bg }} />
                ))}
              </div>
            </div>
          ))}
          <div style={{ display:"flex", gap:14, marginTop:14, paddingTop:12, borderTop:`1px solid ${C.border}` }}>
            {[["Low","rgba(39,174,96,0.5)"],["Medium","rgba(45,125,210,0.5)"],["High","rgba(230,126,34,0.5)"],["Emergency","rgba(192,57,43,0.6)"]].map(([label, bg]) => (
              <div key={label} style={{ display:"flex", alignItems:"center", gap:5, fontSize:10, color:C.textMuted }}>
                <div style={{ width:10, height:10, borderRadius:2, background:bg }} />{label}
              </div>
            ))}
          </div>
        </Section>

        {/* Pain trend SVG */}
        <Section title="7-Day Average Pain Trend">
          {coords.length > 0 ? (
            <>
              <svg viewBox={`0 0 ${W} ${H+20}`} style={{ width:"100%", overflow:"visible" }}>
                {coords.map((_, i) => (
                  <line key={i} x1={16+i*40} y1={0} x2={16+i*40} y2={H} stroke="rgba(255,255,255,0.05)" strokeWidth={1} />
                ))}
                {polygon && <polygon points={polygon} fill="rgba(45,125,210,0.15)" />}
                <polyline points={polyline} fill="none" stroke={C.accent} strokeWidth={2} strokeLinejoin="round" strokeLinecap="round" />
                {coords.map((c, i) => (
                  <circle key={i} cx={c.x} cy={c.y} r={3} fill={i===coords.length-1 ? C.accentLight : C.accent} />
                ))}
                {days.map((d, i) => (
                  <text key={d} x={16+i*40} y={H+14} fontSize={7.5} fill={C.textDim} textAnchor="middle">{d}</text>
                ))}
              </svg>
              <div style={{ fontSize:11, color:C.textMuted, marginTop:6 }}>
                Mean daily pain score across all patients
              </div>
            </>
          ) : (
            <div style={{ textAlign:"center", padding:"24px 0", color:C.textMuted, fontSize:12 }}>No data yet</div>
          )}
        </Section>
      </div>

      {/* Readmission risk table */}
      <Section title="Top 5 Readmission Risk Patients" noPadBody>
        {data.readmission_risks?.length > 0 ? (
          <>
            <table style={{ width:"100%", borderCollapse:"collapse", fontSize:12 }}>
              <thead>
                <tr>
                  {["Patient","Surgery","Day","Risk Score","Risk Bar","Key Factor"].map(h => (
                    <th key={h} style={{ textAlign:"left", padding:"0 12px 10px", fontSize:10, fontWeight:600, color:C.textDim, textTransform:"uppercase", letterSpacing:"0.8px" }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.readmission_risks.map(r => {
                  const pct = Math.round(r.probability * 100);
                  const color = pct >= 80 ? "#E74C3C" : "#F39C12";
                  return (
                    <tr key={r.patient_id}>
                      <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, fontWeight:500, color:C.textMain }}>{r.patient_name}</td>
                      <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, color:C.textMain }}>{r.surgery_type || '—'}</td>
                      <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, color:C.textMain, fontFamily:"monospace" }}>{r.days_since_surgery}</td>
                      <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, fontFamily:"monospace", fontWeight:600, color }}>{pct}%</td>
                      <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, width:120 }}>
                        <div style={{ height:6, borderRadius:3, background:C.navy, overflow:"hidden" }}>
                          <div style={{ height:"100%", width:`${pct}%`, background:color, borderRadius:3 }} />
                        </div>
                      </td>
                      <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, fontSize:11, color:C.textMuted }}>
                        {r.factors?.[0] || r.recommendation || '—'}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
            <div style={{ padding:"14px 18px", borderTop:`1px solid ${C.border}`, display:"flex", gap:16, flexWrap:"wrap" }}>
              {[["Low","rgba(39,174,96,0.5)","routine monitoring"],["Medium","rgba(230,126,34,0.5)","follow up in 3–5 days"],["High","rgba(192,57,43,0.6)","call or visit within 48 hrs"]].map(([label,bg,note]) => (
                <div key={label} style={{ display:"flex", alignItems:"center", gap:5, fontSize:10, color:C.textMuted }}>
                  <div style={{ width:8, height:8, borderRadius:"50%", background:bg }} />
                  {label} — {note}
                </div>
              ))}
            </div>
          </>
        ) : (
          <div style={{ textAlign:"center", padding:"32px 0", color:C.textMuted, fontSize:13 }}>
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
      <div style={{ display:"grid", gridTemplateColumns:"repeat(4,1fr)", gap:14, marginBottom:22 }}>
        {[1,2,3,4].map(i => (
          <div key={i} style={{ background:C.surface, border:`1px solid ${C.border}`, borderRadius:8, padding:"16px 18px", height:90, opacity:0.5 }} />
        ))}
      </div>
    </div>
  );
}

function ErrorState({ message }) {
  return (
    <div style={{ background:C.surface, border:`1px solid rgba(192,57,43,0.3)`, borderRadius:8, padding:32, textAlign:"center" }}>
      <div style={{ fontSize:13, color:"#E74C3C", fontWeight:600 }}>Could not load analytics</div>
      <div style={{ fontSize:12, color:C.textMuted, marginTop:6 }}>{message}</div>
    </div>
  );
}
