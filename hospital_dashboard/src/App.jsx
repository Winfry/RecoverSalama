/**
 * Hospital Dashboard App — Root Component
 *
 * This is the React web app that hospital clinical staff use on their
 * desktop or tablet to monitor discharged patients.
 *
 * They can see:
 * - Which patients have been discharged
 * - Daily check-in data and risk levels
 * - Alerts for HIGH/EMERGENCY patients
 * - Analytics on readmission rates
 *
 * Deployed on Vercel (free tier).
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

export default function App() {
  return (
    <div className="min-h-screen bg-gray-50">
      <Routes>
        {/* Login — no navbar */}
        <Route path="/login" element={<HospitalLogin />} />

        {/* Dashboard routes — with navbar */}
        <Route
          path="/*"
          element={
            <>
              <NavBar />
              <main className="max-w-7xl mx-auto px-4 py-6">
                <Routes>
                  <Route path="/" element={<DashboardHome />} />
                  <Route path="/patients" element={<PatientList />} />
                  <Route path="/patients/:id" element={<PatientDetail />} />
                  <Route path="/alerts" element={<AlertCentre />} />
                  <Route path="/analytics" element={<Analytics />} />
                  <Route path="/discharge" element={<DischargeForm />} />
                  <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
              </main>
            </>
          }
        />
      </Routes>
    </div>
  );
}
