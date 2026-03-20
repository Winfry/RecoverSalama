/**
 * React Query hook for patient data.
 * Used by PatientList and PatientDetail screens.
 */

import { useQuery } from '@tanstack/react-query';
import { getPatients, getPatient } from '../services/api';

export function usePatients(hospitalId) {
  return useQuery({
    queryKey: ['patients', hospitalId],
    queryFn: () => getPatients(hospitalId).then((r) => r.data),
  });
}

export function usePatient(patientId) {
  return useQuery({
    queryKey: ['patient', patientId],
    queryFn: () => getPatient(patientId).then((r) => r.data),
    enabled: !!patientId,
  });
}
