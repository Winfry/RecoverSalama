import { C } from '../../theme';

export default function Section({ title, action, onAction, children, noPadBody }) {
  return (
    <div style={{
      background: C.surface,
      border: `1px solid ${C.border}`,
      borderRadius: 12,
      marginBottom: 16,
      overflow: 'hidden',
    }}>
      <div style={{
        padding: '16px 20px',
        borderBottom: `1px solid ${C.border}`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
      }}>
        <span style={{ fontSize: 14, fontWeight: 600, color: C.textMain }}>{title}</span>
        {action && (
          <span
            style={{ fontSize: 12, color: C.primary, cursor: 'pointer', fontWeight: 500 }}
            onClick={onAction}
          >
            {action}
          </span>
        )}
      </div>
      <div style={noPadBody ? {} : { padding: '20px' }}>{children}</div>
    </div>
  );
}
