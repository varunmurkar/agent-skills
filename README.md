# agent-skills

Reusable agent skills and companion instruction files for Codex, Claude Code, Cursor, and OpenCode.

## Included skills

Core workflow:

- `engineering-core`
- `backend`
- `frontend`
- `testing`
- `pr-review` — PR/code review entrypoint and quality gates
- `consult-outside-expert`
- `address-pr-reviews` — process existing PR review comments/threads

Spec-driven development:

- `spec` — SPEC.md create/amend/bug recording
- `build` — implement SPEC.md tasks
- `check-drift` — read-only spec/PRD drift
- `backprop` — failure-to-invariant protocol

Caveman ecosystem:

- `caveman`

Commit tooling:

- `commit`

Security and platform:

- `security-best-practices`
- `harden-github-actions`
- `supabase`
- `postgres-best-practices`

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
- Existing `AGENTS.md` collisions: choose `companion`, `replace`, or `skip`.

`companion` keeps the incumbent file and installs agent-skills guidance into a generated companion file, then wires the incumbent file to load it.

Claude `CLAUDE.md` is always a symlink to the available canonical `AGENTS.md`; existing files are backed up to `CLAUDE.md.backup<datestamp>` first.

## What gets installed

For `--scope user`, skills are installed once into the agent-compatible global
agent directory:

- `~/.agents/skills/<skill>/SKILL.md`
- `~/.agents/AGENTS.md`

Codex and OpenCode read that location directly. Claude Code also gets
compatibility symlinks under `~/.claude/skills/`.

### Codex

- Skills:
  - project: `.agents/skills/<skill>/SKILL.md`
  - user: `~/.agents/skills/<skill>/SKILL.md`
- Guidance:
  - global: `~/.agents/AGENTS.md`
  - project: `AGENTS.md`
  - user: `${CODEX_HOME:-~/.codex}/AGENTS.md`

### Claude Code

- Skills:
  - project: `.claude/skills/<skill>/SKILL.md`
  - user: `~/.agents/skills/<skill>/SKILL.md`
  - user compatibility: `~/.claude/skills/<skill>` symlink
- Guidance:
  - global: `~/.agents/AGENTS.md`
  - project: `CLAUDE.md` (symlink to project `AGENTS.md`)
  - user: `~/.claude/CLAUDE.md` (symlink to `~/.agents/AGENTS.md`)

### OpenCode

- Skills:
  - project: `.opencode/skills/<skill>/SKILL.md`
  - user: `~/.agents/skills/<skill>/SKILL.md`
- Guidance:
  - global: `~/.agents/AGENTS.md`
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

### Cursor

Open the project in Cursor after installing the generated `.cursor/rules/*.mdc` files. Restart Cursor if the new rules do not appear immediately.

## Notes

- The installer does not fetch anything from the network.
- The repository no longer ships the old `.system` helper skills; it only contains the reusable top-level skills.
- The generated project and user guidance rewrites the root `AGENTS.md` skill-path references so they point at the active installed skill path.
