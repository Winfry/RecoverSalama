import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { Users, AlertTriangle, CheckCircle, Clock, TrendingUp } from 'lucide-react';
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

  const sparkData = analytics?.pain_trend?.map(d => d.checkins || 0) || [0,0,0,0,0,0,0];
  const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  const maxH = Math.max(...sparkData, 1);

  const riskBreakdown = analytics?.risk_breakdown || { LOW:0, MEDIUM:0, HIGH:0, EMERGENCY:0 };
  const total = Object.values(riskBreakdown).reduce((a,b) => a+b, 0) || 1;

  const riskRows = [
    { label: 'Low',       pct: Math.round(riskBreakdown.LOW/total*100),       count: riskBreakdown.LOW,       color: C.green,  bg: C.greenLight },
    { label: 'Medium',    pct: Math.round(riskBreakdown.MEDIUM/total*100),    count: riskBreakdown.MEDIUM,    color: C.blue,   bg: C.blueLight },
    { label: 'High',      pct: Math.round(riskBreakdown.HIGH/total*100),      count: riskBreakdown.HIGH,      color: C.amber,  bg: C.amberLight },
    { label: 'Emergency', pct: Math.round(riskBreakdown.EMERGENCY/total*100), count: riskBreakdown.EMERGENCY, color: C.red,    bg: C.redLight },
  ];

  const highRiskPatients = patients.filter(p =>
    p.risk_level === 'HIGH' || p.risk_level === 'EMERGENCY'
  );

  const noCheckin48h = patients.filter(p => !p.last_checkin_today).length;

  return (
    <div>
      {/* Page header */}
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 20, fontWeight: 700, color: C.textMain, margin: 0 }}>Dashboard</h1>
        <p style={{ fontSize: 13, color: C.textMuted, margin: '4px 0 0' }}>
          {new Date().toLocaleDateString('en-KE', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
        </p>
      </div>

      {/* Stat cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 16, marginBottom: 24 }}>
        <StatCard
          label="Total Patients"
          value={analytics?.total_patients ?? patients.length}
          delta={`${patients.length} active`}
          icon={Users}
        />
        <StatCard
          label="High Risk / Emergency"
          value={analytics?.high_risk_count ?? 0}
          delta={`${alerts.filter(a => a.status==='active').length} unacknowledged alerts`}
          accent={C.red}
          icon={AlertTriangle}
        />
        <StatCard
          label="Checked In Today"
          value={analytics?.checkins_today ?? 0}
          delta={`${analytics?.compliance_rate ?? 0}% check-in rate`}
          accent={C.green}
          icon={CheckCircle}
        />
        <StatCard
          label="No Check-In (48h+)"
          value={noCheckin48h}
          delta="Needs follow-up"
          accent={C.amber}
          icon={Clock}
        />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
        {/* Recent alerts */}
        <Section title="Recent Alerts" action="View all →" onAction={() => navigate('/alerts')}>
          {alerts.slice(0,3).map(a => (
            <div key={a.id} style={{ display: 'flex', gap: 12, paddingBottom: 14, marginBottom: 14, borderBottom: `1px solid ${C.border}` }}>
              <div style={{
                width: 8, height: 8, borderRadius: '50%', flexShrink: 0,
                background: a.risk_level === 'EMERGENCY' ? C.red : C.amber,
                marginTop: 5,
              }} />
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: 500, color: C.textMain, marginBottom: 4, display: 'flex', alignItems: 'center', gap: 8 }}>
                  {a.patients?.name || a.phone || 'Patient'}
                  <Badge level={a.risk_level} />
                </div>
                <div style={{ fontSize: 12, color: C.textMuted, marginBottom: 3 }}>{a.message}</div>
                <div style={{ fontSize: 11, color: C.textDim }}>
                  {new Date(a.created_at).toLocaleString('en-KE')}
                </div>
              </div>
            </div>
          ))}
          {alerts.length === 0 && (
            <div style={{ textAlign: 'center', padding: '24px 0', color: C.textMuted, fontSize: 13 }}>
              No active alerts
            </div>
          )}
        </Section>

        {/* Check-in activity + risk distribution */}
        <Section title="Check-in Activity (7 days)">
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6, height: 60, marginBottom: 20 }}>
            {sparkData.map((v, i) => (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                <div style={{
                  width: '100%',
                  height: `${Math.max((v/maxH)*56, 3)}px`,
                  background: i >= 5 ? `${C.primary}50` : C.primary,
                  borderRadius: '3px 3px 0 0',
                }} />
                <span style={{ fontSize: 9, color: C.textDim }}>{days[i]}</span>
              </div>
            ))}
          </div>

          <div style={{ borderTop: `1px solid ${C.border}`, paddingTop: 16 }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: C.textMuted, marginBottom: 10, textTransform: 'uppercase', letterSpacing: '0.6px' }}>
              Risk Distribution
            </div>
            {riskRows.map(({ label, pct, count, color, bg }) => (
              <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
                <span style={{ fontSize: 11, color: C.textMuted, width: 72, textAlign: 'right', flexShrink: 0 }}>{label}</span>
                <div style={{ flex: 1, height: 20, background: C.bg, borderRadius: 4, overflow: 'hidden', border: `1px solid ${C.border}` }}>
                  <div style={{
                    width: `${pct}%`, height: '100%', background: bg,
                    display: 'flex', alignItems: 'center', paddingLeft: 6,
                    fontSize: 10, fontWeight: 600, color,
                    minWidth: count > 0 ? 20 : 0,
                  }}>
                    {count > 0 ? count : ''}
                  </div>
                </div>
                <span style={{ fontSize: 10, color: C.textDim, width: 28, textAlign: 'right' }}>{pct}%</span>
              </div>
            ))}
          </div>
        </Section>
      </div>

      {/* High-risk patients table */}
      <Section
        title="High-Risk Patients Requiring Attention"
        action="All patients →"
        onAction={() => navigate('/patients')}
        noPadBody
      >
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
          <thead>
            <tr style={{ background: C.bg }}>
              {['Patient', 'Surgery', 'Day', 'Risk', 'Last Check-in', 'Channel'].map(h => (
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
            {highRiskPatients.length > 0 ? highRiskPatients.map((p, i) => (
              <tr
                key={p.id}
                style={{ cursor: 'pointer', background: i % 2 === 0 ? C.surface : C.bg }}
                onClick={() => navigate(`/patients/${p.id}`)}
                onMouseEnter={e => e.currentTarget.style.background = C.primaryLight}
                onMouseLeave={e => e.currentTarget.style.background = i % 2 === 0 ? C.surface : C.bg}
              >
                <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, fontWeight: 600, color: C.textMain }}>{p.name}</td>
                <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMuted }}>{p.surgery_type}</td>
                <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMuted }}>Day {p.days_since_surgery ?? '—'}</td>
                <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}` }}><Badge level={p.risk_level} /></td>
                <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMuted, fontSize: 12 }}>Today</td>
                <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMuted, fontSize: 12 }}>App</td>
              </tr>
            )) : (
              <tr>
                <td colSpan={6} style={{ padding: '32px 16px', textAlign: 'center', color: C.textMuted, fontSize: 13 }}>
                  No high-risk patients right now
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Section>
    </div>
  );
}
