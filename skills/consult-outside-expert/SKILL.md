---
name: consult-outside-expert
description: |
  Get a second opinion via Codex MCP. Use for stress-testing ideas, getting fresh perspective,
  steelmanning arguments, or iteratively refining work through expert back-and-forth.
  Invoke only when the user explicitly asks for an outside/external expert,
  Codex-as-second-opinion, or a consultation loop. Do not trigger for generic
  code review, PR review, drift checks, or normal "review my work" requests.
triggers:
  # Direct invocations
  - consult outside expert
  - outside expert
  - /consult
  # Codex-specific
  - ask codex
  - ask codex for a second opinion
  - use codex as reviewer
  - codex sparring
  - codex second opinion
  - codex feedback
  # Expert consultation
  - expert consultation
  - outside expert review
  - expert feedback
  - get expert input
  - external consultation
  - external expert review
  - outside expert feedback
  # Second opinion / fresh perspective
  - second opinion
  - another perspective
  - fresh perspective
  - different angle
  - outside perspective
  - external perspective
  # Stress testing / validation
  - stress test
  - pressure test
  - sanity check
  - reality check
  - gut check
  - sense check
  - validate my thinking
  # Informal / conversational
  - bounce this off
  - run this by
  - get outside feedback on
  # Refinement / convergence
  - cross-agent refinement
  - dual-agent convergence
  - iterative refinement
  - steelman
  # Questions and capability discovery
  - can I get feedback
  - can I consult
  - how do I get expert
  - should I consult
---

# consult-outside-expert

Open `@references/guide.md` and follow it. Do not proceed without it.

Use outside expert to refine work through iterative back-and-forth. Use for:
- fresh perspective
- stress-test from different angle
- steelmanning ideas
- progressive convergence on best outcome

Do not use for fresh PR/code reviews. Use `../pr-review/SKILL.md` unless the
user explicitly asks for an external/second-opinion reviewer.

Guide contains:
- consultation loop + mediator role
- round templates + expert prompts
- convergence gates + quality criteria
- eval checks + failure modes
- working log templates (manual + MCP modes)
