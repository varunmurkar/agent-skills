---
name: pr-review
description: framework-agnostic procedural executor for pre-merge quality gates defined by the active PR review playbook
---

## Intent

Provide one reusable PR-review procedure while letting project overlays define concrete gates.

## Procedure

1. Load playbook context
   - Resolve active playbook/index from project standards overlays.

2. Establish baseline
   - Determine target branch from PR context.
   - Inspect changed files and diff scope.

3. Execute gates in declared order
   - Run each configured check command.
   - Treat gates by role even when tool names differ by stack:
     - style/static-quality gate (for example `rubocop`, `eslint`, `ruff`) -> linter/formatter/static analysis
     - security gate (for example `brakeman`, `semgrep`, `bandit`, `npm audit`) -> security scanner
     - AI review gate (for example `coderabbit review`, equivalent AI review tooling) -> AI code review
   - Stop on blockers unless explicit risk acceptance is documented.

4. Triage AI review feedback critically
   - Never apply suggestions blindly.
   - Classify each suggestion as `accept`, `reject`, or `defer`.
   - Evaluate against correctness, project conventions, regression risk, and test impact.
   - For CodeRabbit specifically:
     - Default to prompt-efficient mode when available (for example `--prompt-only`).
     - Use expanded/plain mode only when detailed human-readable output is explicitly required.

5. Implement accepted changes
   - Keep edits minimal and reversible.
   - Update/add tests for behavior changes.
   - Re-run affected gates.

6. Track deferred work
   - Add each `defer` item to the repository root TODO file (`TODO` or `TODO.md` if present).
   - If no TODO file exists, create `TODO.md` in repo root and append deferred items.

7. Produce final report
   - Summarize commands run, blockers, accepted/rejected/deferred items, and residual risks.

## Operational Rules

- Never accept AI review output without source-level verification.
- Respect project overlays for stack-specific gates.
- Keep fixes small, readable, and reversible.
- If tools conflict, prioritize security and correctness over style.
