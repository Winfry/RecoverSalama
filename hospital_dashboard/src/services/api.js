/**
 * API service — HTTP client for the FastAPI backend.
 *
 * The hospital dashboard calls the same backend as the Flutter app.
 * Hospitals see aggregated patient data, alerts, and analytics.
 */

import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000',
  headers: { 'Content-Type': 'application/json' },
});

// Add auth token to requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('hospital_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// ── Patients ──
export const getPatients = (hospitalId) =>
  api.get('/api/patients', { params: { hospital_id: hospitalId } });

export const getPatient = (id) =>
  api.get(`/api/patients/${id}`);

// ── Alerts ──
export const getAlerts = (hospitalId) =>
  api.get('/api/alerts', { params: { hospital_id: hospitalId } });

export const updateAlert = (alertId, status) =>
  api.patch(`/api/alerts/${alertId}`, null, { params: { status } });

// ── Analytics ──
export const getAnalytics = (hospitalId) =>
  api.get('/api/hospitals/analytics', { params: { hospital_id: hospitalId } });

export default api;
