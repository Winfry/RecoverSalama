import { C } from '../../theme';

export default function StatCard({ label, value, delta, accent, icon: Icon }) {
  return (
    <div style={{
      background: C.surface,
      border: `1px solid ${C.border}`,
      borderRadius: 12,
      padding: '20px',
      display: 'flex',
      flexDirection: 'column',
      gap: 8,
    }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
        <div style={{ fontSize: 12, fontWeight: 500, color: C.textMuted }}>{label}</div>
        {Icon && (
          <div style={{
            width: 32, height: 32, borderRadius: 8,
            background: accent ? `${accent}18` : C.primaryLight,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon size={16} color={accent || C.primary} strokeWidth={1.8} />
          </div>
        )}
      </div>
      <div style={{ fontSize: 30, fontWeight: 700, color: accent || C.textMain, lineHeight: 1 }}>
        {value ?? '—'}
      </div>
      {delta && (
        <div style={{ fontSize: 11, color: C.textMuted }}>{delta}</div>
      )}
    </div>
  );
}
