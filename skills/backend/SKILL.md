---
name: backend
description: used when writing backend application logic, APIs, data access, and persistence behavior.
---

# Intent

Backend engineering guidance for API design, migrations, models, and query behavior.

## Workflow

1. Load `../engineering-core/SKILL.md` for baseline cross-cutting rules.
2. Load `references/api-design.md` when changing API contracts.
3. Load `references/migrations-core.md` for schema evolution work.
4. Load `references/models-core.md` for domain model and persistence rules.
5. Load `references/querying-core.md` when writing/optimizing queries.
6. When work touches database schema/tables/migrations/queries and the project uses Postgres, load `supabase-postgres-best-practices` and the relevant local schema/query/security/data references.
7. For DB work, treat the Postgres references as required quality gates for:
   - schema/table design and constraints
   - migration safety and rollback strategy
   - query/index performance
   - RLS and privilege hardening (only when tenant/security context requires it)
