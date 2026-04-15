import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
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

  const inputStyle = {
    flex: 1,
    background: C.surface,
    border: `1px solid ${C.border}`,
    borderRadius: 6,
    padding: "8px 14px",
    fontSize: 13,
    color: C.textMain,
    outline: "none",
    fontFamily: "inherit",
  };

  if (isLoading) {
    return <div style={{ textAlign:"center", padding:"40px 0", color:C.textMuted }}>Loading patients...</div>;
  }

  return (
    <div>
      <div style={{ display:"flex", gap:10, marginBottom:18 }}>
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Search patients by name or surgery type..."
          style={inputStyle}
        />
        <select
          value={riskFilter}
          onChange={e => setRiskFilter(e.target.value)}
          style={{ ...inputStyle, flex:"none", width:160 }}
        >
          <option value="all">All Risk Levels</option>
          <option value="emergency">Emergency</option>
          <option value="high">High</option>
          <option value="medium">Medium</option>
          <option value="low">Low</option>
        </select>
      </div>

      <Section
        title={`${filtered.length} Patients`}
        action="+ Discharge new patient"
        onAction={() => navigate('/discharge')}
        noPadBody
      >
        <table style={{ width:"100%", borderCollapse:"collapse", fontSize:12 }}>
          <thead>
            <tr>
              {["Patient Name","Age","Surgery Type","Recovery Day","Check-in Today","Risk Level","Channel"].map(h => (
                <th key={h} style={{ textAlign:"left", padding:"0 12px 10px", fontSize:10, fontWeight:600, color:C.textDim, textTransform:"uppercase", letterSpacing:"0.8px" }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {filtered.length > 0 ? filtered.map(p => (
              <tr
                key={p.id}
                style={{ cursor:"pointer" }}
                onClick={() => navigate(`/patients/${p.id}`)}
                onMouseEnter={e => e.currentTarget.style.background = C.navyLight}
                onMouseLeave={e => e.currentTarget.style.background = "transparent"}
              >
                <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, fontWeight:500, color:C.textMain }}>{p.name}</td>
                <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, color:C.textMain }}>{p.age ?? '—'}</td>
                <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, color:C.textMain }}>{p.surgery_type}</td>
                <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, color:C.textMain, fontFamily:"monospace" }}>
                  {p.days_since_surgery != null ? `Day ${p.days_since_surgery}` : '—'}
                </td>
                <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}` }}>
                  <div style={{ width:10, height:10, borderRadius:"50%", background: C.green }} />
                </td>
                <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}` }}>
                  <Badge level={p.risk_level || 'LOW'} />
                </td>
                <td style={{ padding:"10px 12px", borderTop:`1px solid ${C.border}`, color:C.textMuted }}>App</td>
              </tr>
            )) : (
              <tr>
                <td colSpan={7} style={{ padding:"32px 12px", textAlign:"center", color:C.textMuted, fontSize:13 }}>
                  {patients.length === 0 ? "No patients yet. Discharge a patient to get started." : "No patients match your search."}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Section>
    </div>
  );
}
