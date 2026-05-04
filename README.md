# agent-skills

Reusable agent skills and companion instruction files for Codex, Claude Code, Cursor, and OpenCode.

## Included skills

Core workflow:

- `engineering-core`
- `backend`
- `frontend`
- `testing`
- `pr-review`
- `consult-outside-expert`
- `address-pr-reviews`

Spec-driven development:

- `spec`
- `build`
- `check`
- `backprop`

Caveman ecosystem:

- `caveman`
- `caveman-commit`
- `caveman-review`
- `compress`

Security and platform:

- `security-best-practices`
- `harden-github-actions`
- `supabase`
- `supabase-postgres-best-practices`

Skill authoring:

- `skill-crafting`
- `find-docs`

## Install

Clone this repository, then run the installer from the repo root.

```bash
./scripts/install-agent-skills.sh --scope project --tool all
```

The script supports two scopes:

- `--scope project`: install into the current repo so the whole team can commit and share the setup.
- `--scope user`: install into your user-level config for personal reuse across repositories.

You can target one tool or several tools at once:

```bash
./scripts/install-agent-skills.sh --scope project --tool codex
./scripts/install-agent-skills.sh --scope user --tool claude,opencode
./scripts/install-agent-skills.sh --scope project --tool cursor --skill backend,frontend
```

The installer is intentionally interactive when it finds collisions.

- Skill and Cursor rule collisions: choose `rename`, `replace`, or `skip`.
- `AGENTS.md` and `CLAUDE.md` collisions: choose `companion`, `replace`, or `skip`.

`companion` keeps the incumbent file and installs agent-skills guidance into a generated companion file, then wires the incumbent file to load it.

## What gets installed

### Codex

- Skills:
  - project: `.agents/skills/<skill>/SKILL.md`
  - user: `~/.agents/skills/<skill>/SKILL.md`
- Guidance:
  - project: `AGENTS.md`
  - user: `${CODEX_HOME:-~/.codex}/AGENTS.md`

### Claude Code

- Skills:
  - project: `.claude/skills/<skill>/SKILL.md`
  - user: `~/.claude/skills/<skill>/SKILL.md`
- Guidance:
  - project: `CLAUDE.md`
  - user: `~/.claude/CLAUDE.md`

### OpenCode

- Skills:
  - project: `.opencode/skills/<skill>/SKILL.md`
  - user: `~/.config/opencode/skills/<skill>/SKILL.md`
- Guidance:
  - project: `AGENTS.md`
  - user: `~/.config/opencode/AGENTS.md`

### Cursor

- Rules generated from the skill content:
  - project: `.cursor/rules/*.mdc`
  - user: `~/.cursor/rules/*.mdc`

The installer also generates a Cursor doctrine rule from the repo root `AGENTS.md`.

## Start using the skills

### Codex

Start Codex from the repo root or any subdirectory covered by the installed scope. Codex can pick up these skills automatically, or you can invoke them directly with `$<skill-name>`.

Examples:

```text
$backend
$testing
```

### Claude Code

Start Claude Code in the target repo after installation. Claude can auto-load the installed skills, and you can invoke them directly with `/<skill-name>`.

Examples:

```text
/backend
/testing
```

### OpenCode

Start OpenCode in the target repo after installation. OpenCode discovers the installed skills and can load them through its native `skill` tool or when they match the request.

Example:

```text
skill("caveman")
```

#### Caveman + cavemem MCP

You can pair the `caveman` communication style with long-term memory via `cavemem` MCP.

- Caveman: https://github.com/JuliusBrussee/caveman
- Cavekit: https://github.com/JuliusBrussee/cavekit
- Cavemem: https://github.com/JuliusBrussee/cavemem

This repo includes an OpenCode autoload template at `templates/opencode/caveman-cavemem-autoload.js` that:

- auto-registers a local `cavemem` MCP server
- injects caveman response style into system instructions
- optionally prepends the cavemem binary directory to `PATH`
- sends desktop notifications on session completion/error

When cavemem MCP is active, available tools include:

- `cavemem_search`: find relevant prior memories
- `cavemem_list_sessions`: list recent memory sessions
- `cavemem_timeline`: inspect a session around a point
- `cavemem_get_observations`: fetch full observation bodies

### Cursor

Open the project in Cursor after installing the generated `.cursor/rules/*.mdc` files. Restart Cursor if the new rules do not appear immediately.

## Notes

- The installer does not fetch anything from the network.
- The repository no longer ships the old `.system` helper skills; it only contains the reusable top-level skills.
- The generated project and user guidance rewrites the root `AGENTS.md` references so they point at the installed `engineering-core` skill instead of the old `agent-os` paths.
