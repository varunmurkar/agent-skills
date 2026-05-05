# Conditional Tenant Isolation Guidance

Apply this guidance only when multi-tenant mode is enabled.

## Tenant Mode Gate

Enable only when:
- explicitly requested, or
- repo evidence shows tenant architecture.

If not enabled, skip all tenant-specific requirements.

## Rules (When Enabled)

- Scope data access using the project tenant partition key (for example `tenant_id`, `org_id`, or `account_id`).
- Enforce tenant-aware authorization boundaries.
- Ensure tenant context is propagated through APIs, jobs, and background workflows.
- Test allowed and forbidden cross-tenant access paths.
- Keep tenant terminology generic unless project overlays define specific names.
