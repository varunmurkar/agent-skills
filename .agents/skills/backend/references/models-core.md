# Model and Schema Core

## Core Principles

- Use schema-first changes with explicit migrations.
- Keep schema and application model code synchronized.
- Use constraints and validations for defense in depth.
- Balance normalization with practical query performance.
- Define relationships and cascade behavior explicitly.
- Choose data types that match real data use.

## Data Access Patterns

- Prefer reusable query scopes over duplicated inline conditions.
- Use eager loading to prevent N+1 patterns.
- Analyze query plans for performance-sensitive paths.
- Process large datasets in batches.

## Model Design

- Keep callbacks lightweight and predictable.
- Move complex business logic to dedicated service/domain layers.
- Cover associations, validations, scopes, and callback side effects in tests.

## Conditional Tenant Guidance

- Apply tenant partition-key scoping only for multi-tenant projects.
- For single-tenant projects, skip tenant-specific filters and headers.
