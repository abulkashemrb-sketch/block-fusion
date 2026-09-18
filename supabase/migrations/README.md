# Migrations

Run these in filename order against a fresh project. They are the
authoritative record of the schema; each one is idempotent, so re-running a
file is safe.

| File | What it does |
|---|---|
| `0001_profiles_and_scores.sql` | The two tables, their indexes, Row Level Security and its policies, and the two triggers |
| `0002_revoke_trigger_function_execute.sql` | Takes EXECUTE on the trigger functions away from the API roles |

## Why 0002 exists separately

0001 looked safe and passed review. Supabase's security advisor then
reported that both of its `SECURITY DEFINER` trigger functions were exposed
as REST endpoints (`/rest/v1/rpc/handle_new_user`), callable without signing
in — PostgreSQL grants EXECUTE to PUBLIC by default, and a trigger function
inherits that like any other. A trigger runs as the table owner, so revoking
it costs nothing and closes the hole.

The lesson is worth more than the fix: run `get_advisors` after every schema
change rather than trusting a migration because it reads as though it is
safe.

## A note on the Supabase migration ledger

Only 0002 appears in the project's own migration table. 0001 was applied as
raw SQL before the tooling was wired up, so it was never recorded there.
Registering it now would stamp it with a timestamp *after* 0002 and put the
ledger in the wrong order — replaying it would try to revoke on functions
that did not exist yet. The files in this directory are the source of truth;
the ledger is left as it is rather than made confidently wrong.
