import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { Search, PlusCircle } from 'lucide-react';
import { getPatients } from '../../services/api';
import { C } from '../../theme';
import Section from '../common/Section';
import Badge from '../common/Badge';

export default function PatientList() {
  const navigate = useNavigate();
  const hospitalId = localStorage.getItem('hospital_id') || undefined;
  const [search, setSearch] = useState('');
  const [riskFilter, setRiskFilter] = useState('all');

  const { data: patients = [], isLoading } = useQuery({
    queryKey: ['patients', hospitalId],
    queryFn: () => getPatients(hospitalId).then((r) => r.data),
  });

  const filtered = patients.filter(p =>
    (p.name?.toLowerCase().includes(search.toLowerCase()) ||
     p.surgery_type?.toLowerCase().includes(search.toLowerCase())) &&
    (riskFilter === 'all' || (p.risk_level || 'LOW').toLowerCase() === riskFilter)
  );

  const riskPills = [
    { value: 'all',       label: 'All' },
    { value: 'emergency', label: 'Emergency' },
    { value: 'high',      label: 'High' },
    { value: 'medium',    label: 'Medium' },
    { value: 'low',       label: 'Low' },
  ];

  if (isLoading) {
    return <div style={{ textAlign: 'center', padding: '60px 0', color: C.textMuted }}>Loading patients...</div>;
  }

  return (
    <div>
      {/* Page header */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 24 }}>
        <div>
          <h1 style={{ fontSize: 20, fontWeight: 700, color: C.textMain, margin: 0 }}>Patients</h1>
          <p style={{ fontSize: 13, color: C.textMuted, margin: '4px 0 0' }}>{patients.length} total patients</p>
        </div>
        <button
          onClick={() => navigate('/discharge')}
          style={{
            display: 'flex', alignItems: 'center', gap: 7,
            background: C.primary, border: 'none', borderRadius: 8,
            padding: '9px 16px', fontSize: 13, fontWeight: 600, color: '#fff', cursor: 'pointer',
          }}
        >
          <PlusCircle size={15} />
          Discharge Patient
        </button>
      </div>

      {/* Filters */}
      <div style={{ display: 'flex', gap: 10, marginBottom: 16, alignItems: 'center' }}>
        <div style={{ flex: 1, position: 'relative' }}>
          <Search size={14} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: C.textDim }} />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search by name or surgery type..."
            style={{
              width: '100%',
              border: `1px solid ${C.border}`,
              borderRadius: 8,
              padding: '9px 12px 9px 34px',
              fontSize: 13,
              color: C.textMain,
              background: C.surface,
              outline: 'none',
              fontFamily: 'inherit',
              boxSizing: 'border-box',
            }}
          />
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          {riskPills.map(({ value, label }) => (
            <button
              key={value}
              onClick={() => setRiskFilter(value)}
              style={{
                padding: '7px 14px',
                borderRadius: 20,
                fontSize: 12,
                fontWeight: riskFilter === value ? 600 : 400,
                border: `1px solid ${riskFilter === value ? C.primary : C.border}`,
                background: riskFilter === value ? C.primaryLight : C.surface,
                color: riskFilter === value ? C.primary : C.textMuted,
                cursor: 'pointer',
              }}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <Section title={`${filtered.length} patients`} noPadBody>
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
          <thead>
            <tr style={{ background: C.bg }}>
              {['Patient', 'Age', 'Surgery Type', 'Recovery Day', 'Check-in', 'Risk', 'Channel'].map(h => (
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
            {filtered.length > 0 ? filtered.map((p, i) => {
              const initials = p.name?.split(' ').map(n => n[0]).join('').slice(0,2).toUpperCase() || '??';
              return (
                <tr
                  key={p.id}
                  style={{ cursor: 'pointer', background: i % 2 === 0 ? C.surface : C.bg }}
                  onClick={() => navigate(`/patients/${p.id}`)}
                  onMouseEnter={e => e.currentTarget.style.background = C.primaryLight}
                  onMouseLeave={e => e.currentTarget.style.background = i % 2 === 0 ? C.surface : C.bg}
                >
                  <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}` }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <div style={{
                        width: 32, height: 32, borderRadius: '50%',
                        background: C.primaryLight,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontSize: 11, fontWeight: 700, color: C.primary, flexShrink: 0,
                      }}>{initials}</div>
                      <span style={{ fontWeight: 600, color: C.textMain }}>{p.name}</span>
                    </div>
                  </td>
                  <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMuted }}>{p.age ?? '—'}</td>
                  <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMain }}>{p.surgery_type}</td>
                  <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMuted }}>
                    {p.days_since_surgery != null ? `Day ${p.days_since_surgery}` : '—'}
                  </td>
                  <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}` }}>
                    <div style={{
                      width: 8, height: 8, borderRadius: '50%',
                      background: p.last_checkin_today ? C.green : C.textDim,
                    }} />
                  </td>
                  <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}` }}>
                    <Badge level={p.risk_level || 'LOW'} />
                  </td>
                  <td style={{ padding: '12px 16px', borderBottom: `1px solid ${C.border}`, color: C.textMuted, fontSize: 12 }}>App</td>
                </tr>
              );
            }) : (
              <tr>
                <td colSpan={7} style={{ padding: '40px 16px', textAlign: 'center', color: C.textMuted, fontSize: 13 }}>
                  {patients.length === 0 ? 'No patients yet. Discharge a patient to get started.' : 'No patients match your search.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Section>
    </div>
  );
}
