import { useEffect, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { getAlerts, updateAlert } from '../../services/api';
import { subscribeToAlerts } from '../../services/supabase';
import { C } from '../../theme';
import StatCard from '../common/StatCard';
import Section from '../common/Section';
import Badge from '../common/Badge';

export default function AlertCentre() {
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const hospitalId = localStorage.getItem('hospital_id') || undefined;

  const { data: alerts = [], isLoading } = useQuery({
    queryKey: ['alerts', hospitalId],
    queryFn: () => getAlerts(hospitalId).then((r) => r.data),
    refetchInterval: 30000,
  });

  useEffect(() => {
    if (!hospitalId) return;
    const sub = subscribeToAlerts(hospitalId, () => {
      queryClient.invalidateQueries({ queryKey: ['alerts', hospitalId] });
    });
    return () => sub.unsubscribe();
  }, [hospitalId, queryClient]);

  const ackMutation = useMutation({
    mutationFn: (id) => updateAlert(id, 'acknowledged'),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['alerts'] }),
  });
  const resolveMutation = useMutation({
    mutationFn: (id) => updateAlert(id, 'resolved'),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['alerts'] }),
  });

  const active = alerts.filter(a => a.status !== 'resolved');
  const emergency = active.filter(a => a.risk_level === 'EMERGENCY').length;
  const high = active.filter(a => a.risk_level === 'HIGH').length;

  const btnStyle = (bg, color, border) => ({
    padding: "4px 10px",
    fontSize: 11,
    borderRadius: 4,
    border,
    color,
    background: bg,
    cursor: "pointer",
  });

  if (isLoading) return <div style={{ textAlign:"center", padding:"40px 0", color:C.textMuted }}>Loading alerts...</div>;

  return (
    <div>
      <div style={{ display:"grid", gridTemplateColumns:"repeat(3,1fr)", gap:14, marginBottom:22 }}>
        <StatCard label="Emergency Alerts" value={emergency} delta="Unacknowledged" accent="#E74C3C" borderColor={C.red} />
        <StatCard label="High Alerts"      value={high}      delta="Active"          accent="#F39C12" borderColor={C.amber} />
        <StatCard label="Active Total"     value={active.length} delta="Needs attention" accent="#58D68D" borderColor={C.green} />
      </div>

      <Section title={`Active Alerts (${active.length})`}>
        {active.length > 0 ? active.map(a => (
          <div key={a.id} style={{ display:"flex", alignItems:"flex-start", gap:12, paddingBottom:16, marginBottom:16, borderBottom:`1px solid ${C.border}` }}>
            <div style={{
              width:8, height:8, borderRadius:"50%",
              background: a.risk_level==='EMERGENCY' ? C.red : C.amber,
              marginTop:5, flexShrink:0,
              boxShadow: a.risk_level==='EMERGENCY' ? "0 0 6px rgba(192,57,43,0.6)" : "none",
            }} />
            <div style={{ flex:1 }}>
              <div style={{ fontSize:13, fontWeight:500, color:C.textMain, marginBottom:2 }}>
                {a.patients?.name || a.phone || 'Patient'} <Badge level={a.risk_level} />
              </div>
              <div style={{ fontSize:12, color:C.textMuted }}>{a.message}</div>
              <div style={{ fontSize:11, color:C.textDim, marginTop:4, fontFamily:"monospace" }}>
                {new Date(a.created_at).toLocaleString('en-KE')} · {(a.symptoms||[]).join(', ') || 'No symptoms listed'}
              </div>
            </div>
            <div style={{ display:"flex", gap:6, flexShrink:0 }}>
              <button
                onClick={() => navigate(`/patients/${a.patient_id}`)}
                style={btnStyle("rgba(45,125,210,0.1)", C.accentLight, "1px solid rgba(45,125,210,0.4)")}
              >
                View Patient
              </button>
              <button
                onClick={() => ackMutation.mutate(a.id)}
                disabled={a.status === 'acknowledged'}
                style={{ ...btnStyle("rgba(45,125,210,0.1)", C.accentLight, "1px solid rgba(45,125,210,0.4)"), opacity: a.status==='acknowledged' ? 0.5 : 1 }}
              >
                {a.status === 'acknowledged' ? 'Acknowledged' : 'Acknowledge'}
              </button>
              <button
                onClick={() => resolveMutation.mutate(a.id)}
                style={btnStyle("rgba(39,174,96,0.1)", "#58D68D", "1px solid rgba(39,174,96,0.4)")}
              >
                Resolve
              </button>
            </div>
          </div>
        )) : (
          <div style={{ textAlign:"center", padding:"32px 0", color:C.textMuted, fontSize:13 }}>
            ✓ All alerts resolved
          </div>
        )}
      </Section>
    </div>
  );
}
