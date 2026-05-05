---
name: supabase
description: "Use when doing ANY task involving Supabase. Triggers: Supabase products (Database, Auth, Edge Functions, Realtime, Storage, Vectors, Cron, Queues); client libraries and SSR integrations (supabase-js, @supabase/ssr) in Next.js, React, SvelteKit, Astro, Remix; auth issues (login, logout, sessions, JWT, cookies, getSession, getUser, getClaims, RLS); Supabase CLI or MCP server; schema changes, migrations, security audits, Postgres extensions (pg_graphql, pg_cron, pg_vector)."
metadata:
  author: supabase
  version: "0.1.0"
---

# Supabase

## Core Principles

**1. Supabase changes often. Verify current docs before implementing.**
Do not rely on training data for Supabase features. Function signatures, `config.toml` settings, and API conventions change by version. Look up relevant docs before implementing.

**2. Verify your work.**
After any fix, run a test query to confirm behavior. Unverified fix is incomplete.

**3. Recover from errors, don't loop.**
If approach fails after 2-3 attempts, stop and reconsider. Try different method, check docs, inspect error, review logs when available. Supabase issues rarely improve by repeating same command; logs are not always sufficient but often useful.

**4. RLS by default in exposed schemas.**
Enable RLS on every table in exposed schemas, especially `public`. Tables in exposed schemas can be reachable through Data API. For private schemas, prefer RLS as defense in depth. After enabling RLS, create policies matching actual access model; do not default every table to same `auth.uid()` pattern.

**5. Security checklist.**
For Supabase tasks touching auth, RLS, views, storage, or user data, check these Supabase-specific traps:

- **Auth and session security**
   - **Never use `user_metadata` claims in JWT-based authorization decisions.** In Supabase, `raw_user_meta_data` is user-editable and can appear in `auth.jwt()`, so unsafe for RLS policies or any authz logic. Store authz data in `raw_app_meta_data` / `app_metadata` instead.
   - **Deleting a user does not invalidate existing access tokens.** Sign out or revoke sessions first, keep JWT expiry short for sensitive apps, and for strict guarantees validate `session_id` against `auth.sessions` on sensitive operations.
   - **If you use `app_metadata` or `auth.jwt()` for authorization, remember JWT claims are not always fresh until user's token refreshes.**

- **API key and client exposure**
   - **Never expose `service_role` or secret key in public clients.** Prefer publishable keys for frontend code. Legacy `anon` keys are compatibility only. In Next.js, any `NEXT_PUBLIC_` env var is browser-exposed.

- **RLS, views, and privileged database code**
   - **Views bypass RLS by default.** In Postgres 15+, use `CREATE VIEW ... WITH (security_invoker = true)`. In older Postgres, protect views by revoking access from `anon` and `authenticated`, or putting them in unexposed schema.
   - **UPDATE requires SELECT policy.** In Postgres RLS, UPDATE first needs SELECT row access. Without SELECT policy, updates silently return 0 rows; no error.
   - **Do not put `security definer` functions in exposed schema.** Keep them in private or otherwise unexposed schema.

- **Storage access control**
   - **Storage upsert requires INSERT + SELECT + UPDATE.** INSERT-only allows new uploads but replacement (upsert) silently fails. Need all three.

For other security concerns, fetch Supabase product security index: `https://supabase.com/docs/guides/security/product-security.md`

**6. Use the neutral Postgres specialist for database optimization.**
For SQL queries, schema design, indexes, RLS performance, connection pooling, query tuning, locks, or Postgres diagnostics, also load `../postgres-best-practices/SKILL.md`.

## Supabase CLI

Discover commands via `--help`; never guess. CLI changes by version.

```bash
supabase --help                    # All top-level commands
supabase <group> --help            # Subcommands (e.g., supabase db --help)
supabase <group> <command> --help  # Flags for a specific command
```

Known gotchas:
- `supabase db query` requires CLI v2.79.0+ -> use MCP `execute_sql` or `psql` fallback
- `supabase db advisors` requires CLI v2.81.3+ -> use MCP `get_advisors` fallback
- For new migration SQL file, always run `supabase migration new <name>` first. Never invent migration filename or rely on remembered format.

Version check: `supabase --version`. For changelogs/version-specific features, consult [CLI documentation](https://supabase.com/docs/reference/cli/introduction) or [GitHub releases](https://github.com/supabase/cli/releases).

## Supabase MCP Server

Setup: [MCP setup guide](https://supabase.com/docs/guides/getting-started/mcp).

Troubleshoot connection issues in order:

1. **Check server reachability:**
   `curl -so /dev/null -w "%{http_code}" https://mcp.supabase.com/mcp`
   `401` expected without token and means server is up. Timeout/connection refused means possible outage.

2. **Check `.mcp.json` config:**
   Verify project root has valid `.mcp.json` with correct server URL. If missing, create pointing to `https://mcp.supabase.com/mcp`.

3. **Authenticate MCP server:**
   If server reachable and `.mcp.json` correct but tools hidden, user must authenticate. Supabase MCP uses OAuth 2.1. Tell user to trigger auth flow in agent, complete browser flow, reload session.

## Supabase Documentation

Before implementing Supabase feature, find relevant docs. Priority:

1. MCP `search_docs` tool (preferred; returns snippets directly)
2. Fetch docs pages as markdown by appending `.md` to URL path
3. Web search for Supabase-specific topics when page unknown

## Making and Committing Schema Changes

For schema changes, use `execute_sql` (MCP) or `supabase db query` (CLI). These run SQL directly without migration history entries, so you can iterate freely and generate clean migration when ready.

Do NOT use `apply_migration` for local schema iteration. It writes migration history on every call; then `supabase db diff` / `supabase db pull` can produce empty or conflicting diffs. If used, you're stuck with first SQL passed.

When ready to commit migration file:

1. Run advisors -> `supabase db advisors` (CLI v2.81.3+) or MCP `get_advisors`. Fix issues.
2. Review Security Checklist above if changes involve views, functions, triggers, or storage.
3. Generate migration -> `supabase db pull <descriptive-name> --local --yes`
4. Verify -> `supabase migration list --local`

## Reference Guides

- **Skill Feedback** -> [references/skill-feedback.md](references/skill-feedback.md)
  **MUST read when** user reports this skill gave incorrect guidance or missed information.
