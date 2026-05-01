-- =============================================================
-- SMS Auth: таблица для хранения OTP-кодов (SMSC.ru)
-- Выполнить в Supabase SQL Editor
-- =============================================================

CREATE TABLE IF NOT EXISTS public.phone_otps (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  phone text NOT NULL,
  code text NOT NULL,
  expires_at timestamptz NOT NULL,
  verified boolean DEFAULT false,
  attempts int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_phone_otps_phone ON public.phone_otps(phone);
CREATE INDEX IF NOT EXISTS idx_phone_otps_expires ON public.phone_otps(expires_at);

ALTER TABLE public.phone_otps ENABLE ROW LEVEL SECURITY;

-- Только service role может читать/писать в эту таблицу.
-- anon/authenticated пользователи не имеют доступа.
DROP POLICY IF EXISTS "Service role only" ON public.phone_otps;
CREATE POLICY "Service role only" ON public.phone_otps
  FOR ALL USING (false);

-- Автоочистка: удалять записи старше 1 часа (если pg_cron доступен)
-- SELECT cron.schedule(
--   'cleanup_expired_otps',
--   '*/30 * * * *',
--   $$DELETE FROM public.phone_otps WHERE expires_at < now() - interval '1 hour'$$
-- );
