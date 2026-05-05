# Test Writing Core

- Focus first on core user flows and primary behavior.
- Avoid exhaustive edge-case expansion during early implementation unless business-critical.
- Test behavior rather than implementation details.
- Use clear, descriptive test names.
- Mock/stub external dependencies for isolation.
- Keep unit-level tests fast and frequently runnable.

## Cost Discipline

- Prefer fast transactional tests by default.
- Escalate to non-transactional tests only when the behavior depends on real DB, session, role, or schema boundaries.
- In expensive non-transactional specs, share stable infrastructure setup per file and reset mutable rows/state between examples.
- Prefer targeted row resets or truncation over dropping and recreating schemas or databases when schema shape is unchanged.
- When a heavy service is not the subject under test, seed the minimal rows needed directly instead of replaying the full service stack.
- Reuse helpers and shared contexts for repeated setup infrastructure, but keep expectations local so test intent stays obvious.
