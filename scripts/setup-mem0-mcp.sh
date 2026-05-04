#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="${MEM0_INSTALL_DIR:-${HOME}/.local/share/ai-tools}"
OPENCODE_CONFIG="${OPENCODE_CONFIG:-${HOME}/.config/opencode/opencode.json}"
MEM0_USER_ID="${MEM0_USER_ID:-${USER:-$(id -un)}}"
COLLECTION_NAME="${MEM0_COLLECTION_NAME:-opencode_memory}"
QDRANT_HOST="${MEM0_QDRANT_HOST:-localhost}"
QDRANT_PORT="${MEM0_QDRANT_PORT:-6333}"
EMBEDDING_DIMS="${MEM0_EMBEDDING_DIMS:-768}"
OLLAMA_URL="${MEM0_OLLAMA_URL:-http://localhost:11434}"
LLM_MODEL="${MEM0_LLM_MODEL:-gpt-oss:120b-cloud}"
EMBED_MODEL="${MEM0_EMBED_MODEL:-nomic-embed-text:latest}"
ENABLED="true"
ENABLED_EXPLICIT=false
REPLACE=false
SKIP_PACKAGES=false

info() {
  printf '[setup-mem0-mcp] %s\n' "$*"
}

warn() {
  printf '[setup-mem0-mcp] %s\n' "$*" >&2
}

die() {
  warn "$*"
  exit 1
}

usage() {
  cat <<'EOF'
Set up local Mem0 MCP server and wire it into OpenCode.

Defaults mirror the observed working setup on this machine:
  install dir: ~/.local/share/ai-tools
  Python:      ~/.local/share/ai-tools/.venv/bin/python
  server:      ~/.local/share/ai-tools/mem0_server.py
  vector DB:   Qdrant localhost:6333, collection opencode_memory
  LLM:         Ollama gpt-oss:120b-cloud
  embedder:    Ollama nomic-embed-text:latest
  OpenCode:    ~/.config/opencode/opencode.json, mcp.mem0 enabled=true

Usage:
  scripts/setup-mem0-mcp.sh [options]

Options:
  --install-dir <path>       Install server and venv here.
  --opencode-config <path>   OpenCode config path.
  --user-id <value>          Default MEM0_USER_ID for MCP server.
  --collection <name>        Qdrant collection name.
  --qdrant-host <host>       Qdrant host.
  --qdrant-port <port>       Qdrant port.
  --embedding-dims <n>       Embedding vector dimensions.
  --ollama-url <url>         Ollama base URL.
  --llm-model <name>         Ollama LLM model.
  --embed-model <name>       Ollama embedder model.
  --enable                   Set OpenCode mcp.mem0.enabled=true.
  --disable                  Set OpenCode mcp.mem0.enabled=false.
  --replace                  Overwrite existing mem0_server.py.
  --skip-packages            Do not install/upgrade Python packages.
  -h, --help                 Show help.

Notes:
  - New OpenCode mem0 entries are enabled by default.
  - Existing enabled value is preserved unless --enable or --disable is passed.
  - Qdrant and Ollama services/models are not started or pulled by this script.
EOF
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      --install-dir)
        (($# >= 2)) || die "Missing value for --install-dir"
        INSTALL_DIR="$2"
        shift 2
        ;;
      --opencode-config)
        (($# >= 2)) || die "Missing value for --opencode-config"
        OPENCODE_CONFIG="$2"
        shift 2
        ;;
      --user-id)
        (($# >= 2)) || die "Missing value for --user-id"
        MEM0_USER_ID="$2"
        shift 2
        ;;
      --collection)
        (($# >= 2)) || die "Missing value for --collection"
        COLLECTION_NAME="$2"
        shift 2
        ;;
      --qdrant-host)
        (($# >= 2)) || die "Missing value for --qdrant-host"
        QDRANT_HOST="$2"
        shift 2
        ;;
      --qdrant-port)
        (($# >= 2)) || die "Missing value for --qdrant-port"
        QDRANT_PORT="$2"
        shift 2
        ;;
      --embedding-dims)
        (($# >= 2)) || die "Missing value for --embedding-dims"
        EMBEDDING_DIMS="$2"
        shift 2
        ;;
      --ollama-url)
        (($# >= 2)) || die "Missing value for --ollama-url"
        OLLAMA_URL="$2"
        shift 2
        ;;
      --llm-model)
        (($# >= 2)) || die "Missing value for --llm-model"
        LLM_MODEL="$2"
        shift 2
        ;;
      --embed-model)
        (($# >= 2)) || die "Missing value for --embed-model"
        EMBED_MODEL="$2"
        shift 2
        ;;
      --enable)
        ENABLED="true"
        ENABLED_EXPLICIT=true
        shift
        ;;
      --disable)
        ENABLED="false"
        ENABLED_EXPLICIT=true
        shift
        ;;
      --replace)
        REPLACE=true
        shift
        ;;
      --skip-packages)
        SKIP_PACKAGES=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done
}

write_mem0_server() {
  local server_file="$1"

  if [[ -e "${server_file}" && "${REPLACE}" != "true" ]]; then
    info "Keeping existing ${server_file}. Use --replace to overwrite."
    return
  fi

  cat > "${server_file}" <<PY
import asyncio
import os
import getpass
from pathlib import Path
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp import types

CONFIG = {
    "vector_store": {
        "provider": "qdrant",
        "config": {
            "collection_name": ${COLLECTION_NAME@Q},
            "host": ${QDRANT_HOST@Q},
            "port": int(${QDRANT_PORT@Q}),
            "embedding_model_dims": int(${EMBEDDING_DIMS@Q}),
        },
    },
    "llm": {
        "provider": "ollama",
        "config": {
            "model": ${LLM_MODEL@Q},
            "temperature": 0,
            "max_tokens": 2000,
            "ollama_base_url": ${OLLAMA_URL@Q},
        },
    },
    "embedder": {
        "provider": "ollama",
        "config": {
            "model": ${EMBED_MODEL@Q},
            "ollama_base_url": ${OLLAMA_URL@Q},
        },
    },
}


def normalize_app_id(value: str) -> str:
    return value.strip().lower().replace("-", "_").replace(" ", "_")


def default_app_id() -> str:
    cwd_name = Path.cwd().resolve().name
    return normalize_app_id(cwd_name) if cwd_name else "default"


USER_ID = os.environ.get("MEM0_USER_ID") or ${MEM0_USER_ID@Q} or getpass.getuser()
APP_ID = normalize_app_id(os.environ.get("MEM0_APP_ID", "")) or default_app_id()
app = Server("mem0-local")
_memory = None


def get_memory():
    global _memory
    if _memory is None:
        from mem0 import Memory
        _memory = Memory.from_config(CONFIG)
    return _memory


def scope_filters() -> dict:
    return {"user_id": USER_ID, "app_id": APP_ID}


@app.list_tools()
async def list_tools():
    return [
        types.Tool(name="add_memory", description="Store information to long-term memory", inputSchema={"type": "object", "properties": {"content": {"type": "string"}}, "required": ["content"]}),
        types.Tool(name="search_memory", description="Search long-term memory for relevant context", inputSchema={"type": "object", "properties": {"query": {"type": "string"}}, "required": ["query"]}),
        types.Tool(name="get_all_memories", description="Retrieve all stored memories", inputSchema={"type": "object", "properties": {}}),
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict):
    memory = get_memory()
    if name == "add_memory":
        result = memory.add(arguments["content"], user_id=USER_ID, metadata={"app_id": APP_ID}, infer=False)
        return [types.TextContent(type="text", text=str(result))]
    if name == "search_memory":
        results = memory.search(arguments["query"], filters=scope_filters())
        return [types.TextContent(type="text", text=str(results))]
    if name == "get_all_memories":
        results = memory.get_all(filters=scope_filters())
        return [types.TextContent(type="text", text=str(results))]
    raise ValueError(f"Unknown tool: {name}")


async def main():
    async with stdio_server() as (read, write):
        await app.run(read, write, app.create_initialization_options())


if __name__ == "__main__":
    asyncio.run(main())
PY
  info "Wrote ${server_file}."
}

update_opencode_config() {
  local python_bin="$1"
  local server_file="$2"
  local config_dir
  config_dir="$(dirname -- "${OPENCODE_CONFIG}")"
  mkdir -p -- "${config_dir}"

  if [[ ! -e "${OPENCODE_CONFIG}" ]]; then
    printf '{}\n' > "${OPENCODE_CONFIG}"
  fi

  python3 - "${OPENCODE_CONFIG}" "${python_bin}" "${server_file}" "${ENABLED}" "${ENABLED_EXPLICIT}" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
python_bin = sys.argv[2]
server_file = sys.argv[3]
requested_enabled = sys.argv[4] == "true"
enabled_explicit = sys.argv[5] == "true"

try:
    raw = config_path.read_text().strip()
    config = json.loads(raw) if raw else {}
except json.JSONDecodeError as exc:
    raise SystemExit(f"Invalid JSON in {config_path}: {exc}")

mcp = config.setdefault("mcp", {})
mem0 = mcp.setdefault("mem0", {})
entry_existed = bool(mem0)

mem0["type"] = "local"
if enabled_explicit or not entry_existed or "enabled" not in mem0:
    mem0["enabled"] = requested_enabled
mem0["command"] = [python_bin, server_file]

config_path.write_text(json.dumps(config, indent=2) + "\n")
PY
  info "Updated OpenCode config at ${OPENCODE_CONFIG}."
}

parse_args "$@"

mkdir -p -- "${INSTALL_DIR}"
VENV_DIR="${INSTALL_DIR}/.venv"
PYTHON_BIN="${VENV_DIR}/bin/python"
SERVER_FILE="${INSTALL_DIR}/mem0_server.py"

if [[ ! -x "${PYTHON_BIN}" ]]; then
  python3 -m venv "${VENV_DIR}"
  info "Created venv at ${VENV_DIR}."
fi

if [[ "${SKIP_PACKAGES}" != "true" ]]; then
  "${PYTHON_BIN}" -m pip install --upgrade pip
  "${PYTHON_BIN}" -m pip install 'mem0ai==2.0.1' 'mcp==1.27.0' 'qdrant-client==1.17.1'
fi

write_mem0_server "${SERVER_FILE}"
"${PYTHON_BIN}" -m py_compile "${SERVER_FILE}"
update_opencode_config "${PYTHON_BIN}" "${SERVER_FILE}"

info "Mem0 MCP setup complete."
info "Ensure Qdrant is reachable at ${QDRANT_HOST}:${QDRANT_PORT} and Ollama at ${OLLAMA_URL}."
