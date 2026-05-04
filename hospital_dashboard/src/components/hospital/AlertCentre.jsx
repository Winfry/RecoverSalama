import { useEffect, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { Bell, AlertTriangle, CheckCircle } from 'lucide-react';
import { getAlerts, updateAlert } from '../../services/api';
import { subscribeToAlerts } from '../../services/supabase';
import { C } from '../../theme';
import StatCard from '../common/StatCard';
import Badge from '../common/Badge';

export default function AlertCentre() {
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const hospitalId = localStorage.getItem('hospital_id') || undefined;
  const [filter, setFilter] = useState('all');

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

  const filterPills = [
    { value: 'all',       label: `All (${active.length})` },
    { value: 'emergency', label: `Emergency (${emergency})` },
    { value: 'high',      label: `High (${high})` },
  ];

  const displayed = filter === 'all'
    ? active
    : active.filter(a => a.risk_level.toLowerCase() === filter);

  if (isLoading) return <div style={{ textAlign: 'center', padding: '60px 0', color: C.textMuted }}>Loading alerts...</div>;

  return (
    <div>
      {/* Page header */}
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 20, fontWeight: 700, color: C.textMain, margin: 0 }}>Alert Centre</h1>
        <p style={{ fontSize: 13, color: C.textMuted, margin: '4px 0 0' }}>Real-time patient alerts — refreshes every 30s</p>
      </div>

      {/* Stat cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 16, marginBottom: 24 }}>
        <StatCard label="Emergency Alerts" value={emergency} delta="Needs immediate attention" accent={C.red}    icon={AlertTriangle} />
        <StatCard label="High Alerts"       value={high}      delta="Active"                   accent={C.amber}  icon={Bell} />
        <StatCard label="Total Active"      value={active.length} delta="Unresolved"           accent={C.primary} icon={CheckCircle} />
      </div>

      {/* Filter pills */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        {filterPills.map(({ value, label }) => (
          <button
            key={value}
            onClick={() => setFilter(value)}
            style={{
              padding: '7px 16px', borderRadius: 20, fontSize: 12,
              fontWeight: filter === value ? 600 : 400,
              border: `1px solid ${filter === value ? C.primary : C.border}`,
              background: filter === value ? C.primaryLight : C.surface,
              color: filter === value ? C.primary : C.textMuted,
              cursor: 'pointer',
            }}
          >
            {label}
          </button>
        ))}
      </div>

      {/* Alert list */}
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, overflow: 'hidden' }}>
        {displayed.length > 0 ? displayed.map((a, i) => (
          <div
            key={a.id}
            style={{
              display: 'flex', alignItems: 'flex-start', gap: 14,
              padding: '18px 20px',
              borderBottom: i < displayed.length - 1 ? `1px solid ${C.border}` : 'none',
              background: a.risk_level === 'EMERGENCY' ? '#FFF5F5' : C.surface,
            }}
          >
            {/* Risk dot */}
            <div style={{
              width: 10, height: 10, borderRadius: '50%', flexShrink: 0,
              background: a.risk_level === 'EMERGENCY' ? C.red : C.amber,
              marginTop: 4,
              boxShadow: a.risk_level === 'EMERGENCY' ? `0 0 8px ${C.red}60` : 'none',
            }} />

            {/* Content */}
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
                <span style={{ fontSize: 14, fontWeight: 600, color: C.textMain }}>
                  {a.patients?.name || a.phone || 'Patient'}
                </span>
                <Badge level={a.risk_level} />
                {a.status === 'acknowledged' && (
                  <span style={{ fontSize: 11, color: C.textMuted, background: C.bg, border: `1px solid ${C.border}`, borderRadius: 4, padding: '1px 7px' }}>
                    Acknowledged
                  </span>
                )}
              </div>
              <div style={{ fontSize: 13, color: C.textMuted, marginBottom: 4 }}>{a.message}</div>
              <div style={{ fontSize: 11, color: C.textDim }}>
                {new Date(a.created_at).toLocaleString('en-KE')}
                {(a.symptoms || []).length > 0 && ` · ${a.symptoms.join(', ')}`}
              </div>
            </div>

            {/* Actions */}
            <div style={{ display: 'flex', gap: 8, flexShrink: 0 }}>
              <button
                onClick={() => navigate(`/patients/${a.patient_id}`)}
                style={{
                  padding: '7px 14px', fontSize: 12, borderRadius: 7, cursor: 'pointer',
                  border: `1px solid ${C.border}`, background: C.surface, color: C.textMain, fontWeight: 500,
                }}
              >
                View Patient
              </button>
              <button
                onClick={() => ackMutation.mutate(a.id)}
                disabled={a.status === 'acknowledged'}
                style={{
                  padding: '7px 14px', fontSize: 12, borderRadius: 7, cursor: a.status === 'acknowledged' ? 'default' : 'pointer',
                  border: `1px solid ${C.border}`, background: C.surface, color: C.textMuted,
                  opacity: a.status === 'acknowledged' ? 0.5 : 1,
                }}
              >
                {a.status === 'acknowledged' ? 'Acknowledged' : 'Acknowledge'}
              </button>
              <button
                onClick={() => resolveMutation.mutate(a.id)}
                style={{
                  padding: '7px 14px', fontSize: 12, borderRadius: 7, cursor: 'pointer',
                  border: `1px solid ${C.green}`, background: C.greenLight, color: C.green, fontWeight: 600,
                }}
              >
                Resolve
              </button>
            </div>
          </div>
        )) : (
          <div style={{ textAlign: 'center', padding: '48px 0', color: C.textMuted, fontSize: 13 }}>
            All alerts resolved
          </div>
        )}
      </div>
    </div>
  );
}
