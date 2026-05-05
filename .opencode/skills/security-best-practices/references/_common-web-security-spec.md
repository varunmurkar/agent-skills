# Common Web Security Spec

Shared rules for framework-specific web security references. Read this before any `*-web-*-security.md` file; framework files add stack-specific baselines, sinks, detection hints, and fixes.

## 0) Safety, boundaries, and anti-abuse constraints (MUST FOLLOW)

- MUST NOT request, output, log, or commit secrets: API keys, passwords, private keys, session secrets/cookies, JWTs, tokens, database URLs with credentials, signing keys, client secrets.
- MUST NOT "fix" security by disabling protections: weakening auth/cookie flags, disabling CSRF for cookie-auth apps, enabling permissive CORS, trusting proxy headers from open internet, turning on prod debug/stack traces, disabling TLS verification without documented replacement, removing validation, removing auth checks.
- MUST provide evidence-based audit findings: cite file paths, code snippets/config values, middleware/routes/functions, line numbers, and runtime assumptions.
- MUST treat uncertainty honestly: if protection may exist outside app code (reverse proxy, gateway, WAF, CDN, service mesh, platform config), report `not visible in app code; verify at runtime/config`.
- MUST prefer vetted libraries and platform controls over custom crypto/auth/session/CSRF/security code.
- MUST keep fixes minimal, correct, and production-safe; warn before breaking auth/session/proxy flows.

## 1) Operating modes

### 1.1 Generation mode (default)

When writing/modifying code:

- Follow every MUST requirement in common + framework spec.
- Follow SHOULD requirements unless user explicitly overrides.
- Prefer safe-by-default APIs and proven libraries.
- Avoid introducing risky sinks: shell execution, dynamic code/eval, unsafe deserialization, untrusted template rendering, serving user files as HTML, unsafe redirects, unsafe filesystem paths, arbitrary outbound fetch/SSRF endpoints, weak crypto, unbounded parsing.

### 1.2 Passive review mode (while editing)

While working in covered repo, notice violations in touched/nearby code even if user did not ask for scan. Mention high-impact issues with brief explanation + safe fix.

### 1.3 Active audit mode (explicit scan request)

When user asks to scan/audit/hunt vulns:

- Systematically search for common + framework-specific violations.
- Output structured findings using §2.3 format.
- Prioritize exploitable, evidence-backed findings over speculative hardening.

## 2) Definitions and review guidance

### 2.1 Untrusted input

Treat input as attacker-controlled unless proven otherwise. Examples: request path/query/body/headers/cookies, uploads, WebSocket messages, webhooks, third-party API data, message queue events, persisted user content, and deployment/config values that may be attacker-influenced in some environments.

Framework files list stack-specific objects and parsing caveats.

### 2.2 State-changing request

Request is state-changing if it can create/update/delete data, change auth/session state, trigger side effects (purchase, email, webhook), or initiate privileged actions.

### 2.3 Required audit finding format

For each issue:

- Rule ID:
- Severity: Critical / High / Medium / Low
- Location: file path + function/route/handler/middleware name + line(s)
- Evidence: exact code/config snippet
- Impact: what could go wrong, who can exploit it
- Fix: safe change; prefer minimal diff
- Mitigation: defense-in-depth if immediate fix hard
- False positive notes: what to verify if uncertain (edge config, proxy behavior, auth assumptions)

## Common SSRF Rule

Server-side request forgery risk exists when attacker-influenced URL/host/path controls outbound server requests.

Require:
- allowlist trusted destinations when feasible
- restrict schemes to expected values, usually `https`
- block private, loopback, link-local, multicast, and cloud metadata IP ranges after DNS resolution
- re-check redirects; do not let redirect escape allowlist
- set timeouts, size limits, and response handling limits
- avoid forwarding credentials/secrets to attacker-controlled destinations

Audit hints:
- search outbound HTTP clients/fetches and webhook/callback delivery
- trace whether URL/host/path comes from request/user/persisted user data
- check DNS rebinding and redirect behavior, not only string prefixes

Framework refs keep API-specific examples and remediation code.

## Common CSP Rule

CSP is defense-in-depth for browser-facing HTML. Highest-value directive is `script-src`; avoid `unsafe-inline` and `unsafe-eval` unless documented and constrained.

Require/Prefer:
- set CSP for apps rendering HTML or untrusted content
- prioritize `script-src` and `object-src 'none'`
- use nonces/hashes for inline scripts when needed
- use `frame-ancestors` or equivalent clickjacking control
- do not treat CSP as substitute for output encoding/sanitization

Framework refs keep framework-specific header APIs and caveats.
