import { badge } from '../../theme';

export default function Badge({ level }) {
  const s = badge(level);
  return (
    <span style={{
      ...s,
      padding: "3px 8px",
      borderRadius: 4,
      fontSize: 10,
      fontWeight: 600,
      letterSpacing: "0.5px",
      textTransform: "uppercase",
      display: "inline-block",
    }}>
      {(level || 'LOW').toUpperCase()}
    </span>
  );
}
