import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase.js';
import { requireAuth, AuthenticatedRequest } from '../middleware/auth.js';

export const notificationsRouter = Router();

notificationsRouter.get('/', requireAuth, async (req: AuthenticatedRequest, res) => {
  const { data, error } = await supabaseAdmin
    .from('notifications')
    .select('*, actor:profiles!notifications_actor_id_fkey(id, username, avatar_url, is_verified)')
    .eq('recipient_id', req.user!.id)
    .order('created_at', { ascending: false })
    .limit(50);

  if (error) return res.status(400).json({ error: error.message });

  const { data: followRequests } = await supabaseAdmin
    .from('follow_requests')
    .select('id, created_at, requester:profiles!follow_requests_requester_id_fkey(id, username, full_name, avatar_url)')
    .eq('target_id', req.user!.id)
    .eq('status', 'pending');

  return res.json({
    notifications: data ?? [],
    followRequests: followRequests ?? []
  });
});

notificationsRouter.post('/read', requireAuth, async (req: AuthenticatedRequest, res) => {
  const { notificationIds } = z.object({ notificationIds: z.array(z.string().uuid()).optional() }).parse(req.body ?? {});

  let query = supabaseAdmin.from('notifications').update({ is_read: true }).eq('recipient_id', req.user!.id);
  if (notificationIds && notificationIds.length > 0) {
    query = query.in('id', notificationIds);
  }
  await query;
  return res.json({ markedRead: true });
});

notificationsRouter.post('/push-token', requireAuth, async (req: AuthenticatedRequest, res) => {
  const { pushToken } = z.object({ pushToken: z.string().min(10).max(255) }).parse(req.body);
  await supabaseAdmin.from('profiles').update({ push_token: pushToken }).eq('id', req.user!.id);
  return res.json({ saved: true });
});
