import { C } from '../../theme';

export default function StatCard({ label, value, delta, accent, borderColor }) {
  return (
    <div style={{
      background: C.surface,
      border: `1px solid ${C.border}`,
      borderTop: `2px solid ${borderColor || C.accent}`,
      borderRadius: 8,
      padding: "16px 18px",
    }}>
      <div style={{ fontSize: 11, color: C.textMuted, textTransform: "uppercase", letterSpacing: "0.8px", marginBottom: 8 }}>
        {label}
      </div>
      <div style={{ fontSize: 28, fontWeight: 600, color: accent || C.textMain, fontFamily: "monospace", lineHeight: 1 }}>
        {value}
      </div>
      <div style={{ fontSize: 11, color: C.textMuted, marginTop: 6 }}>{delta}</div>
    </div>
  );
}
