/**
 * Hospital Dashboard Navigation Bar.
 * Shows: Dashboard | Patients | Alerts | Analytics
 * Alert badge shows count of unacknowledged alerts.
 */

import { Link, useLocation } from 'react-router-dom';

const navItems = [
  { path: '/', label: 'Dashboard', icon: '📊' },
  { path: '/patients', label: 'Patients', icon: '👥' },
  { path: '/alerts', label: 'Alerts', icon: '🚨' },
  { path: '/analytics', label: 'Analytics', icon: '📈' },
];

export default function NavBar() {
  const location = useLocation();

  return (
    <nav className="bg-white border-b border-gray-200 px-6 py-3">
      <div className="max-w-7xl mx-auto flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="text-xl">💚</span>
          <span className="font-bold text-[#0077B6] text-lg">
            SalamaRecover
          </span>
          <span className="text-xs text-gray-400 ml-2">Hospital Dashboard</span>
        </div>

        <div className="flex items-center gap-6">
          {navItems.map((item) => (
            <Link
              key={item.path}
              to={item.path}
              className={`flex items-center gap-1 text-sm font-medium px-3 py-2 rounded-lg transition ${
                location.pathname === item.path
                  ? 'bg-blue-50 text-[#0077B6]'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              <span>{item.icon}</span>
              {item.label}
            </Link>
          ))}
        </div>
      </div>
    </nav>
  );
}
