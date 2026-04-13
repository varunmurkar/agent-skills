# Feature Implementation Core

Use for net-new capabilities.

## Recon and Planning

- Capture objectives, acceptance criteria, and rollout plan.
- Survey repository patterns and impacted dependencies.
- Record risks and open questions before coding.

## Delivery Strategy

- Build in runnable layers from data to interfaces.
- Prefer extending existing abstractions before creating new ones.
- Use flags for incremental rollout when risk warrants.

## Quality Gates

- Run lint/tests/manual checks before handoff.
- Sync API contracts, user-visible copy, and telemetry.
- Document rollback options before merge.
