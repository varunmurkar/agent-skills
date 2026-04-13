# Component Heuristics

- One component should have one clear purpose.
- Prefer composition over option-heavy monolith components.
- Expose explicit stable interfaces.
- Hide implementation details.
- Keep state close to where it is used.
- Use intent-revealing names.

## Extraction Criteria

- Pattern repeats or is likely to repeat.
- Pattern has multiple dynamic states worth testing.
- Reuse improves correctness and consistency.

## Documentation Expectations

- Document intent, required inputs, and usage example.
- Keep public component APIs small and stable.
