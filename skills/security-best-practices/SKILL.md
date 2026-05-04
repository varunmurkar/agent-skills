---
name: "security-best-practices"
description: "Perform language and framework specific security best-practice reviews and suggest improvements. Trigger only when the user explicitly requests security best practices guidance, a security review/report, or secure-by-default coding help. Do not trigger for general code review, debugging, or non-security tasks."
---

# Security Best Practices

## Overview

Identify language/frameworks in scope, then load matching reference docs from this skill's `references/` directory.

Use guidance to write secure-by-default code, passively detect major issues, or produce requested vulnerability report + fixes.

## Workflow

1. Identify ALL languages and ALL frameworks requested or present in project scope. Focus on primary core frameworks. For web apps, often identify both frontend and backend.
2. Check `references/` for matching docs. Read ALL files relevant to specific language/framework. Filename shape: `<language>-<framework>-<stack>-security.md`.
3. Also check `<language>-general-<stack>-security.md` for framework-agnostic guidance.
4. For web apps with frontend + backend, check BOTH sides.
5. If building web app and frontend framework unspecified, also read `javascript-general-web-frontend-security.md`.
6. If no matching reference exists, use known language/framework security best practices. If producing report, state concrete guidance is unavailable; still report certain critical vulnerabilities if found.

Modes:

1. Primary: write secure-by-default code from this point forward.
2. Passive: flag critical/high-impact secure-default violations while working. Focus on largest-impact vulnerabilities.
3. Report: if user asks for security report or hardening, produce prioritized report with clear severity/urgency sections, then offer fixes. See #fixes.

## Workflow Decision Tree

- If language/framework unclear, inspect repo and list evidence.
- If matching `references/` guidance exists, load only relevant files and follow them.
- If no match, use known best practices where confident. For reports, disclose lack of concrete reference guidance; still report definite critical vulnerabilities.

# Overrides

Project docs/prompts may require bypassing a best practice. Follow project-specific rules. You MAY note override to user, but do not fight them. Suggest documenting why bypass exists so future agents follow it.

# Report Format

Write report to `security_best_practices_report.md` unless user gives another path. Ask location if needed.

Report requirements:
- short executive summary first
- sections by vulnerability severity
- focus on critical findings first; highest user impact
- numeric ID per finding
- one-sentence impact statement for critical findings
- code references with line numbers

After writing report, summarize findings to user, less verbose OK. Include final report path. Offer to explain findings/rationale.

# Fixes

If report produced, let user read it and ask to begin fixes.

If passive critical finding found, notify user and ask whether to fix.

When fixing:
- fix one finding at a time
- add concise comments only where useful, citing specific best practice and brief danger
- consider functionality/regression impact before changing behavior
- avoid quick/slapdash security changes that break project behavior
- follow configured change/commit flow
- if committing, use clear messages explaining best-practice alignment
- avoid grouping unrelated findings in one commit
- follow test flow; verify no regressions
- warn user about second-order impacts before making risky changes

# General Security Advice

### Avoid Using Incrementing IDs for Public IDs of Resources

For internet-exposed resource IDs, avoid small auto-incrementing IDs. Use UUID4 or long random hex string to prevent quantity inference and ID guessing.

### A note on TLS

TLS matters in prod, but most dev work has TLS disabled or external TLS proxy. Be careful not to report lack of TLS as issue. Be careful with `secure` cookies: set only when app actually uses TLS. On non-TLS local/dev/test, secure cookies break app. Env/config flag can keep secure off until TLS prod deploy. Avoid recommending HSTS; it is dangerous without full understanding of lasting impact (major outages/user lockout) and generally out of scope for reviewed projects.
