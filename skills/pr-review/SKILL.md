---
name: pr-review
description: |
  Canonical PR/code review entrypoint. Runs pre-merge quality gates, routes to
  review specializations, triages AI review feedback, and reports findings in a
  terse actionable style. Use for "review this PR", "code review", "review the
  diff", "PR review", or "/review".
triggers:
  - review this PR
  - code review
  - review the diff
  - PR review
  - /review
---

## Intent

Provide one reusable PR/code review procedure while letting project overlays define concrete gates. This is the only broad review trigger; load references and specialization skills as needed.

## Required References

1. Load `references/comment-style.md` for finding/comment format.
2. Load `references/review-triage-core.md` for accept/reject/defer rules.

## Routing

1. Existing PR comments/threads
   - If user asks to fix, respond to, resolve, or summarize existing PR review feedback, load `../address-pr-reviews/SKILL.md`.
   - Do not duplicate GitHub review-thread mechanics here.

2. CLI-based quality gates
   - Resolve active project playbook/overlays.
   - Run deterministic gates first: tests, lint/static analysis, typecheck/build, format check, and configured security scanners.
   - Run AI review gates after deterministic gates when configured.
   - Do not run CodeRabbit twice for verification.

3. Code quality, DRY/SOLID, and conventions
   - Load `../engineering-core/SKILL.md`.
   - Load `../backend/SKILL.md`, `../frontend/SKILL.md`, `../postgres-best-practices/SKILL.md`, or other domain skills only when changed files indicate those domains.
   - Prefer project docs and overlays over generic conventions.

4. Security
   - For explicit security review/hardening requests, load `../security-best-practices/SKILL.md`.
   - For general review, flag obvious high-impact security issues and run configured security gates.

5. PRD/spec drift
   - If user asks for PRD/spec drift, requirements alignment, invariants, or spec-vs-code review, load `../check-drift/SKILL.md`.
   - Keep drift checks read-only and report-only.

## Procedure

1. Load references and route specializations
   - Load required references above.
   - Apply routing rules before running gates.

2. Load playbook context
   - Resolve active playbook/index from project standards overlays.

3. Establish baseline
   - Determine target branch from PR context.
   - Inspect changed files and diff scope.

4. Execute gates in declared order
   - Run each configured check command.
   - Treat gates by role even when tool names differ by stack:
     - style/static-quality gate (for example `rubocop`, `eslint`, `ruff`) -> linter/formatter/static analysis
     - security gate (for example `brakeman`, `semgrep`, `bandit`, `npm audit`) -> security scanner
     - AI review gate (for example `coderabbit review`, equivalent AI review tooling) -> AI code review
   - Stop on blockers unless explicit risk acceptance is documented.

5. Triage AI review feedback critically
   - Never apply suggestions blindly.
   - Classify each suggestion as `accept`, `reject`, or `defer`.
   - Evaluate against correctness, project conventions, regression risk, and test impact.
   - For CodeRabbit specifically:
     - Default to prompt-efficient mode when available (for example `--prompt-only`).
     - Use expanded/plain mode only when detailed human-readable output is explicitly required.

6. Implement accepted changes
   - Keep edits minimal and reversible.
   - Update/add tests for behavior changes.
   - Re-run affected gates.

7. Track deferred work
   - Add each `defer` item to the repository root TODO file (`TODO` or `TODO.md` if present).
   - If no TODO file exists, create `TODO.md` in repo root and append deferred items.

8. Produce final report
   - Summarize commands run, blockers, accepted/rejected/deferred items, and residual risks.
   - Findings first, ordered by severity.
   - Use `references/comment-style.md` for line-level review comments.

## Operational Rules

- Never accept AI review output without source-level verification.
- Respect project overlays for stack-specific gates.
- Keep fixes small, readable, and reversible.
- If tools conflict, prioritize security and correctness over style.
- Do not run coderabbit a second time to verify, rate limits will block.
- Do not route fresh review requests to any other review skill unless the request is specifically about existing PR comments/threads.
