import { C } from '../../theme';

export default function Section({ title, action, onAction, children, noPadBody }) {
  return (
    <div style={{
      background: C.surface,
      border: `1px solid ${C.border}`,
      borderRadius: 8,
      marginBottom: 18,
    }}>
      <div style={{
        padding: "14px 18px",
        borderBottom: `1px solid ${C.border}`,
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
      }}>
        <span style={{ fontSize: 13, fontWeight: 600, color: C.textMain }}>{title}</span>
        {action && (
          <span
            style={{ fontSize: 11, color: C.accentLight, cursor: "pointer" }}
            onClick={onAction}
          >
            {action}
          </span>
        )}
      </div>
      <div style={noPadBody ? {} : { padding: 18 }}>{children}</div>
    </div>
  );
}
