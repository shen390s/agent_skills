#!/usr/bin/env bash
set -euo pipefail

# Crush skill installer — installs one or more Agent Skills from skills/ into
# Crush, Claude Code, and/or Kiro. All three share the SKILL.md format.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="${SCRIPT_DIR}/skills"

PROJECT_DIR=""
FORCE=0
DRY_RUN=0
COLOR=1
TOOLS=()
SKILLS=()

# --- output helpers ---------------------------------------------------------

use_color() {
  local fd="$1"
  [[ "$COLOR" -eq 1 ]] \
    && [[ -z "${NO_COLOR:-}" ]] \
    && [[ "${TERM:-}" != "dumb" ]] \
    && [[ -t "$fd" ]]
}

green() { use_color 1 && printf '\033[32m%s\033[0m' "$1" || printf '%s' "$1"; }
dim()   { use_color 1 && printf '\033[2m%s\033[0m' "$1" || printf '%s' "$1"; }
bold()  { use_color 1 && printf '\033[1m%s\033[0m' "$1" || printf '%s' "$1"; }
red()   { use_color 2 && printf '\033[31m%s\033[0m' "$1" || printf '%s' "$1"; }

fail() {
  echo "$(red 'error:') $1" >&2
  exit 1
}

discover_skills() {
  DISCOVERED=()
  local dir name
  for dir in "$SKILLS_SRC"/*/; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"
    [[ -f "$dir/SKILL.md" ]] && DISCOVERED+=("$name")
  done
}

list_skills() {
  if [[ ${#DISCOVERED[@]} -eq 0 ]]; then
    echo "  (none)"
    return
  fi
  local name
  for name in "${DISCOVERED[@]}"; do
    echo "  ${name}"
  done
}

usage() {
  cat <<'EOF'
Install Agent Skills from skills/ into Crush, Claude Code, and/or Kiro.

Examples:
  ./install.sh                          # all skills -> Crush (global)
  ./install.sh all                      # all skills -> all tools
  ./install.sh --skill cli-ux           # one skill -> Crush
  ./install.sh claude --skill cli-ux    # one skill -> Claude Code
  ./install.sh --project=. all          # all skills -> this project
  ./install.sh -f --tool kiro --skill cli-ux
  ./install.sh --list                   # list available skills

Usage:
  install.sh [options] [tool ...]

Tools (default: crush; "all" = crush claude kiro):
  crush    Crush         (project .crush/skills   | global ~/.config/crush/skills)
  claude   Claude Code   (project .claude/skills  | global ~/.claude/skills)
  kiro     Kiro (AWS)    (project .kiro/skills    | global ~/.kiro/skills)

Options:
  --skill NAME      Skill to install, or "all" (repeatable; default: all)
  --tool NAME       Tool to install into (repeatable)
  --project[=DIR]   Install project-locally (default: current dir)
  -f, --force       Overwrite existing installations without prompting
      --no-color    Disable colored output
  -n, --dry-run     Show what would be done without doing it
  -l, --list        List available skills and exit
  -h, --help        Show this help

Global roots honor CRUSH_SKILLS_DIR, CLAUDE_CONFIG_DIR, and KIRO_HOME when set.
EOF
  echo
  echo "Available skills:"
  list_skills
}

array_contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

unique() {
  local out=() item
  for item in "$@"; do
    array_contains "$item" "${out[@]}" || out+=("$item")
  done
  printf '%s\n' "${out[@]}"
}

discover_skills

# --- argument parsing -------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_DIR="."
      shift
      ;;
    --project=*)
      PROJECT_DIR="${1#*=}"
      [[ -n "$PROJECT_DIR" ]] || PROJECT_DIR="."
      shift
      ;;
    --tool)
      [[ -n "${2:-}" ]] || fail "--tool needs a value"
      TOOLS+=("$2")
      shift 2
      ;;
    --tool=*)
      TOOLS+=("${1#*=}")
      shift
      ;;
    --skill)
      [[ -n "${2:-}" ]] || fail "--skill needs a value"
      SKILLS+=("$2")
      shift 2
      ;;
    --skill=*)
      SKILLS+=("${1#*=}")
      shift
      ;;
    -f|--force)
      FORCE=1
      shift
      ;;
    --no-color)
      COLOR=0
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -l|--list)
      list_skills
      exit 0
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    -*)
      fail "unknown option: $1 (run install.sh --help)"
      ;;
    *)
      TOOLS+=("$1")
      shift
      ;;
  esac
done

# --- resolve tools ----------------------------------------------------------

if [[ ${#TOOLS[@]} -eq 0 ]]; then
  TOOLS=(crush)
fi
for tool in "${TOOLS[@]}"; do
  case "$tool" in
    crush|claude|kiro|all) ;;
    *) fail "unknown tool: $tool (expected crush, claude, kiro, or all)" ;;
  esac
done
if array_contains "all" "${TOOLS[@]}"; then
  TOOLS=(crush claude kiro)
fi
_tmp=()
while IFS= read -r item; do
  if [[ -n "$item" ]]; then
    _tmp+=("$item")
  fi
done < <(unique "${TOOLS[@]}")
TOOLS=("${_tmp[@]}")

# --- resolve skills ----------------------------------------------------------

if [[ ${#DISCOVERED[@]} -eq 0 ]]; then
  fail "no skills found (expected skills/<name>/SKILL.md under $SKILLS_SRC)"
fi

for name in "${SKILLS[@]}"; do
  [[ "$name" == "all" ]] && continue
  array_contains "$name" "${DISCOVERED[@]}" \
    || fail "unknown skill: $name (available: ${DISCOVERED[*]})"
done

if [[ ${#SKILLS[@]} -eq 0 ]] || array_contains "all" "${SKILLS[@]}"; then
  SELECTED=("${DISCOVERED[@]}")
else
  SELECTED=("${SKILLS[@]}")
fi
_tmp=()
while IFS= read -r item; do
  if [[ -n "$item" ]]; then
    _tmp+=("$item")
  fi
done < <(unique "${SELECTED[@]}")
SELECTED=("${_tmp[@]}")

# --- install -----------------------------------------------------------------

tool_label() {
  case "$1" in
    crush)  echo "Crush" ;;
    claude) echo "Claude Code" ;;
    kiro)   echo "Kiro" ;;
  esac
}

tool_skills_root() {
  local tool="$1"
  if [[ -n "$PROJECT_DIR" ]]; then
    local proj
    proj="$(cd "$PROJECT_DIR" 2>/dev/null && pwd || true)"
    if [[ -z "$proj" ]]; then
      proj="$PROJECT_DIR"
      [[ "$proj" = /* ]] || proj="$(pwd)/$proj"
    fi
    case "$tool" in
      crush)  echo "${proj}/.crush/skills" ;;
      claude) echo "${proj}/.claude/skills" ;;
      kiro)   echo "${proj}/.kiro/skills" ;;
    esac
    return
  fi

  case "$tool" in
    crush)
      if [[ -n "${CRUSH_SKILLS_DIR:-}" ]]; then
        echo "${CRUSH_SKILLS_DIR}"
      else
        echo "${XDG_CONFIG_HOME:-$HOME/.config}/crush/skills"
      fi
      ;;
    claude)
      echo "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
      ;;
    kiro)
      echo "${KIRO_HOME:-$HOME/.kiro}/skills"
      ;;
  esac
}

scope_label() {
  if [[ -n "$PROJECT_DIR" ]]; then
    echo "project ($PROJECT_DIR)"
  else
    echo "global"
  fi
}

installed=0
for skill in "${SELECTED[@]}"; do
  src_file="${SKILLS_SRC}/${skill}/SKILL.md"
  for tool in "${TOOLS[@]}"; do
    dir="$(tool_skills_root "$tool")/${skill}"
    file="${dir}/SKILL.md"

    if [[ "$DRY_RUN" -eq 1 ]]; then
      action="install"
      [[ -f "$file" ]] && action="overwrite"
      echo "$(dim "would ${action}") $(bold "$skill") -> $(tool_label "$tool") [$(scope_label)]:"
      echo "  ${src_file} -> ${file}"
      continue
    fi

    if [[ -f "$file" && "$FORCE" -eq 0 ]]; then
      if [[ ! -t 0 ]]; then
        fail "already installed at ${file}; re-run with -f to overwrite"
      fi
      read -r -p "already installed at ${file}; overwrite? [y/N] " answer
      case "$answer" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "$(dim 'skipped') ${skill} -> $(tool_label "$tool")"; continue ;;
      esac
    fi

    mkdir -p "$dir"
    cp "$src_file" "$file"
    echo "$(green 'installed') $(bold "$skill") -> $(tool_label "$tool") [$(scope_label)]:"
    echo "  ${file}"
    installed=1
  done
done

if [[ "$DRY_RUN" -eq 0 && "$installed" -eq 0 ]]; then
  echo "nothing installed."
fi
