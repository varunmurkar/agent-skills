# Testing Standards Core

## Structure

- Organize tests by layer (API/request, service/domain, policy/authorization, integration).
- Reuse helpers/fixtures/traits to reduce duplication.

## Writing and Assertions

- Cover both success and failure behavior for each feature/bugfix.
- Keep assertions focused on one primary behavior per example.
- Prefer helper matchers over repeated literal payloads.
- Verify contracts (status, envelope/shape, key headers) for API-level behavior.

## Isolation and Reliability

- Avoid live external service calls in automated tests.
- Freeze/mock nondeterministic inputs such as time/randomness.
- Ensure test data does not leak across examples.
- Avoid brittle assertions tied to irrelevant implementation details.

## Conditional Tenant Guidance

- Apply tenant-context header and scoping tests only for multi-tenant projects.
- For single-tenant projects, skip tenant-specific header/scoping checks.
