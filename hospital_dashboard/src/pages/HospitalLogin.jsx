/**
 * Hospital Login Screen (H1)
 *
 * Hospital staff log in with their credentials.
 * Uses Supabase Auth with hospital-specific role.
 */

import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../services/supabase';

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

    const { data, error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (authError) {
      setError(authError.message);
    } else {
      // Store the JWT token so api.js interceptor can attach it to requests
      const token = data.session?.access_token;
      if (token) {
        localStorage.setItem('hospital_token', token);
      }

      // Fetch the hospital_id linked to this staff member's user account.
      // We look up the patients table for a hospital linked to this user,
      // or fall back to a hospitals table lookup by user metadata.
      // For now we store the user's metadata hospital_id if present.
      const hospitalId = data.user?.user_metadata?.hospital_id || '';
      localStorage.setItem('hospital_id', hospitalId);

      navigate('/');
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="w-full max-w-md p-8 bg-white rounded-2xl shadow-sm border border-gray-200">
        <div className="text-center mb-8">
          <span className="text-4xl">💚</span>
          <h1 className="text-2xl font-bold text-[#0077B6] mt-2">
            SalamaRecover
          </h1>
          <p className="text-gray-500 text-sm mt-1">Hospital Dashboard Login</p>
        </div>

        <form onSubmit={handleLogin} className="space-y-4">
          {error && (
            <div className="p-3 bg-red-50 text-red-600 text-sm rounded-lg">
              {error}
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#0077B6] focus:border-transparent"
              placeholder="doctor@hospital.co.ke"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Password
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#0077B6] focus:border-transparent"
              placeholder="••••••••"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 bg-[#0077B6] text-white font-semibold rounded-lg hover:bg-[#005a8d] transition disabled:opacity-50"
          >
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>
      </div>
    </div>
  );
}
