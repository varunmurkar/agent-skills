#!/usr/bin/env bash

set -euo pipefail
shopt -s extglob

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
readonly SOURCE_SKILLS_DIR="${REPO_ROOT}/skills"
readonly SOURCE_AGENTS_FILE="${REPO_ROOT}/AGENTS.md"
readonly CODEX_HOME_DIR="${CODEX_HOME:-${HOME}/.codex}"
readonly USER_AGENTS_DIR="${HOME}/.agents"
readonly USER_AGENTS_SKILLS_DIR="${HOME}/.agents/skills"
readonly INSTALL_USER_ID="${USER:-user}"

AVAILABLE_SKILLS=()

SCOPE=""
PROJECT_ROOT_INPUT="${PWD}"
REQUESTED_TOOLS=()
REQUESTED_SKILLS=()
REPLACE_ALL=false

TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TMP_DIR}"' EXIT

info() {
  printf '[install-agent-skills] %s\n' "$*"
}

warn() {
  printf '[install-agent-skills] %s\n' "$*" >&2
}

die() {
  warn "$*"
  exit 1
}

usage() {
  cat <<'EOF'
Install the repository's agent skills for Codex, Claude Code, Cursor, and OpenCode.

Usage:
  scripts/install-agent-skills.sh --scope <project|user> [options]

Options:
  --scope <project|user>       Required. Install into the current project or the current user profile.
  --tool <name[,name...]>      Tool target(s): codex, claude, cursor, opencode, all.
                               Defaults to all.
  --skill <name[,name...]>     Skill subset to install. Defaults to all repository skills.
  --project-root <path>        Project root for --scope project. Defaults to the current directory.
  --replace-all                Replace existing skills, instruction files, rules, and plugins without prompting.
  -h, --help                   Show this help text.

Examples:
  scripts/install-agent-skills.sh --scope project --tool all
  scripts/install-agent-skills.sh --scope user --tool codex,claude
  scripts/install-agent-skills.sh --scope project --tool cursor --skill backend,frontend

Notes:
  - The script prompts before replacing, renaming, or skipping collisions unless --replace-all is set.
  - Codex/OpenCode installs also wire in adapted AGENTS.md guidance.
  - Claude installs also wire in adapted CLAUDE.md guidance.
  - Cursor installs generate .cursor/rules/*.mdc wrappers from the skill content.
EOF
}

trim() {
  local value="$1"
  value="${value##+([[:space:]])}"
  value="${value%%+([[:space:]])}"
  printf '%s\n' "${value}"
}

array_contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "${item}" == "${needle}" ]]; then
      return 0
    fi
  done
  return 1
}

push_unique() {
  local value="$1"
  local -n array_ref="$2"
  if ! array_contains "${value}" "${array_ref[@]}"; then
    array_ref+=("${value}")
  fi
}

split_csv_into_array() {
  local csv="$1"
  local destination="$2"
  local IFS=','
  local parts=()
  read -r -a parts <<< "${csv}"
  local item
  for item in "${parts[@]}"; do
    item="$(trim "${item}")"
    [[ -n "${item}" ]] || continue
    push_unique "${item}" "${destination}"
  done
}

validate_scope() {
  case "${SCOPE}" in
    project|user) ;;
    *) die "--scope must be project or user." ;;
  esac
}

validate_tool() {
  case "$1" in
    codex|claude|cursor|opencode|all) ;;
    *) die "Unknown tool: $1" ;;
  esac
}

validate_skill() {
  if ! array_contains "$1" "${AVAILABLE_SKILLS[@]}"; then
    die "Unknown skill: $1"
  fi
}

discover_available_skills() {
  local skill_dir
  local discovered=()

  [[ -d "${SOURCE_SKILLS_DIR}" ]] || die "Missing source skills directory: ${SOURCE_SKILLS_DIR}"

  for skill_dir in "${SOURCE_SKILLS_DIR}"/*; do
    [[ -d "${skill_dir}" ]] || continue
    [[ -f "${skill_dir}/SKILL.md" ]] || continue
    discovered+=("$(basename -- "${skill_dir}")")
  done

  ((${#discovered[@]} > 0)) || die "No installable skills found under ${SOURCE_SKILLS_DIR}"
  mapfile -t AVAILABLE_SKILLS < <(printf '%s\n' "${discovered[@]}" | sort)
}

validate_requested_inputs() {
  local item

  for item in "${REQUESTED_TOOLS[@]}"; do
    validate_tool "${item}"
  done

  for item in "${REQUESTED_SKILLS[@]}"; do
    validate_skill "${item}"
  done
}

resolve_project_root() {
  [[ -d "${PROJECT_ROOT_INPUT}" ]] || die "Project root does not exist: ${PROJECT_ROOT_INPUT}"
  (cd -- "${PROJECT_ROOT_INPUT}" && pwd -P)
}

ensure_interactive() {
  [[ -t 0 ]] || die "Collision handling requires an interactive terminal."
}

prompt_skill_collision_action() {
  local target_path="$1"
  local response
  if [[ "${REPLACE_ALL}" == "true" ]]; then
    printf 'replace\n'
    return
  fi
  ensure_interactive
  while true; do
    read -r -p "Collision at ${target_path}. Choose [r]ename, re[p]lace, or [s]kip: " response
    case "${response,,}" in
      r|rename) printf 'rename\n'; return ;;
      p|replace) printf 'replace\n'; return ;;
      s|skip) printf 'skip\n'; return ;;
    esac
  done
}

prompt_instruction_collision_action() {
  local target_path="$1"
  local response
  if [[ "${REPLACE_ALL}" == "true" ]]; then
    printf 'replace\n'
    return
  fi
  ensure_interactive
  while true; do
    read -r -p "Instruction file already exists at ${target_path}. Choose [c]ompanion, re[p]lace, or [s]kip: " response
    case "${response,,}" in
      c|companion) printf 'companion\n'; return ;;
      p|replace) printf 'replace\n'; return ;;
      s|skip) printf 'skip\n'; return ;;
    esac
  done
}

prompt_compat_link_collision_action() {
  local target_path="$1"
  local response
  if [[ "${REPLACE_ALL}" == "true" ]]; then
    printf 'replace\n'
    return
  fi
  ensure_interactive
  while true; do
    read -r -p "Compatibility link collision at ${target_path}. Choose re[p]lace or [s]kip: " response
    case "${response,,}" in
      p|replace) printf 'replace\n'; return ;;
      s|skip) printf 'skip\n'; return ;;
    esac
  done
}

prompt_new_name() {
  local original_name="$1"
  local candidate
  ensure_interactive
  while true; do
    read -r -p "New name for ${original_name}: " candidate
    candidate="$(trim "${candidate}")"
    if [[ ! "${candidate}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
      warn "Use lowercase letters, numbers, and single hyphens only."
      continue
    fi
    printf '%s\n' "${candidate}"
    return
  done
}

skill_root_for_tool() {
  local tool="$1"
  local project_root="$2"
  case "${tool}:${SCOPE}" in
    codex:project) printf '%s/.agents/skills\n' "${project_root}" ;;
    codex:user) printf '%s\n' "${USER_AGENTS_SKILLS_DIR}" ;;
    claude:project) printf '%s/.claude/skills\n' "${project_root}" ;;
    claude:user) printf '%s\n' "${USER_AGENTS_SKILLS_DIR}" ;;
    opencode:project) printf '%s/.opencode/skills\n' "${project_root}" ;;
    opencode:user) printf '%s\n' "${USER_AGENTS_SKILLS_DIR}" ;;
    *) die "Unsupported skill root lookup for ${tool}:${SCOPE}" ;;
  esac
}

rewrite_skill_name() {
  local skill_file="$1"
  local new_name="$2"
  local rewritten_file="${TMP_DIR}/rewritten-skill.md"
  awk -v new_name="${new_name}" '
    !done && $0 ~ /^name:[[:space:]]*/ {
      print "name: " new_name
      done = 1
      next
    }
    { print }
  ' "${skill_file}" > "${rewritten_file}"
  mv -- "${rewritten_file}" "${skill_file}"
}

install_skill_directory() {
  local source_name="$1"
  local destination_root="$2"
  local source_dir="${SOURCE_SKILLS_DIR}/${source_name}"
  local install_name="${source_name}"
  local destination_dir="${destination_root}/${install_name}"
  local action

  [[ -d "${source_dir}" ]] || die "Missing source skill directory: ${source_dir}"
  mkdir -p -- "${destination_root}"

  while [[ -e "${destination_dir}" ]]; do
    action="$(prompt_skill_collision_action "${destination_dir}")"
    case "${action}" in
      rename)
        install_name="$(prompt_new_name "${source_name}")"
        destination_dir="${destination_root}/${install_name}"
        ;;
      replace)
        rm -rf -- "${destination_dir}"
        ;;
      skip)
        info "Skipped skill ${source_name} for ${destination_root}."
        return
        ;;
    esac
  done

  cp -a -- "${source_dir}" "${destination_dir}"
  if [[ "${install_name}" != "${source_name}" ]]; then
    rewrite_skill_name "${destination_dir}/SKILL.md" "${install_name}"
    warn "Installed ${source_name} as ${install_name}. Any references to the original name remain unchanged."
  else
    info "Installed ${source_name} to ${destination_dir}."
  fi
}

install_skill_compat_link() {
  local source_name="$1"
  local link_root="$2"
  local canonical_dir="${USER_AGENTS_SKILLS_DIR}/${source_name}"
  local link_path="${link_root}/${source_name}"
  local current_target
  local action

  [[ -d "${canonical_dir}" ]] || die "Missing canonical user skill: ${canonical_dir}"
  mkdir -p -- "${link_root}"

  while [[ -e "${link_path}" || -L "${link_path}" ]]; do
    if [[ -L "${link_path}" ]]; then
      current_target="$(readlink -- "${link_path}")"
      if [[ "${current_target}" == "${canonical_dir}" ]]; then
        info "Compatibility link already exists at ${link_path}."
        return
      fi
    fi

    action="$(prompt_compat_link_collision_action "${link_path}")"
    case "${action}" in
      replace)
        rm -rf -- "${link_path}"
        ;;
      skip)
        info "Skipped compatibility link ${link_path}."
        return
        ;;
    esac
  done

  ln -s -- "${canonical_dir}" "${link_path}"
  info "Linked ${link_path} to ${canonical_dir}."
}

extract_skill_description() {
  local skill_file="$1"
  awk '
    BEGIN { in_frontmatter = 0 }
    /^---[[:space:]]*$/ {
      in_frontmatter += 1
      next
    }
    in_frontmatter == 1 && $0 ~ /^description:[[:space:]]*/ {
      sub(/^description:[[:space:]]*/, "", $0)
      gsub(/^"/, "", $0)
      gsub(/"$/, "", $0)
      print
      exit
    }
  ' "${skill_file}"
}

extract_skill_body() {
  local skill_file="$1"
  awk '
    BEGIN { separators = 0 }
    /^---[[:space:]]*$/ {
      separators += 1
      next
    }
    separators >= 2 { print }
  ' "${skill_file}"
}

yaml_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s\n' "${value}"
}

write_cursor_rule_file() {
  local source_name="$1"
  local rule_name="$2"
  local target_file="$3"
  local skill_file="${SOURCE_SKILLS_DIR}/${source_name}/SKILL.md"
  local description

  description="$(extract_skill_description "${skill_file}")"
  description="$(yaml_escape "${description}")"

  mkdir -p -- "$(dirname -- "${target_file}")"
  {
    cat <<EOF
---
description: "${description}"
alwaysApply: false
---
# ${rule_name}

Generated from \`agent-skills/skills/${source_name}/SKILL.md\` for Cursor.

EOF
    extract_skill_body "${skill_file}"
  } > "${target_file}"
}

install_cursor_rule() {
  local source_name="$1"
  local rule_root="$2"
  local rule_name="${source_name}"
  local target_file="${rule_root}/${rule_name}.mdc"
  local action

  mkdir -p -- "${rule_root}"
  while [[ -e "${target_file}" ]]; do
    action="$(prompt_skill_collision_action "${target_file}")"
    case "${action}" in
      rename)
        rule_name="$(prompt_new_name "${source_name}")"
        target_file="${rule_root}/${rule_name}.mdc"
        ;;
      replace)
        rm -f -- "${target_file}"
        ;;
      skip)
        info "Skipped Cursor rule ${source_name}."
        return
        ;;
    esac
  done

  write_cursor_rule_file "${source_name}" "${rule_name}" "${target_file}"
  info "Installed Cursor rule ${rule_name} to ${target_file}."
}

doctrine_hint_for_agents() {
  local key="$1"
  case "${key}" in
    codex) printf '`./.agents/skills/engineering-core/SKILL.md`' ;;
    opencode) printf '`./.opencode/skills/engineering-core/SKILL.md`' ;;
    codex+opencode) printf '`./.agents/skills/engineering-core/SKILL.md` or `./.opencode/skills/engineering-core/SKILL.md`' ;;
    codex-user|opencode-user|claude-user) printf '`~/.agents/skills/engineering-core/SKILL.md`' ;;
    claude-project) printf '`./.claude/skills/engineering-core/SKILL.md`' ;;
    cursor) printf 'the generated `engineering-core.mdc` rule in `.cursor/rules/`' ;;
    *) die "Unsupported doctrine hint key: ${key}" ;;
  esac
}

doctrine_communication_ref() {
  local key="$1"
  case "${key}" in
    codex) printf '`./.agents/skills/caveman/SKILL.md`' ;;
    opencode) printf '`./.opencode/skills/caveman/SKILL.md`' ;;
    codex+opencode) printf '`./.agents/skills/caveman/SKILL.md` or `./.opencode/skills/caveman/SKILL.md`' ;;
    codex-user|opencode-user|claude-user) printf '`~/.agents/skills/caveman/SKILL.md`' ;;
    claude-project) printf '`./.claude/skills/caveman/SKILL.md`' ;;
    cursor) printf 'the generated `caveman.mdc` rule in `.cursor/rules/`' ;;
    *) die "Unsupported doctrine communication key: ${key}" ;;
  esac
}

render_doctrine_body() {
  local source_file="$1"
  local communication_ref="$2"
  local install_user_id="$3"
  awk -v communication_ref="${communication_ref}" -v install_user_id="${install_user_id}" '
    /^## Installed Skill Paths[[:space:]]*$/ {
      skipping_installed_paths = 1
      next
    }
    skipping_installed_paths && /^## / {
      skipping_installed_paths = 0
    }
    skipping_installed_paths {
      next
    }
    $0 == "## Communication" {
      print
      if (getline > 0) {
        print communication_ref
      }
      next
    }
    $0 ~ /^- Tool: mem0 MCP\. User ID:/ {
      print "- Tool: mem0 MCP. User ID: `" install_user_id "`"
      next
    }
    { print }
  ' "${source_file}"
}

write_doctrine_content() {
  local target_file="$1"
  local communication_ref="$2"
  local doctrine_hint="$3"
  {
    render_doctrine_body "${SOURCE_AGENTS_FILE}" "${communication_ref}" "${INSTALL_USER_ID}"
    cat <<EOF

## Installed Skill Paths
- **Operational Doctrine Index**: installed engineering-core guidance is typically ${doctrine_hint}. Load once per task; it details when to pull in each specialized guide.
EOF
  } > "${target_file}"
}

append_agents_loader() {
  local target_file="$1"
  local relative_companion="$2"
  if grep -Fq "${relative_companion}" "${target_file}"; then
    info "Existing AGENTS.md already references ${relative_companion}."
    return
  fi

  cat >> "${target_file}" <<EOF

## Agent Skills Shared Guidance

Read \
`${relative_companion}` immediately at session start and treat it as part of this instruction set. Load it once and skip it if it is already in context.
EOF
}

append_claude_import() {
  local target_file="$1"
  local relative_companion="$2"
  if grep -Fq "@${relative_companion}" "${target_file}"; then
    info "Existing CLAUDE.md already imports ${relative_companion}."
    return
  fi

  cat >> "${target_file}" <<EOF

## Agent Skills Shared Guidance
@${relative_companion}
EOF
}

install_instruction_file() {
  local target_file="$1"
  local companion_file="$2"
  local relative_companion="$3"
  local generated_file="$4"
  local file_kind="$5"
  local action

  mkdir -p -- "$(dirname -- "${target_file}")"

  if [[ -s "${target_file}" ]]; then
    action="$(prompt_instruction_collision_action "${target_file}")"
    case "${action}" in
      companion)
        mkdir -p -- "$(dirname -- "${companion_file}")"
        cp -- "${generated_file}" "${companion_file}"
        if [[ "${file_kind}" == "claude" ]]; then
          append_claude_import "${target_file}" "${relative_companion}"
        else
          append_agents_loader "${target_file}" "${relative_companion}"
        fi
        info "Installed companion guidance at ${companion_file}."
        ;;
      replace)
        cp -- "${generated_file}" "${target_file}"
        info "Replaced ${target_file}."
        ;;
      skip)
        info "Skipped instruction file ${target_file}."
        ;;
    esac
  else
    cp -- "${generated_file}" "${target_file}"
    info "Installed ${target_file}."
  fi
}

install_project_agents_guidance() {
  local project_root="$1"
  local hint_key="$2"
  local generated_file="${TMP_DIR}/project-AGENTS.md"
  write_doctrine_content \
    "${generated_file}" \
    "$(doctrine_communication_ref "${hint_key}")" \
    "$(doctrine_hint_for_agents "${hint_key}")"
  install_instruction_file \
    "${project_root}/AGENTS.md" \
    "${project_root}/.agent-skills/AGENTS.md" \
    "./.agent-skills/AGENTS.md" \
    "${generated_file}" \
    "agents"
}

install_user_agents_guidance() {
  local target_file="$1"
  local companion_file="$2"
  local hint_key="$3"
  local generated_file="$4"
  write_doctrine_content \
    "${generated_file}" \
    "$(doctrine_communication_ref "${hint_key}")" \
    "$(doctrine_hint_for_agents "${hint_key}")"
  install_instruction_file "${target_file}" "${companion_file}" "agent-skills/AGENTS.md" "${generated_file}" "agents"
}

install_global_user_agents_guidance() {
  local generated_file="${TMP_DIR}/user-global-AGENTS.md"
  write_doctrine_content \
    "${generated_file}" \
    "$(doctrine_communication_ref "codex-user")" \
    "$(doctrine_hint_for_agents "codex-user")"
  install_instruction_file \
    "${USER_AGENTS_DIR}/AGENTS.md" \
    "${USER_AGENTS_DIR}/agent-skills/AGENTS.md" \
    "agent-skills/AGENTS.md" \
    "${generated_file}" \
    "agents"
}

install_claude_guidance() {
  local target_file="$1"
  local companion_file="$2"
  local hint_key="$3"
  local generated_file="$4"
  local relative_companion="agent-skills/CLAUDE.md"
  if [[ "${SCOPE}" == "project" ]]; then
    relative_companion="./.agent-skills/CLAUDE.md"
  fi

  write_doctrine_content \
    "${generated_file}" \
    "$(doctrine_communication_ref "${hint_key}")" \
    "$(doctrine_hint_for_agents "${hint_key}")"
  install_instruction_file "${target_file}" "${companion_file}" "${relative_companion}" "${generated_file}" "claude"
}

write_cursor_doctrine_rule() {
  local target_file="$1"
  local doctrine_hint
  doctrine_hint="$(doctrine_hint_for_agents cursor)"
  mkdir -p -- "$(dirname -- "${target_file}")"
  {
    cat <<EOF
---
description: "Shared doctrine and operating model generated from agent-skills/AGENTS.md"
alwaysApply: true
---
# Agent Skills Doctrine

Generated from \`agent-skills/AGENTS.md\` for Cursor.

EOF
    render_doctrine_body "${SOURCE_AGENTS_FILE}" "$(doctrine_communication_ref cursor)" "${INSTALL_USER_ID}"
    cat <<EOF

## Installed Skill Paths
- **Operational Doctrine Index**: installed \`engineering-core\` guidance is typically ${doctrine_hint}.
EOF
  } > "${target_file}"
}

install_cursor_doctrine_rule() {
  local rule_root="$1"
  local target_file="${rule_root}/00-agent-skills-doctrine.mdc"
  local action

  mkdir -p -- "${rule_root}"
  while [[ -e "${target_file}" ]]; do
    action="$(prompt_skill_collision_action "${target_file}")"
    case "${action}" in
      rename)
        target_file="${rule_root}/$(prompt_new_name 'agent-skills-doctrine').mdc"
        ;;
      replace)
        rm -f -- "${target_file}"
        ;;
      skip)
        info "Skipped Cursor doctrine rule."
        return
        ;;
    esac
  done

  write_cursor_doctrine_rule "${target_file}"
  info "Installed Cursor doctrine rule to ${target_file}."
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      --scope)
        (($# >= 2)) || die "Missing value for --scope"
        SCOPE="$2"
        shift 2
        ;;
      --tool)
        (($# >= 2)) || die "Missing value for --tool"
        split_csv_into_array "$2" REQUESTED_TOOLS
        shift 2
        ;;
      --skill|--skills)
        (($# >= 2)) || die "Missing value for --skill"
        split_csv_into_array "$2" REQUESTED_SKILLS
        shift 2
        ;;
      --project-root)
        (($# >= 2)) || die "Missing value for --project-root"
        PROJECT_ROOT_INPUT="$2"
        shift 2
        ;;
      --replace-all)
        REPLACE_ALL=true
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

build_selected_tools() {
  local tools=()
  local item

  if ((${#REQUESTED_TOOLS[@]} == 0)); then
    tools=(codex claude cursor opencode)
  else
    for item in "${REQUESTED_TOOLS[@]}"; do
      validate_tool "${item}"
      if [[ "${item}" == "all" ]]; then
        tools=(codex claude cursor opencode)
        printf '%s\n' "${tools[@]}"
        return
      fi
      push_unique "${item}" tools
    done
  fi

  printf '%s\n' "${tools[@]}"
}

build_selected_skills() {
  local requested=()
  local skill

  if ((${#REQUESTED_SKILLS[@]} > 0)); then
    for skill in "${REQUESTED_SKILLS[@]}"; do
      validate_skill "${skill}"
      push_unique "${skill}" requested
    done
  else
    requested=("${AVAILABLE_SKILLS[@]}")
  fi

  if ((${#SELECTED_RUNTIME_TOOLS[@]} > 0)); then
    if array_contains "codex" "${SELECTED_RUNTIME_TOOLS[@]}" || \
       array_contains "claude" "${SELECTED_RUNTIME_TOOLS[@]}" || \
       array_contains "opencode" "${SELECTED_RUNTIME_TOOLS[@]}"; then
      push_unique "engineering-core" requested
    fi
  fi

  local ordered=()
  for skill in "${AVAILABLE_SKILLS[@]}"; do
    if array_contains "${skill}" "${requested[@]}"; then
      ordered+=("${skill}")
    fi
  done

  printf '%s\n' "${ordered[@]}"
}

parse_args "$@"
validate_scope
discover_available_skills
validate_requested_inputs

PROJECT_ROOT="$(resolve_project_root)"
mapfile -t SELECTED_RUNTIME_TOOLS < <(build_selected_tools)
mapfile -t SELECTED_SKILLS < <(build_selected_skills)

[[ -f "${SOURCE_AGENTS_FILE}" ]] || die "Missing ${SOURCE_AGENTS_FILE}"

for skill_name in "${SELECTED_SKILLS[@]}"; do
  [[ -d "${SOURCE_SKILLS_DIR}/${skill_name}" ]] || die "Missing source skill: ${skill_name}"
done

info "Installing skills from ${REPO_ROOT}"
info "Scope: ${SCOPE}"
info "Tools: ${SELECTED_RUNTIME_TOOLS[*]}"
info "Skills: ${SELECTED_SKILLS[*]}"

if [[ "${SCOPE}" == "user" ]]; then
  if array_contains "codex" "${SELECTED_RUNTIME_TOOLS[@]}" || \
     array_contains "claude" "${SELECTED_RUNTIME_TOOLS[@]}" || \
     array_contains "opencode" "${SELECTED_RUNTIME_TOOLS[@]}"; then
    for skill_name in "${SELECTED_SKILLS[@]}"; do
      install_skill_directory "${skill_name}" "${USER_AGENTS_SKILLS_DIR}"
    done
  fi

  if array_contains "claude" "${SELECTED_RUNTIME_TOOLS[@]}"; then
    for skill_name in "${SELECTED_SKILLS[@]}"; do
      install_skill_compat_link "${skill_name}" "${HOME}/.claude/skills"
    done
  fi

  if array_contains "cursor" "${SELECTED_RUNTIME_TOOLS[@]}"; then
    cursor_rule_root="${HOME}/.cursor/rules"
    install_cursor_doctrine_rule "${cursor_rule_root}"
    for skill_name in "${SELECTED_SKILLS[@]}"; do
      install_cursor_rule "${skill_name}" "${cursor_rule_root}"
    done
  fi
else
  for tool in "${SELECTED_RUNTIME_TOOLS[@]}"; do
    case "${tool}" in
      codex|claude|opencode)
        skill_root="$(skill_root_for_tool "${tool}" "${PROJECT_ROOT}")"
        for skill_name in "${SELECTED_SKILLS[@]}"; do
          install_skill_directory "${skill_name}" "${skill_root}"
        done
        ;;
      cursor)
        cursor_rule_root="${PROJECT_ROOT}/.cursor/rules"
        install_cursor_doctrine_rule "${cursor_rule_root}"
        for skill_name in "${SELECTED_SKILLS[@]}"; do
          install_cursor_rule "${skill_name}" "${cursor_rule_root}"
        done
        ;;
    esac
  done
fi

if [[ "${SCOPE}" == "project" ]]; then
  if array_contains "codex" "${SELECTED_RUNTIME_TOOLS[@]}" && array_contains "opencode" "${SELECTED_RUNTIME_TOOLS[@]}"; then
    install_project_agents_guidance "${PROJECT_ROOT}" "codex+opencode"
  elif array_contains "codex" "${SELECTED_RUNTIME_TOOLS[@]}"; then
    install_project_agents_guidance "${PROJECT_ROOT}" "codex"
  elif array_contains "opencode" "${SELECTED_RUNTIME_TOOLS[@]}"; then
    install_project_agents_guidance "${PROJECT_ROOT}" "opencode"
  fi

  if array_contains "claude" "${SELECTED_RUNTIME_TOOLS[@]}"; then
    install_claude_guidance \
      "${PROJECT_ROOT}/CLAUDE.md" \
      "${PROJECT_ROOT}/.agent-skills/CLAUDE.md" \
      "claude-project" \
      "${TMP_DIR}/project-CLAUDE.md"
  fi
else
  if array_contains "codex" "${SELECTED_RUNTIME_TOOLS[@]}" || \
     array_contains "claude" "${SELECTED_RUNTIME_TOOLS[@]}" || \
     array_contains "opencode" "${SELECTED_RUNTIME_TOOLS[@]}"; then
    install_global_user_agents_guidance
  fi

  if array_contains "codex" "${SELECTED_RUNTIME_TOOLS[@]}"; then
    install_user_agents_guidance \
      "${CODEX_HOME_DIR}/AGENTS.md" \
      "${CODEX_HOME_DIR}/agent-skills/AGENTS.md" \
      "codex-user" \
      "${TMP_DIR}/user-codex-AGENTS.md"
  fi

  if array_contains "opencode" "${SELECTED_RUNTIME_TOOLS[@]}"; then
    install_user_agents_guidance \
      "${HOME}/.config/opencode/AGENTS.md" \
      "${HOME}/.config/opencode/agent-skills/AGENTS.md" \
      "opencode-user" \
      "${TMP_DIR}/user-opencode-AGENTS.md"
  fi

  if array_contains "claude" "${SELECTED_RUNTIME_TOOLS[@]}"; then
    install_claude_guidance \
      "${HOME}/.claude/CLAUDE.md" \
      "${HOME}/.claude/agent-skills/CLAUDE.md" \
      "claude-user" \
      "${TMP_DIR}/user-claude-CLAUDE.md"
  fi
fi

info "Finished. Restart the target tool if it does not pick up the new skills or rules immediately."
