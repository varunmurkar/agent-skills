---
name: engineering-core
description: use for cross-cutting engineering rules that are language/framework-agnostic, including communication, verification, validation, dependency choices, documentation quality, and feature lifecycle discipline.
---

# Intent

Single source-of-truth for reusable engineering guidance across projects.

## Activation Rules

- Default: single-tenant, no special regulatory regime.
- Enable tenant-specific guidance only when user requests multi-tenant behavior or repo evidence shows multi-tenant architecture.
- Enable regulation/compliance guidance only when user requests specific regime or repo docs/config declare compliance requirements.
- Do not add tenant/compliance overhead without those signals.

## Workflow

1. Load `references/communication.md` and `references/coding-style-core.md` for baseline execution quality.
2. Load `references/verification-core.md` and `references/validation-core.md` when changing behavior.
3. Load `references/dependencies-core.md` when adding/updating third-party tooling.
4. Load `../testing/SKILL.md` when writing tests, debugging failures, or reducing suite/runtime cost.
5. Load `references/documentation-core.md` when producing/updating docs.
6. Load `references/error-handling-core.md` when defining/revising failure behavior.
7. Load one feature lifecycle reference by task type:
   - net-new work: `references/feature-implementation-core.md`
   - refactor/modify: `references/feature-iteration-core.md`
   - deletion/sunset: `references/feature-removal.md`
8. Load `references/analytics-monitoring-core.md` only when telemetry/observability touched.
9. Load `references/tenant-isolation-conditional.md` only when tenant guidance enabled.
10. Load `references/compliance-conditional.md` only when compliance guidance enabled.
11. If task includes Postgres DB/schema/migration/query design, load `../postgres-best-practices/SKILL.md` before final implementation decisions.

## Multi-Tenant Detection Signals

Treat multi-tenant as enabled only with concrete evidence:
- tenant partition keys (`tenant_id`, `account_id`, `org_id`, similar)
- tenant context helpers/middleware
- tenant context headers
- tenant-scoped authorization/policies
- row-level tenant isolation rules
