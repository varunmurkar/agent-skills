---
name: ralph-lisa-loop
description: |
  Automated plan-implement loop with expert review. Orchestrator dispatches subagents
  for planning/implementation and self-review, Codex for external review. The human steers.
  A single rope-length knob (0-5) controls interruption frequency. Subagent architecture
  keeps the orchestrator's context window lean for completing tasks in a single session.
  Use for any planning, development, or implementation task that benefits from structured review.
triggers:
  # Direct invocations
  - /ralph-lisa-loop
  - /ralph-lisa
  - /ralph
  - ralph-lisa loop
  - ralph loop
  - ralph lisa
  # Planning
  - plan this
  - let's plan
  - make a plan
  - plan with expert
  - plan and build
  - plan-implement cycle
  - plan then implement
  - plan then build
  # Plan-only
  - plan only
  - just plan
  - design review
  - RFC review
  # Development / implementation
  - build this
  - implement this
  - implement with expert
  - build with expert review
  # Implement-only
  - just implement
  - just build
  - skip planning
  # Codex review
  - codex review
  - get codex to review
  - have codex review
  - review with codex
  - expert review loop
  # Automation emphasis
  - automated review loop
  - autonomous review loop
---

# ralph-lisa-loop

## Preflight

Do not enter round loop until all checks pass.

### Step 1: Stop hook check

Read `~/.claude/settings.json`; find `Stop` hook pointing to this skill's `scripts/stop-hook.sh`.

If missing, tell user:

> The ralph-lisa loop works best with the stop hook installed - it keeps the loop
> running automatically so you don't have to type "continue" each round. The hook
> is dormant when no loop session is active (it checks for a session file and
> exits immediately if none exists).
>
> Want me to add it to your settings?

If yes, add under `hooks.Stop` in `~/.claude/settings.json` (create path if missing):

```json
{
  "matcher": "",
  "hooks": [{
    "type": "command",
    "command": "SKILL_SCRIPTS_DIR/stop-hook.sh",
    "timeout": 10000
  }]
}
```

Replace `SKILL_SCRIPTS_DIR` with absolute path to this skill's `scripts/` directory.

If declined, proceed Manual tier; user types "continue" between rounds. Note tier in first round summary. If hook already installed, proceed silently.

### Step 2: Codex reviewer channel check

Probe Codex MCP availability: search tools for `mcp__codex__codex`, or attempt lightweight call. Do not inspect config source; may be project `.mcp.json`, user MCP settings, or harness.

- `mcp__codex__codex` available -> record `reviewer_backend: mcp`, `review_channel_status: mcp_ready`; proceed.
- Unavailable -> check `which codex`.
  - CLI exists -> offer MCP config:
    > Codex MCP isn't available in this session. I can add it for you:
    >
    > 1. **User-level** - available in all projects
    > 2. **Project-level** - scoped to this repo
    > 3. **Skip** - use `codex exec` CLI fallback (slower, session-based persistence)
    >
    > Which do you prefer?

    Options 1/2: run command, then stop. Do not enter loop. Tell user restart Claude Code + re-invoke; preflight will find MCP.
    ```bash
    # User-level
    claude mcp add --scope user --transport stdio codex -- codex mcp-server

    # Project-level
    claude mcp add --scope project --transport stdio codex -- codex mcp-server
    ```

    Option 3: record `reviewer_backend: exec`, `review_channel_status: exec_opt_in`; proceed with downgrade logged.
  - No CLI -> hard stop:
    > The ralph-lisa loop requires Codex as reviewer. Install: `npm i -g @openai/codex`
    > Then either restart (I'll offer to configure MCP) or ensure the CLI is in your PATH.

### Step 3: Reasoning policy initialization

Confirm rope length and inform user:

> Reasoning policy: xhigh for all rounds, with detailed reasoning summaries.

## Protocol

Open `@references/guide.md` and follow it. Do not proceed without it.

Use for:
- stress-tested plans via parallel ideation + convergence
- per-round implementation review with zero-finding close gate
- rope-length autonomy: 0 approve everything, 5 full auto
- walk-away execution with decisions in session file
- one-context-window execution

Guide contains:
- orchestrator + subagents: planner/implementor, self-reviewer, Codex reviewer
- round mechanics: implement, self-review, external review, reconcile, synthesize, gate check
- subagent prompts + dispatch patterns
- plan context loading rules
- rope-length semantics + salience scoring
- stable finding/dispute IDs
- close gate + anti-gaming constraints
- plan -> implement transition + decisions ledger
- Round 1 parallel ideation independence
- session file + continuation block format
- stop hook integration
- prompt pack: `@references/prompts.md`
- session template: `@references/session-template.md`
- eval checks + failure modes
