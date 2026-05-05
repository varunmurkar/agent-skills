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
- `AGENTS.md` and `CLAUDE.md` collisions: choose `companion`, `replace`, or `skip`.

`companion` keeps the incumbent file and installs agent-skills guidance into a generated companion file, then wires the incumbent file to load it.

## What gets installed

For `--scope user`, skills are installed once into the agent-compatible global
skills directory:

- `~/.agents/skills/<skill>/SKILL.md`

Codex and OpenCode read that location directly. Claude Code also gets
compatibility symlinks under `~/.claude/skills/`.

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
  - user: `~/.agents/skills/<skill>/SKILL.md`
  - user compatibility: `~/.claude/skills/<skill>` symlink
- Guidance:
  - project: `CLAUDE.md`
  - user: `~/.claude/CLAUDE.md`

### OpenCode

- Skills:
  - project: `.opencode/skills/<skill>/SKILL.md`
  - user: `~/.agents/skills/<skill>/SKILL.md`
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

#### Mem0 MCP

Long-term memory uses Mem0 MCP. The main installer does not start memory services; run the follow-up setup script for OpenCode:

```bash
./scripts/setup-mem0-mcp.sh
```

This creates/reuses `~/.local/share/ai-tools/.venv`, writes `~/.local/share/ai-tools/mem0_server.py`, installs pinned Python packages, and configures `~/.config/opencode/opencode.json` with `mcp.mem0.enabled=true` by default.

Useful options:

```bash
./scripts/setup-mem0-mcp.sh --disable
./scripts/setup-mem0-mcp.sh --replace
./scripts/setup-mem0-mcp.sh --llm-model gpt-oss:120b-cloud --embed-model nomic-embed-text:latest
```

Expected local services:

- Qdrant at `localhost:6333` (collection `opencode_memory`)
- Ollama at `http://localhost:11434`
- Ollama models `gpt-oss:120b-cloud` and `nomic-embed-text:latest`

The installed MCP server exposes:

- `add_memory`: store information
- `search_memory`: search relevant memories
- `get_all_memories`: list scoped memories

### Cursor

Open the project in Cursor after installing the generated `.cursor/rules/*.mdc` files. Restart Cursor if the new rules do not appear immediately.

## Notes

- The installer does not fetch anything from the network.
- The repository no longer ships the old `.system` helper skills; it only contains the reusable top-level skills.
- The generated project and user guidance rewrites the root `AGENTS.md` skill-path references so they point at the active installed skill path.
