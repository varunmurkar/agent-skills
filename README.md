# agent-skills

Reusable agent skills and companion instruction files for Codex, Claude Code, Cursor, and OpenCode.

## Included skills

- `backend`
- `engineering-core`
- `frontend`
- `pr-review`
- `security-best-practices`
- `supabase-postgres-best-practices`
- `testing`

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

### Cursor

Open the project in Cursor after installing the generated `.cursor/rules/*.mdc` files. Restart Cursor if the new rules do not appear immediately.

## Notes

- The installer does not fetch anything from the network.
- The repository no longer ships the old `.system` helper skills; it only contains the reusable top-level skills.
- The generated project and user guidance rewrites the root `AGENTS.md` references so they point at the installed `engineering-core` skill instead of the old `agent-os` paths.
