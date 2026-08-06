# Migration Best Practices

- Keep migrations reversible when practical.
- Keep each migration focused on one logical change.
- Consider backward compatibility and deployment order for high-availability environments.
- Separate schema and data changes when possible.
- Add indexes carefully on large tables to avoid long locks.
- Use descriptive migration names.
- Commit migrations to version control.
- Never edit or delete a migration already applied to a remote project; migration runners skip migrations already recorded as applied.
- For changes to an applied migration, create a new corrective migration in dependency order.
