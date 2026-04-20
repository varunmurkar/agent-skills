# Testing Standards Core

## Structure

- Organize tests by layer (API/request, service/domain, policy/authorization, integration).
- Reuse helpers/fixtures/traits to reduce duplication.
- Extract repeated infrastructure setup into focused helpers/shared contexts, not broad assertion abstractions.

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
- Shared fixtures outside transactions require explicit reset and teardown discipline.
- Use `before(:context)` or file-scoped shared setup only for costly infrastructure that is stable across examples.
- Track created tenants, users, and other durable resources explicitly for teardown; avoid broad cleanup by naming convention.
- Reset connection-scoped state between examples, including tenant switching, auth/session context, role/session state, and request globals.
- Do not run multiple spec processes concurrently against the same mutable test database unless isolation is guaranteed.

## Conditional Tenant Guidance

- Apply tenant-context header and scoping tests only for multi-tenant projects.
- For single-tenant projects, skip tenant-specific header/scoping checks.
