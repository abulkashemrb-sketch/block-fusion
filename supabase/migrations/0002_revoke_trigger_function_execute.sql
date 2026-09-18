-- Both functions below are trigger functions. A trigger runs them as the
-- table owner regardless of who holds EXECUTE, so the API roles never need
-- it — but PostgreSQL grants EXECUTE to PUBLIC by default, which left them
-- callable by anyone as /rest/v1/rpc/handle_new_user and
-- /rest/v1/rpc/sync_best_score, signed in or not. They are SECURITY
-- DEFINER, so that is an opening nobody needs.
--
-- Found by Supabase's security advisor after 0001 was applied, which is
-- the argument for running it after every schema change rather than
-- trusting a migration to be safe because it looks safe.

revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.sync_best_score() from public, anon, authenticated;
