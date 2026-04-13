# Debugging Core

## Principles

- Use structured diagnosis: recon -> isolate -> gather evidence -> identify root cause -> remediate.
- Fix root causes; avoid superficial patches.
- Report unrelated issues instead of silently changing scope.

## Workflow

- Verify environment consistency between shell/runtime/test contexts.
- Reproduce failures reliably before implementing fixes.
- Map dependency chains for asynchronous or integration failures.
- Add targeted logging and bounded timeouts before making behavior changes.
