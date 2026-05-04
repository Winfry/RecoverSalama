import { Link, useLocation, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Users, Bell, BarChart2, FileText, BookOpen, Settings, LogOut } from 'lucide-react';
import { C } from '../../theme';

const navItems = [
  { path: '/',          label: 'Dashboard', icon: LayoutDashboard },
  { path: '/patients',  label: 'Patients',  icon: Users },
  { path: '/alerts',    label: 'Alerts',    icon: Bell,     badge: true },
  { path: '/analytics', label: 'Analytics', icon: BarChart2 },
  { path: '/discharge', label: 'Discharge', icon: FileText },
  { path: '/reference', label: 'Reference', icon: BookOpen },
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
      position: 'fixed',
      top: 0,
      left: 0,
      width: C.sidebarW,
      height: '100vh',
      background: C.surface,
      borderRight: `1px solid ${C.border}`,
      display: 'flex',
      flexDirection: 'column',
      zIndex: 100,
      boxSizing: 'border-box',
    }}>
      {/* Logo */}
      <div style={{ padding: '24px 20px 20px', borderBottom: `1px solid ${C.border}` }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10,
            background: C.primary,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
          }}>
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
              <path d="M10 3v14M3 10h14" stroke="#fff" strokeWidth="2.5" strokeLinecap="round"/>
            </svg>
          </div>
          <div>
            <div style={{ fontSize: 14, fontWeight: 700, color: C.textMain, lineHeight: 1.2 }}>SalamaRecover</div>
            <div style={{ fontSize: 10, color: C.textMuted, letterSpacing: '0.5px' }}>Clinical Dashboard</div>
          </div>
        </div>
      </div>

      {/* Nav links */}
      <div style={{ flex: 1, padding: '12px 12px', overflowY: 'auto' }}>
        {navItems.map(({ path, label, icon: Icon, badge }) => {
          const active = location.pathname === path ||
            (path !== '/' && location.pathname.startsWith(path));
          return (
            <Link
              key={path}
              to={path}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 10,
                padding: '10px 12px',
                borderRadius: 8,
                fontSize: 13,
                fontWeight: active ? 600 : 400,
                color: active ? C.primary : C.textMuted,
                background: active ? C.primaryLight : 'transparent',
                textDecoration: 'none',
                marginBottom: 2,
                transition: 'all 0.15s',
                position: 'relative',
              }}
            >
              <Icon size={16} strokeWidth={active ? 2.2 : 1.8} />
              <span style={{ flex: 1 }}>{label}</span>
              {badge && (
                <span style={{
                  width: 7, height: 7, borderRadius: '50%',
                  background: C.red, flexShrink: 0,
                }} />
              )}
            </Link>
          );
        })}

        <div style={{ margin: '8px 0', borderTop: `1px solid ${C.border}` }} />

        <Link
          to="/settings"
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            padding: '10px 12px',
            borderRadius: 8,
            fontSize: 13,
            fontWeight: 400,
            color: C.textMuted,
            background: 'transparent',
            textDecoration: 'none',
          }}
        >
          <Settings size={16} strokeWidth={1.8} />
          Settings
        </Link>
      </div>

      {/* User footer */}
      <div style={{ padding: '16px 12px', borderTop: `1px solid ${C.border}` }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
          <div style={{
            width: 32, height: 32, borderRadius: '50%',
            background: C.primaryLight,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 12, fontWeight: 600, color: C.primary, flexShrink: 0,
          }}>
            DR
          </div>
          <div style={{ overflow: 'hidden' }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: C.textMain, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              Hospital Staff
            </div>
            <div style={{ fontSize: 10, color: C.textMuted }}>
              {new Date().toLocaleDateString('en-KE', { day: '2-digit', month: 'short' })}
            </div>
          </div>
        </div>
        <button
          onClick={handleLogout}
          style={{
            width: '100%',
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            padding: '8px 10px',
            borderRadius: 7,
            border: `1px solid ${C.border}`,
            background: 'transparent',
            fontSize: 12,
            color: C.textMuted,
            cursor: 'pointer',
          }}
        >
          <LogOut size={14} />
          Sign out
        </button>
      </div>
    </nav>
  );
}
