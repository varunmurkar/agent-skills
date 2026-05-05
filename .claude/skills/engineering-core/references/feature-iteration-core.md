# Feature Iteration Core

Use for modifying existing behavior.

## Recon and Impact

- Confirm objective and failing/target scenarios.
- Reproduce current behavior and map entry points.
- Identify affected contracts, dependencies, and risks.

## Change Discipline

- Keep diffs surgical and maintain runnable states.
- Reuse existing architecture boundaries.
- Update downstream consumers that depend on changed behavior.

## Regression Control

- Validate modified and adjacent code paths.
- Update tests with the behavior change.
- Define rollback and mitigation steps before release.
