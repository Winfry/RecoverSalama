/**
 * Hospital Dashboard App — Root Component
 */

import { Routes, Route, Navigate } from 'react-router-dom';
import HospitalLogin from './pages/HospitalLogin';
import DashboardHome from './components/hospital/DashboardHome';
import PatientList from './components/hospital/PatientList';
import PatientDetail from './components/hospital/PatientDetail';
import AlertCentre from './components/hospital/AlertCentre';
import Analytics from './components/hospital/Analytics';
import DischargeForm from './components/hospital/DischargeForm';
import NavBar from './components/common/NavBar';

/**
 * ProtectedRoute — redirects to /login if no auth token is present.
 * Hospital staff must be logged in to see any patient data.
 */
function ProtectedRoute({ children }) {
  const token = localStorage.getItem('hospital_token');
  if (!token) {
    return <Navigate to="/login" replace />;
  }
  return children;
}

export default function App() {
  return (
    <div className="min-h-screen bg-gray-50">
      <Routes>
        {/* Login — no navbar, no auth required */}
        <Route path="/login" element={<HospitalLogin />} />

        {/* All dashboard routes — require auth */}
        <Route
          path="/*"
          element={
            <ProtectedRoute>
              <>
                <NavBar />
                <main className="max-w-7xl mx-auto px-4 py-6">
                  <Routes>
                    <Route path="/" element={<DashboardHome />} />
                    <Route path="/patients" element={<PatientList />} />
                    <Route path="/patients/:id" element={<PatientDetail />} />
                    <Route path="/patients/:id/discharge" element={<DischargeForm />} />
                    <Route path="/alerts" element={<AlertCentre />} />
                    <Route path="/analytics" element={<Analytics />} />
                    <Route path="/discharge" element={<DischargeForm />} />
                    <Route path="*" element={<Navigate to="/" replace />} />
                  </Routes>
                </main>
              </>
            </ProtectedRoute>
          }
        />
      </Routes>
    </div>
  );
}
