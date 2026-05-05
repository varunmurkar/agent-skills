# Migration Best Practices

- Keep migrations reversible when practical.
- Keep each migration focused on one logical change.
- Consider backward compatibility and deployment order for high-availability environments.
- Separate schema and data changes when possible.
- Add indexes carefully on large tables to avoid long locks.
- Use descriptive migration names.
- Commit migrations to version control and avoid rewriting deployed migrations.
