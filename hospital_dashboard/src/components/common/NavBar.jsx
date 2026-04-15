import { Link, useLocation, useNavigate } from 'react-router-dom';
import { C } from '../../theme';

const navItems = [
  { path: '/',          label: 'Overview',  icon: '◈' },
  { path: '/patients',  label: 'Patients',  icon: '⊞' },
  { path: '/alerts',    label: 'Alerts',    icon: '⚠' },
  { path: '/analytics', label: 'Analytics', icon: '↗' },
  { path: '/discharge', label: 'Discharge', icon: '+' },
];

export default function NavBar() {
  const location = useLocation();
  const navigate = useNavigate();

  const handleLogout = () => {
    localStorage.removeItem('hospital_token');
    localStorage.removeItem('hospital_id');
    navigate('/login');
  };

  return (
    <nav style={{
      background: C.navy,
      borderBottom: `1px solid ${C.border}`,
      padding: "0 24px",
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      height: 52,
      position: "sticky",
      top: 0,
      zIndex: 100,
    }}>
      {/* Logo */}
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <div style={{
          width: 28, height: 28, borderRadius: 6,
          background: "linear-gradient(135deg, #2D7DD2, #27AE60)",
          display: "flex", alignItems: "center", justifyContent: "center",
          fontSize: 14, fontWeight: 700, color: "#fff",
        }}>S</div>
        <div>
          <div style={{ fontSize: 13, fontWeight: 700, color: C.textMain, lineHeight: 1 }}>SalamaRecover</div>
          <div style={{ fontSize: 9, color: C.textDim, letterSpacing: "0.8px", textTransform: "uppercase" }}>Clinical Dashboard</div>
        </div>
      </div>

      {/* Nav links */}
      <div style={{ display: "flex", alignItems: "center", gap: 2 }}>
        {navItems.map((item) => {
          const active = location.pathname === item.path ||
            (item.path !== '/' && location.pathname.startsWith(item.path));
          return (
            <Link
              key={item.path}
              to={item.path}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 6,
                padding: "6px 14px",
                borderRadius: 6,
                fontSize: 12,
                fontWeight: active ? 600 : 400,
                color: active ? C.accentLight : C.textMuted,
                background: active ? "rgba(45,125,210,0.12)" : "transparent",
                textDecoration: "none",
                transition: "all 0.15s",
              }}
            >
              <span style={{ fontSize: 11 }}>{item.icon}</span>
              {item.label}
            </Link>
          );
        })}
      </div>

      {/* Right side */}
      <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
        <div style={{ fontSize: 11, color: C.textDim }}>
          {new Date().toLocaleDateString('en-KE', { weekday: 'short', day: '2-digit', month: 'short' })}
        </div>
        <button
          onClick={handleLogout}
          style={{
            background: "transparent",
            border: `1px solid ${C.border}`,
            borderRadius: 6,
            padding: "5px 12px",
            fontSize: 11,
            color: C.textMuted,
            cursor: "pointer",
          }}
        >
          Sign out
        </button>
      </div>
    </nav>
  );
}
