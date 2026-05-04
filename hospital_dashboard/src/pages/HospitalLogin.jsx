import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../services/supabase';
import { C } from '../theme';

export default function HospitalLogin() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    const { data, error: authError } = await supabase.auth.signInWithPassword({ email, password });

    if (authError) {
      setError(authError.message);
    } else {
      const token = data.session?.access_token;
      if (token) localStorage.setItem('hospital_token', token);

      let hospitalId = data.user?.user_metadata?.hospital_id || '';
      if (!hospitalId) {
        try {
          const { data: hospitals } = await supabase.from('hospitals').select('id').limit(1);
          if (hospitals?.length > 0) hospitalId = hospitals[0].id;
        } catch (_) {}
      }
      localStorage.setItem('hospital_id', hospitalId);
      navigate('/');
    }
    setLoading(false);
  };

  return (
    <div style={{
      minHeight: '100vh',
      background: C.bg,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: 24,
    }}>
      <div style={{ display: 'flex', gap: 0, width: '100%', maxWidth: 860, borderRadius: 16, overflow: 'hidden', boxShadow: '0 4px 40px rgba(0,0,0,0.08)', border: `1px solid ${C.border}` }}>

        {/* Left: illustration panel */}
        <div style={{
          flex: 1,
          background: `linear-gradient(140deg, ${C.primary} 0%, #009E87 60%, #007A68 100%)`,
          padding: '48px 40px',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          minWidth: 0,
        }}>
          {/* Logo */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 36, height: 36, borderRadius: 10, background: 'rgba(255,255,255,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
                <path d="M10 3v14M3 10h14" stroke="#fff" strokeWidth="2.5" strokeLinecap="round"/>
              </svg>
            </div>
            <div>
              <div style={{ fontSize: 15, fontWeight: 700, color: '#fff' }}>SalamaRecover</div>
              <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.7)', letterSpacing: '0.5px' }}>Clinical Dashboard</div>
            </div>
          </div>

          {/* Hospital illustration SVG */}
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '32px 0' }}>
            <svg viewBox="0 0 280 220" style={{ width: '100%', maxWidth: 280, opacity: 0.9 }} fill="none">
              {/* Building */}
              <rect x="60" y="80" width="160" height="130" rx="4" fill="rgba(255,255,255,0.15)"/>
              <rect x="60" y="80" width="160" height="130" rx="4" stroke="rgba(255,255,255,0.4)" strokeWidth="1.5"/>
              {/* Roof */}
              <path d="M50 82 L140 40 L230 82" stroke="rgba(255,255,255,0.5)" strokeWidth="2" fill="rgba(255,255,255,0.1)"/>
              {/* Cross on roof */}
              <rect x="130" y="50" width="20" height="6" rx="3" fill="rgba(255,255,255,0.8)"/>
              <rect x="137" y="43" width="6" height="20" rx="3" fill="rgba(255,255,255,0.8)"/>
              {/* Door */}
              <rect x="113" y="155" width="34" height="55" rx="4" fill="rgba(255,255,255,0.2)" stroke="rgba(255,255,255,0.4)" strokeWidth="1"/>
              {/* Windows */}
              <rect x="80" y="105" width="30" height="28" rx="3" fill="rgba(255,255,255,0.25)" stroke="rgba(255,255,255,0.4)" strokeWidth="1"/>
              <rect x="170" y="105" width="30" height="28" rx="3" fill="rgba(255,255,255,0.25)" stroke="rgba(255,255,255,0.4)" strokeWidth="1"/>
              <rect x="80" y="145" width="30" height="28" rx="3" fill="rgba(255,255,255,0.15)" stroke="rgba(255,255,255,0.3)" strokeWidth="1"/>
              <rect x="170" y="145" width="30" height="28" rx="3" fill="rgba(255,255,255,0.15)" stroke="rgba(255,255,255,0.3)" strokeWidth="1"/>
              {/* Ground */}
              <line x1="30" y1="210" x2="250" y2="210" stroke="rgba(255,255,255,0.3)" strokeWidth="1.5"/>
              {/* People / dots */}
              <circle cx="46" cy="198" r="6" fill="rgba(255,255,255,0.35)"/>
              <circle cx="234" cy="198" r="6" fill="rgba(255,255,255,0.35)"/>
            </svg>
          </div>

          {/* Bottom tagline */}
          <div>
            <div style={{ fontSize: 20, fontWeight: 700, color: '#fff', marginBottom: 8 }}>
              Surgical Recovery,<br />Intelligently Monitored
            </div>
            <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.75)', lineHeight: 1.6 }}>
              Real-time patient recovery tracking,<br />AI-powered risk alerts for Kenya.
            </div>
          </div>
        </div>

        {/* Right: login form */}
        <div style={{
          width: 380,
          flexShrink: 0,
          background: C.surface,
          padding: '48px 40px',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
        }}>
          <div style={{ marginBottom: 32 }}>
            <div style={{ fontSize: 22, fontWeight: 700, color: C.textMain, marginBottom: 6 }}>
              Welcome back
            </div>
            <div style={{ fontSize: 13, color: C.textMuted }}>
              Sign in to your clinical dashboard
            </div>
          </div>

          <form onSubmit={handleLogin}>
            {error && (
              <div style={{
                background: C.redLight,
                border: `1px solid #FEB2B2`,
                borderRadius: 8,
                padding: '10px 14px',
                fontSize: 13,
                color: C.red,
                marginBottom: 18,
              }}>
                {error}
              </div>
            )}

            <div style={{ marginBottom: 16 }}>
              <label style={{ display: 'block', fontSize: 12, fontWeight: 500, color: C.textMain, marginBottom: 6 }}>
                Email address
              </label>
              <input
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="doctor@hospital.co.ke"
                required
                style={{
                  width: '100%',
                  border: `1px solid ${C.border}`,
                  borderRadius: 8,
                  padding: '10px 14px',
                  fontSize: 13,
                  color: C.textMain,
                  background: C.bg,
                  outline: 'none',
                  fontFamily: 'inherit',
                  boxSizing: 'border-box',
                }}
              />
            </div>

            <div style={{ marginBottom: 24 }}>
              <label style={{ display: 'block', fontSize: 12, fontWeight: 500, color: C.textMain, marginBottom: 6 }}>
                Password
              </label>
              <input
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                style={{
                  width: '100%',
                  border: `1px solid ${C.border}`,
                  borderRadius: 8,
                  padding: '10px 14px',
                  fontSize: 13,
                  color: C.textMain,
                  background: C.bg,
                  outline: 'none',
                  fontFamily: 'inherit',
                  boxSizing: 'border-box',
                }}
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              style={{
                width: '100%',
                background: loading ? C.primaryHover : C.primary,
                border: 'none',
                borderRadius: 8,
                padding: '12px 0',
                fontSize: 14,
                fontWeight: 600,
                color: '#fff',
                cursor: loading ? 'not-allowed' : 'pointer',
                opacity: loading ? 0.8 : 1,
                transition: 'background 0.15s',
              }}
            >
              {loading ? 'Signing in...' : 'Sign In'}
            </button>
          </form>

          <div style={{ textAlign: 'center', marginTop: 28, fontSize: 11, color: C.textDim }}>
            SalamaRecover · Hospital Staff Only
          </div>
        </div>
      </div>
    </div>
  );
}
