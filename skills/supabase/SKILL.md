---
name: supabase
description: "Use when doing ANY task involving Supabase. Triggers: Supabase products (Database, Auth, Edge Functions, Realtime, Storage, Vectors, Cron, Queues); client libraries and SSR integrations (supabase-js, @supabase/ssr) in Next.js, React, SvelteKit, Astro, Remix; auth issues (login, logout, sessions, JWT, cookies, getSession, getUser, getClaims, RLS); Supabase CLI or MCP server; schema changes, migrations, declarative schemas, security audits, Postgres extensions (pg_graphql, pg_cron, pg_vector)."
metadata:
  author: supabase
  version: "0.1.2"
---

# Supabase

## Core Principles

**1. Supabase changes frequently — verify changelog and current docs before implementing.**
Do not rely on training data. Function signatures, config.toml settings, and API conventions change between versions.

First, fetch `https://supabase.com/changelog.md` (lightweight summary index), scan relevant `breaking-change` tags, follow applicable linked pages, then look up the topic using documentation methods below.

**2. Verify your work.**
After any fix, run a test query to confirm it works. Unverified fixes are incomplete.

**3. Recover from errors, don't loop.**
If an approach fails after 2-3 attempts, stop and reconsider. Try a different method, check docs, inspect the error, and review available logs. Do not repeatedly retry the same command.

**4. Exposing tables to the Data API:** Depending on [Data API settings](https://supabase.com/dashboard/project/<ref>/integrations/data_api/settings), new tables may not be exposed via the Data (REST) API. If not, explicitly grant access to `anon` and `authenticated` roles.

> Note that this is separate from RLS, which controls which _rows_ are visible once a table is accessible, not whether the table is accessible at all.

For inaccessible SQL-created tables, check Data API settings and explicit `GRANT` SQL. When granting public (`anon`/`authenticated`) access, also enable RLS. See [Exposing a Table to the Data API](https://supabase.com/docs/guides/api/securing-your-api.md).

**5. RLS in exposed schemas.**
Enable RLS on every table in exposed schemas, including `public` by default. Exposed tables can be reachable through the Data API when `anon`/`authenticated` have access (see [Exposing a Table to the Data API](https://supabase.com/docs/guides/api/securing-your-api.md)). Prefer RLS in private schemas as defense in depth. Create policies matching the actual access model; do not default every table to the same `auth.uid()` pattern.

**6. Security checklist.**
For Supabase tasks touching auth, RLS, views, storage, or user data, check these Supabase-specific security traps:

- **Auth and session security**
  - **Never use `user_metadata` claims in JWT-based authorization decisions.** In Supabase, `raw_user_meta_data` is user-editable and can appear in `auth.jwt()`, so it is unsafe for RLS policies or any other authorization logic. Store authorization data in `raw_app_meta_data` / `app_metadata` instead.
  - **Deleting a user does not invalidate existing access tokens.** Sign out or revoke sessions first, keep JWT expiry short for sensitive apps, and for strict guarantees validate `session_id` against `auth.sessions` on sensitive operations.
  - **`app_metadata` and `auth.jwt()` claims may be stale until the user's token is refreshed.**

- **API key and client exposure**
  - **Never expose `service_role` or secret keys in public clients.** Use publishable keys for frontend code. Legacy `anon` keys are compatibility-only. In Next.js, every `NEXT_PUBLIC_` env var reaches the browser.

- **RLS, views, and privileged database code**
  - **Views bypass RLS by default.** In Postgres 15 and above, use `CREATE VIEW ... WITH (security_invoker = true)`. In older versions of Postgres, protect your views by revoking access from the `anon` and `authenticated` roles, or by putting them in an unexposed schema.
  - **UPDATE requires a SELECT policy.** In Postgres RLS, an UPDATE needs to first SELECT the row. Without a SELECT policy, updates silently return 0 rows — no error, just no change.
  - **`auth.role()` is deprecated — use the `TO` clause instead.** Specify the target role with `TO authenticated` or `TO anon`. `auth.role() = 'authenticated'` breaks silently when anonymous sign-ins are enabled because anonymous users carry the `authenticated` Postgres role.
    ```sql
    -- Deprecated (do not use)
    create policy "example" on table_name for select
    using ( auth.role() = 'authenticated' );
    ```
  - **`TO authenticated` alone is authentication without authorization (BOLA / IDOR).** It checks only the role, not row ownership. Combine it with an ownership predicate in `USING`:
    ```sql
    create policy "example" on table_name for select
    to authenticated
    using ( (select auth.uid()) = user_id );
    ```
  - **UPDATE policies require both `USING` and `WITH CHECK`.** Without `WITH CHECK`, users can reassign a row's `user_id`:
    ```sql
    create policy "example" on table_name for update
    to authenticated
    using ( (select auth.uid()) = user_id )
    with check ( (select auth.uid()) = user_id );
    ```
  - **`SECURITY DEFINER` functions bypass RLS.** They run with creator privileges, often a role with `bypassrls` (e.g., `postgres`). Never use it to resolve permission errors; prefer `SECURITY INVOKER`.
  - **`SECURITY DEFINER` functions in `public` are callable by all roles.** Postgres grants `EXECUTE` to `PUBLIC` by default, making each such function a public API endpoint. If genuinely needed (e.g., bypassing RLS on an internal lookup table), keep it in a non-exposed schema, include an `auth.uid()` check, and run `supabase db advisors`.

- **Storage access control**
  - **Storage upsert requires INSERT + SELECT + UPDATE.** INSERT alone permits new uploads but silently fails on replacement.

- **Dependency and supply-chain security**
  - **Pin package versions and commit lockfiles** when installing Supabase packages (`supabase-js`, `@supabase/ssr`, `supabase-py`, etc.). See the [npm security guide](https://supabase.com/docs/guides/security/npm-security.md).

For other security concerns, fetch the Supabase product security index: `https://supabase.com/docs/guides/security/product-security.md`

## Supabase CLI

Discover commands via `--help`; never guess. CLI structure changes between versions.

```bash
supabase --help                    # All top-level commands
supabase <group> --help            # Subcommands (e.g., supabase db --help)
supabase <group> <command> --help  # Flags for a specific command
```

**Supabase CLI Known gotchas:**

- `supabase db query` requires **CLI v2.79.0+** → use MCP `execute_sql` or `psql` as fallback
- `supabase db advisors` requires **CLI v2.81.3+** → use MCP `get_advisors` as fallback
- In imperative migration projects, create new hand-authored migration files with `supabase migration new <name>` first. Never invent a migration filename or rely on memory for the expected format. Declarative schema projects generate migrations from `supabase/schemas/`; see "Making and Committing Schema Changes" below.

**Version check and upgrade:** Run `supabase --version` to check. For CLI changelogs and version-specific features, consult the [CLI documentation](https://supabase.com/docs/reference/cli/introduction) or [GitHub releases](https://github.com/supabase/cli/releases).

## Supabase MCP Server

See the [MCP setup guide](https://supabase.com/docs/guides/getting-started/mcp) for setup, server URL, and configuration.

**Troubleshooting connection issues** — follow in order:

1. **Check if the server is reachable:**
   `curl -so /dev/null -w "%{http_code}" https://mcp.supabase.com/mcp`
   `401` is expected without a token and means the server is up. Timeout or "connection refused" may mean it is down.

2. **Check `.mcp.json` configuration:**
   Verify project root has valid `.mcp.json` with the correct server URL. If missing, create one pointing to `https://mcp.supabase.com/mcp`.

3. **Authenticate the MCP server:**
   If reachable and `.mcp.json` is correct but tools are missing, authenticate. Supabase MCP uses OAuth 2.1: trigger auth in the agent, complete it in the browser, and reload the session.

## Supabase Documentation

Before implementing Supabase features, find relevant docs in this order:

1. **MCP `search_docs` tool** (preferred — returns relevant snippets directly)
2. **Fetch docs pages as markdown** — any docs page can be fetched by appending `.md` to the URL path.
3. **Web search** for Supabase-specific topics when you don't know which page to look at.

## Making and Committing Schema Changes

First identify the schema workflow.

### Option A: Declarative schemas

Use when `supabase/schemas/` exists or `config.toml` sets `schema_paths`. Edit desired schema state, then generate and review the migration. Do not hand-write one first. See the [Declarative database schemas guide](https://supabase.com/docs/guides/local-development/declarative-database-schemas).

### Option B: Imperative migrations

Use when the project does not use declarative schemas.

**To make schema changes, use `execute_sql` (MCP) or `supabase db query` (CLI).** They run SQL without migration history entries, allowing iteration before generating a clean migration.

Do NOT use `apply_migration` for local schema changes. It writes migration history on every call, preventing iteration; `supabase db diff` / `supabase db pull` then produce empty or conflicting diffs.

**When ready to commit** changes to a migration file:

1. **Run advisors** → `supabase db advisors` (CLI v2.81.3+) or MCP `get_advisors`. Fix any issues.
2. **Review the Security Checklist above** if your changes involve views, functions, triggers, or storage.
3. **Generate the migration** → `supabase db pull <descriptive-name> --local --yes`
4. **Verify** → `supabase migration list --local`

## Reference Guides

- **Skill Feedback** → [references/skill-feedback.md](references/skill-feedback.md)
  **MUST read when** the user reports incorrect or missing guidance from this skill.
