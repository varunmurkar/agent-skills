# Query Best Practices

- Prevent injection through parameterization or safe query APIs.
- Avoid N+1 query behavior with eager loading/joins.
- Select only needed columns.
- Index columns used by filter/join/order patterns.
- Use transactions for related writes requiring consistency.
- Set query timeouts for runaway query protection.
- Cache expensive and frequently repeated reads when justified.
