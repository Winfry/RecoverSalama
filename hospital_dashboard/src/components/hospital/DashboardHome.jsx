import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { getPatients, getAlerts, getAnalytics } from '../../services/api';
import { C } from '../../theme';
import StatCard from '../common/StatCard';
import Section from '../common/Section';
import Badge from '../common/Badge';

export default function DashboardHome() {
  const navigate = useNavigate();
  const hospitalId = localStorage.getItem('hospital_id') || undefined;

  const { data: patients = [] } = useQuery({
    queryKey: ['patients', hospitalId],
    queryFn: () => getPatients(hospitalId).then((r) => r.data),
  });

  const { data: alerts = [] } = useQuery({
    queryKey: ['alerts', hospitalId],
    queryFn: () => getAlerts(hospitalId).then((r) => r.data),
    refetchInterval: 30000,
  });

  const { data: analytics } = useQuery({
    queryKey: ['analytics', hospitalId],
    queryFn: () => getAnalytics(hospitalId).then((r) => r.data),
    refetchInterval: 60000,
  });

  // Spark bar data — check-in counts per day (from analytics pain_trend)
  const sparkData = analytics?.pain_trend?.map(d => d.checkins || 0) || [0,0,0,0,0,0,0];
  const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  const maxH = Math.max(...sparkData, 1);

  // Risk distribution
  const riskBreakdown = analytics?.risk_breakdown || { LOW:0, MEDIUM:0, HIGH:0, EMERGENCY:0 };
  const total = Object.values(riskBreakdown).reduce((a,b) => a+b, 0) || 1;
  const riskRows = [
    ['Low',       `${Math.round(riskBreakdown.LOW/total*100)}%`,       riskBreakdown.LOW,       'rgba(39,174,96,0.4)',   '#58D68D'],
    ['Medium',    `${Math.round(riskBreakdown.MEDIUM/total*100)}%`,    riskBreakdown.MEDIUM,    'rgba(45,125,210,0.4)',  '#5DADE2'],
    ['High',      `${Math.round(riskBreakdown.HIGH/total*100)}%`,      riskBreakdown.HIGH,      'rgba(230,126,34,0.4)', '#F39C12'],
    ['Emergency', `${Math.round(riskBreakdown.EMERGENCY/total*100)}%`, riskBreakdown.EMERGENCY, 'rgba(192,57,43,0.5)',  '#E74C3C'],
  ];

  const highRiskPatients = patients.filter(p =>
    p.risk_level === 'HIGH' || p.risk_level === 'EMERGENCY'
  );

  const noCheckin48h = patients.filter(p => !p.last_checkin_today).length;

  return (
    <div>
      {/* Stat cards */}
      <div style={{ display:"grid", gridTemplateColumns:"repeat(4,1fr)", gap:14, marginBottom:22 }}>
        <StatCard label="Total Patients"      value={analytics?.total_patients ?? patients.length} delta={`${patients.length} active`}                    borderColor={C.accent} />
        <StatCard label="Emergency / High"    value={analytics?.high_risk_count ?? 0}              delta={`${alerts.filter(a=>a.status==='active').length} unacknowledged`} accent="#E74C3C" borderColor={C.red} />
        <StatCard label="Checked In Today"    value={analytics?.checkins_today ?? 0}               delta={`${analytics?.compliance_rate ?? 0}% check-in rate`}              accent="#58D68D" borderColor={C.green} />
        <StatCard label="No Check-In (48h+)"  value={noCheckin48h}                                 delta="Needs follow-up"                                                   accent="#F39C12" borderColor={C.amber} />
      </div>

      <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:16 }}>
        {/* Recent alerts */}
        <Section title="Recent Alerts" action="View all →" onAction={() => navigate('/alerts')}>
          {alerts.slice(0,3).map(a => (
            <div key={a.id} style={{ display:"flex", gap:12, paddingBottom:14, marginBottom:14, borderBottom:`1px solid ${C.border}` }}>
              <div style={{
                width:8, height:8, borderRadius:"50%",
                background: a.risk_level==='EMERGENCY' ? C.red : C.amber,
                marginTop:5, flexShrink:0,
                boxShadow: a.risk_level==='EMERGENCY' ? "0 0 6px rgba(192,57,43,0.6)" : "none",
              }} />
              <div>
                <div style={{ fontSize:13, fontWeight:500, color:C.textMain, marginBottom:2 }}>
                  {a.patients?.name || a.phone || 'Patient'} <Badge level={a.risk_level} />
                </div>
                <div style={{ fontSize:12, color:C.textMuted }}>{a.message}</div>
                <div style={{ fontSize:11, color:C.textDim, marginTop:4, fontFamily:"monospace" }}>
                  {new Date(a.created_at).toLocaleString('en-KE')}
                </div>
              </div>
            </div>
          ))}
          {alerts.length === 0 && (
            <div style={{ textAlign:"center", padding:"24px 0", color:C.textMuted, fontSize:13 }}>
              ✓ No active alerts
            </div>
          )}
        </Section>

        {/* Check-in activity + risk distribution */}
        <Section title="Check-in Activity (7 days)">
          <div style={{ display:"flex", alignItems:"flex-end", gap:4, height:56, marginBottom:20 }}>
            {sparkData.map((v, i) => (
              <div key={i} style={{ flex:1, display:"flex", flexDirection:"column", alignItems:"center", gap:4 }}>
                <div style={{
                  width:"100%",
                  height:`${(v/maxH)*52}px`,
                  background: C.accent,
                  opacity: i >= 5 ? 0.4 : 0.7,
                  borderRadius:"2px 2px 0 0",
                  minHeight: 2,
                }} />
                <span style={{ fontSize:9, color:C.textDim }}>{days[i]}</span>
              </div>
            ))}
          </div>
          <div style={{ borderTop:`1px solid ${C.border}`, paddingTop:14 }}>
            <div style={{ fontSize:11, color:C.textMuted, marginBottom:10, textTransform:"uppercase", letterSpacing:"0.8px" }}>
              Risk Distribution
            </div>
            {riskRows.map(([label, w, count, bg, color]) => (
              <div key={label} style={{ display:"flex", alignItems:"center", gap:10, marginBottom:8 }}>
                <span style={{ fontSize:11, color:C.textMuted, width:70, textAlign:"right" }}>{label}</span>
                <div style={{ flex:1, height:18, background:C.navy, borderRadius:3, overflow:"hidden" }}>
                  <div style={{ width:w, height:"100%", background:bg, display:"flex", alignItems:"center", paddingLeft:8, fontSize:10, fontWeight:600, color }}>
                    {count}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </Section>
      </div>

      {/* High-risk patients table */}
      <Section title="High-Risk Patients Requiring Attention" action="All patients →" onAction={() => navigate('/patients')} noPadBody>
        <table style={{ width:"100%", borderCollapse:"collapse", fontSize:12 }}>
          <thead>
            <tr>
              {["Patient","Surgery","Day","Risk","Last Check-in","Channel"].map(h => (
                <th key={h} style={{ textAlign:"left", padding:"0 12px 10px", fontSize:10, fontWeight:600, color:C.textDim, textTransform:"uppercase", letterSpacing:"0.8px" }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {highRiskPatients.length > 0 ? highRiskPatients.map(p => (
              <tr key={p.id} style={{ cursor:"pointer" }} onClick={() => navigate(`/patients/${p.id}`)}>
                <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, fontWeight:500, color:C.textMain }}>{p.name}</td>
                <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, color:C.textMain }}>{p.surgery_type}</td>
                <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, color:C.textMain, fontFamily:"monospace" }}>{p.days_since_surgery ?? '—'}</td>
                <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}` }}><Badge level={p.risk_level} /></td>
                <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, color:C.textMuted }}>Today</td>
                <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, color:C.textMuted }}>App</td>
              </tr>
            )) : (
              <tr>
                <td colSpan={6} style={{ padding:"24px 12px", textAlign:"center", color:C.textMuted, fontSize:13 }}>
                  ✓ No high-risk patients right now
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Section>
    </div>
  );
}
