/**
 * React Query hook for alert data.
 * Polls every 30 seconds as backup to Supabase Realtime.
 */

import { useQuery } from '@tanstack/react-query';
import { getAlerts } from '../services/api';

export function useAlerts(hospitalId) {
  return useQuery({
    queryKey: ['alerts', hospitalId],
    queryFn: () => getAlerts(hospitalId).then((r) => r.data),
    refetchInterval: 30000,
  });
}
