import { badge } from '../../theme';

export default function Badge({ level }) {
  const s = badge(level);
  return (
    <span style={{
      ...s,
      padding: '3px 8px',
      borderRadius: 6,
      fontSize: 11,
      fontWeight: 600,
      letterSpacing: '0.3px',
      display: 'inline-block',
    }}>
      {(level || 'LOW').toUpperCase()}
    </span>
  );
}
