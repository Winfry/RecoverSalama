/**
 * Risk level badge — color-coded indicator used throughout the dashboard.
 * GREEN = LOW, AMBER = MEDIUM, RED = HIGH, DARK RED = EMERGENCY
 */

const colors = {
  LOW: 'bg-green-100 text-green-700',
  MEDIUM: 'bg-amber-100 text-amber-700',
  HIGH: 'bg-red-100 text-red-700',
  EMERGENCY: 'bg-red-200 text-red-900 font-bold',
};

export default function RiskBadge({ level }) {
  return (
    <span
      className={`inline-block px-2 py-1 rounded-full text-xs font-medium ${
        colors[level] || colors.LOW
      }`}
    >
      {level}
    </span>
  );
}
