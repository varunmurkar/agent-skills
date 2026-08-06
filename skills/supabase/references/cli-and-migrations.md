# Supabase CLI and Migration Guidance

Apply these rules to any Supabase project.

## CLI

- Use `bunx supabase`, not a globally installed CLI.
- Work against the linked remote project. Do not use local Supabase commands when the task changes or verifies the project database.
- Discover version-specific commands with `bunx supabase <command> --help` before using unfamiliar flags.

## Migrations

- Create new migration files with `bunx supabase migration new <name>`.
- Never edit or delete a migration already applied to a remote project. Supabase records applied migrations and skips them on later pushes.
- For a change to an applied migration, create a new corrective migration after it in migration order.
- Keep each migration focused and safe to run against the linked remote project.
- End schema-changing migrations with:

```sql
NOTIFY pgrst, 'reload schema';
```

## Verification

- Push or apply migrations through the linked remote project, then check remote migration status.
- Verify changed tables, functions, policies, or columns through the remote database/API after migration.
