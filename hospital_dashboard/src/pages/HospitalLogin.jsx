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

  const inputStyle = {
    width: "100%",
    background: C.navy,
    border: `1px solid ${C.border}`,
    borderRadius: 6,
    color: C.textMain,
    padding: "10px 14px",
    fontSize: 13,
    outline: "none",
    fontFamily: "inherit",
    boxSizing: "border-box",
  };

  return (
    <div style={{ minHeight:"100vh", background:C.bg, display:"flex", alignItems:"center", justifyContent:"center" }}>
      <div style={{ width:"100%", maxWidth:380, background:C.surface, border:`1px solid ${C.border}`, borderRadius:10, padding:32 }}>
        {/* Logo */}
        <div style={{ textAlign:"center", marginBottom:28 }}>
          <div style={{
            width:44, height:44, borderRadius:10, margin:"0 auto 12px",
            background:"linear-gradient(135deg, #2D7DD2, #27AE60)",
            display:"flex", alignItems:"center", justifyContent:"center",
            fontSize:20, fontWeight:700, color:"#fff",
          }}>S</div>
          <div style={{ fontSize:18, fontWeight:700, color:C.textMain }}>SalamaRecover</div>
          <div style={{ fontSize:11, color:C.textDim, marginTop:4, letterSpacing:"0.8px", textTransform:"uppercase" }}>
            Clinical Dashboard
          </div>
        </div>

        <form onSubmit={handleLogin}>
          {error && (
            <div style={{ background:"rgba(192,57,43,0.15)", border:"1px solid rgba(192,57,43,0.3)", borderRadius:6, padding:"10px 14px", fontSize:12, color:"#E74C3C", marginBottom:16 }}>
              {error}
            </div>
          )}

          <div style={{ marginBottom:14 }}>
            <label style={{ display:"block", fontSize:11, color:C.textMuted, marginBottom:6, textTransform:"uppercase", letterSpacing:"0.6px" }}>
              Email
            </label>
            <input
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              style={inputStyle}
              placeholder="doctor@hospital.co.ke"
              required
            />
          </div>

          <div style={{ marginBottom:22 }}>
            <label style={{ display:"block", fontSize:11, color:C.textMuted, marginBottom:6, textTransform:"uppercase", letterSpacing:"0.6px" }}>
              Password
            </label>
            <input
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              style={inputStyle}
              placeholder="••••••••"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            style={{
              width:"100%",
              background: C.accent,
              border:"none",
              borderRadius:6,
              padding:"11px 0",
              fontSize:13,
              fontWeight:600,
              color:"#fff",
              cursor: loading ? "not-allowed" : "pointer",
              opacity: loading ? 0.7 : 1,
            }}
          >
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        <div style={{ textAlign:"center", marginTop:20, fontSize:11, color:C.textDim }}>
          SalamaRecover · Hospital Staff Only
        </div>
      </div>
    </div>
  );
}
