/**
 * Alert count badge — shows number of unacknowledged alerts.
 * Appears on the Alerts nav item.
 */

export default function AlertBadge({ count }) {
  if (!count || count === 0) return null;

  return (
    <span className="inline-flex items-center justify-center w-5 h-5 text-xs font-bold text-white bg-red-500 rounded-full">
      {count > 99 ? '99+' : count}
    </span>
  );
}
