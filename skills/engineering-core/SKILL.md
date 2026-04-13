---
name: engineering-core
description: use for cross-cutting engineering rules that are language/framework-agnostic, including communication, verification, validation, dependency choices, documentation quality, and feature lifecycle discipline.
---

# Intent

Provide a single source-of-truth for reusable engineering guidance that applies across projects.

## Activation Rules

- Default assumptions: single-tenant and no special regulatory regime.
- Enable tenant-specific guidance only when either condition is true:
  - user explicitly requests multi-tenant behavior, or
  - repo evidence shows multi-tenant architecture.
- Enable regulation/compliance guidance only when either condition is true:
  - user explicitly requests a specific compliance regime, or
  - repo docs/config explicitly declare compliance requirements.
- Do not add tenant or compliance overhead when these conditions are not met.

## Workflow

1. Load `references/communication.md` and `references/coding-style-core.md` for baseline execution quality.
2. Load `references/verification-core.md` and `references/validation-core.md` when changing behavior.
3. Load `references/dependencies-core.md` when adding/updating third-party tooling.
4. Load `references/documentation-core.md` when producing or updating documentation.
5. Load `references/error-handling-core.md` when defining or revising failure behavior.
6. Load one of the feature lifecycle references based on task type:
   - net-new work: `references/feature-implementation-core.md`
   - refactor/modify: `references/feature-iteration-core.md`
   - deletion/sunset: `references/feature-removal.md`
7. Load `references/analytics-monitoring-core.md` only when telemetry/observability is touched.
8. Load `references/tenant-isolation-conditional.md` only when tenant guidance is enabled.
9. Load `references/compliance-conditional.md` only when compliance guidance is enabled.
10. If the task includes DB/schema/migration/query design on Postgres, require loading `../supabase-postgres-best-practices/SKILL.md` before finalizing implementation decisions.

## Multi-Tenant Detection Signals

Treat multi-tenant as enabled only with concrete evidence, such as:
- tenant partition keys (`tenant_id`, `account_id`, `org_id`, similar)
- tenant context helpers/middleware
- tenant context headers
- tenant-scoped authorization/policies
- row-level tenant isolation rules
