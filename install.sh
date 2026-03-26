#!/usr/bin/env bash
# Claude Code Architecture — Module Installer
# Usage: ./install.sh [--modules m1,m2,...] [--bundle name] [--all] [--list] <target-dir>
# Source: https://github.com/V0latix/claude-code-architecture

set -euo pipefail

# ─── Colors ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ─── Config ─────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/V0latix/claude-code-architecture"

# ─── Paths ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
BUNDLES_DIR="$SCRIPT_DIR/bundles"
SOURCE_CLAUDE="$SCRIPT_DIR/.claude"

# ─── Module definitions (order = dependency order) ──────────────────────────
ALL_MODULES=("core" "process" "dev" "frontend" "devops" "ai-llm" "bmad" "vscode" "data" "mobile")

declare -A MODULE_DESC=(
  [core]="Fondation obligatoire — hooks, 8 skills de base, outils utilitaires"
  [process]="Discipline TDD — debugging systématique, RED-GREEN-REFACTOR, plans granulaires"
  [dev]="Développement général — developer, architect, code-reviewer, qa-engineer, 7 workflows"
  [frontend]="UI/Frontend — frontend-specialist, ui-expert, ux-expert, shadcn/ui, Framer Motion"
  [devops]="Infrastructure & ops — devops-engineer, security-auditor, docker-k8s, security-audit"
  [ai-llm]="Applications IA/LLM — ai-engineer, RAG, agents, chatbots, llm-ai-patterns"
  [bmad]="Méthodologie BMAD — orchestrator, greenfield/brownfield/quick, bmad-story"
  [vscode]="Extensions VSCode — vscode-developer, scaffold, workflow Marketplace"
  [data]="Data science — data-scientist, data-engineering, dbt, Airflow, data-pipeline"
  [mobile]="Mobile cross-platform — mobile-developer, React Native / Flutter"
)

declare -A MODULE_DEPS=(
  [core]=""
  [process]="core"
  [dev]="core process"
  [frontend]="core dev"
  [devops]="core dev"
  [ai-llm]="core dev"
  [bmad]="core dev"
  [vscode]="core dev"
  [data]="core dev"
  [mobile]="core dev frontend"
)

# ─── Helpers ─────────────────────────────────────────────────────────────────
print_header() {
  echo -e "\n${BOLD}${BLUE}╔══════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${BLUE}║   Claude Code Architecture — Module Installer            ║${RESET}"
  echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════╝${RESET}\n"
}

info()    { echo -e "${CYAN}ℹ${RESET}  $*"; }
success() { echo -e "${GREEN}✓${RESET}  $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET}  $*"; }
error()   { echo -e "${RED}✗${RESET}  $*" >&2; }
bold()    { echo -e "${BOLD}$*${RESET}"; }

# Resolve full dependency set (recursive)
resolve_deps() {
  local modules=("$@")
  local resolved=()
  local seen=()

  resolve_one() {
    local mod="$1"
    # Already seen?
    for s in "${seen[@]:-}"; do [[ "$s" == "$mod" ]] && return; done
    seen+=("$mod")

    # Resolve dependencies first
    local deps="${MODULE_DEPS[$mod]:-}"
    for dep in $deps; do
      resolve_one "$dep"
    done
    resolved+=("$mod")
  }

  for m in "${modules[@]}"; do
    resolve_one "$m"
  done
  echo "${resolved[@]}"
}

# Parse bundle file (JSON) — returns list of modules
parse_bundle() {
  local bundle_file="$1"
  python3 -c "
import json, sys
with open('$bundle_file') as f:
    data = json.load(f)
print(' '.join(data['modules']))
"
}

# Parse module.json and copy files
install_module() {
  local mod="$1"
  local target="$2"
  local manifest="$MODULES_DIR/$mod/module.json"

  if [[ ! -f "$manifest" ]]; then
    error "Module manifest not found: $manifest"
    return 1
  fi

  info "Installing module: ${BOLD}$mod${RESET}"

  # Use python3 to parse JSON and get file paths
  local paths
  paths=$(python3 -c "
import json, sys
with open('$manifest') as f:
    m = json.load(f)
components = m.get('components', {})
paths = []
for key, items in components.items():
    if key != 'docs':
        paths.extend(items)
print('\n'.join(paths))
")

  local doc_paths
  doc_paths=$(python3 -c "
import json, sys
with open('$manifest') as f:
    m = json.load(f)
components = m.get('components', {})
docs = components.get('docs', [])
print('\n'.join(docs))
")

  # Copy .claude/ components
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    local src="$SCRIPT_DIR/$path"
    local rel="${path#.claude/}"
    local dst="$target/.claude/$rel"

    if [[ -d "$src" ]]; then
      mkdir -p "$dst"
      cp -r "$src/." "$dst/"
    elif [[ -f "$src" ]]; then
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
    else
      warn "  Source not found (skipping): $path"
    fi
  done <<< "$paths"

  # Copy docs/ components (relative to repo root, not .claude/)
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    local src="$SCRIPT_DIR/$path"
    local dst="$target/$path"

    if [[ -d "$src" ]]; then
      mkdir -p "$dst"
      cp -r "$src/." "$dst/"
    fi
  done <<< "$doc_paths"

  success "  Module $mod installed"
}

# Generate CLAUDE-INSTALLED.md summary
generate_summary() {
  local modules=("$@")
  local target="${modules[-1]}"
  unset 'modules[-1]'

  local summary_file="$target/CLAUDE-INSTALLED.md"
  local date
  date=$(date +%Y-%m-%d)

  cat > "$summary_file" << EOF
# Claude Code Architecture — Modules installés

**Date :** $date
**Modules :** ${modules[*]}

## Commandes disponibles

EOF

  for mod in "${modules[@]}"; do
    local manifest="$MODULES_DIR/$mod/module.json"
    [[ ! -f "$manifest" ]] && continue

    local display
    display=$(python3 -c "
import json
with open('$manifest') as f:
    m = json.load(f)
print(m.get('displayName', '$mod'))
")

    echo "### $display" >> "$summary_file"
    echo "" >> "$summary_file"

    python3 -c "
import json
with open('$manifest') as f:
    m = json.load(f)
for entry in m.get('claude_entries', []):
    print(f'- \`{entry}\`')
" >> "$summary_file"
    echo "" >> "$summary_file"
  done

  success "Summary generated: CLAUDE-INSTALLED.md"
}

# Save tracking metadata for future updates
save_tracking() {
  local modules=("$@")
  local target="${modules[-1]}"
  unset 'modules[-1]'

  local tracking_file="$target/.claude/claude-architecture.json"
  local version="unknown"
  local commit="unknown"
  local date
  date=$(date +%Y-%m-%d)

  [[ -f "$SCRIPT_DIR/VERSION" ]] && version=$(cat "$SCRIPT_DIR/VERSION" | tr -d '[:space:]')
  command -v git &>/dev/null && commit=$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")

  # Build JSON modules array
  local modules_json
  modules_json=$(python3 -c "import sys, json; print(json.dumps(sys.argv[1:]))" "${modules[@]}")

  python3 -c "
import json
data = {
    'version': '$version',
    'commit': '$commit',
    'installedAt': '$date',
    'modules': $modules_json,
    'source': 'https://github.com/V0latix/claude-code-architecture'
}
with open('$tracking_file', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
  success "Tracking metadata saved: .claude/claude-architecture.json"
}

# Count installed components
count_installed() {
  local target="$1"
  local agents=0 skills=0 workflows=0 tools=0

  [[ -d "$target/.claude/agents" ]] && agents=$(find "$target/.claude/agents" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  [[ -d "$target/.claude/skills" ]] && skills=$(find "$target/.claude/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  [[ -d "$target/.claude/commands/workflows" ]] && workflows=$(find "$target/.claude/commands/workflows" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  [[ -d "$target/.claude/commands/tools" ]] && tools=$(find "$target/.claude/commands/tools" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

  echo "$agents $skills $workflows $tools"
}

# ─── List command ─────────────────────────────────────────────────────────────
cmd_list() {
  print_header
  bold "Available modules:\n"
  for mod in "${ALL_MODULES[@]}"; do
    local deps="${MODULE_DEPS[$mod]:-}"
    local dep_str=""
    [[ -n "$deps" ]] && dep_str=" ${YELLOW}(needs: $deps)${RESET}"
    printf "  ${CYAN}%-12s${RESET} %s%s\n" "$mod" "${MODULE_DESC[$mod]}" "$dep_str"
  done

  bold "\nAvailable bundles:\n"
  for bundle_file in "$BUNDLES_DIR"/*.json; do
    local name display desc modules
    name=$(basename "$bundle_file" .json)
    display=$(python3 -c "import json; d=json.load(open('$bundle_file')); print(d.get('displayName','$name'))")
    desc=$(python3 -c "import json; d=json.load(open('$bundle_file')); print(d.get('description',''))")
    modules=$(python3 -c "import json; d=json.load(open('$bundle_file')); print(', '.join(d['modules']))")
    printf "  ${GREEN}%-18s${RESET} %s\n" "$name" "$desc"
    printf "  %-18s ${YELLOW}modules: %s${RESET}\n\n" "" "$modules"
  done

  bold "Usage examples:"
  echo "  ./install.sh --modules vscode /path/to/project"
  echo "  ./install.sh --bundle full-stack /path/to/project"
  echo "  ./install.sh --all /path/to/project"
  echo "  ./install.sh /path/to/project  (interactive)"
}

# ─── Interactive mode ─────────────────────────────────────────────────────────
interactive_select() {
  local selected=()

  print_header
  bold "Select modules to install (space = toggle, enter = confirm):\n"
  echo -e "  ${YELLOW}[x] core${RESET}       — ALWAYS installed — ${MODULE_DESC[core]}"

  local toggles=()
  for mod in "${ALL_MODULES[@]:1}"; do  # skip core
    toggles+=("false")
  done

  local i=0
  local mods=("${ALL_MODULES[@]:1}")

  # Simple selection loop (non-interactive fallback)
  for mod in "${mods[@]}"; do
    local deps="${MODULE_DEPS[$mod]:-}"
    local dep_str=""
    [[ -n "$deps" ]] && dep_str=" (deps: $deps)"
    echo -e "  ${CYAN}[ ] $mod${RESET}$dep_str — ${MODULE_DESC[$mod]}"
  done

  echo ""
  echo -n "Enter module names separated by commas (or 'all'): "
  read -r user_input

  if [[ "$user_input" == "all" ]]; then
    selected=("${ALL_MODULES[@]}")
  else
    selected=("core")
    IFS=',' read -ra extra <<< "$user_input"
    for m in "${extra[@]}"; do
      m="$(echo "$m" | tr -d ' ')"
      [[ -n "$m" ]] && selected+=("$m")
    done
  fi

  echo "${selected[@]}"
}

# ─── Main install flow ────────────────────────────────────────────────────────
do_install() {
  local modules=("$@")
  local target="${modules[-1]}"
  unset 'modules[-1]'

  # Validate target
  if [[ -z "$target" ]]; then
    error "Target directory required"
    echo "Usage: ./install.sh [--modules m1,m2] <target-dir>"
    exit 1
  fi

  # Resolve dependencies
  local resolved
  IFS=' ' read -ra resolved <<< "$(resolve_deps "${modules[@]}")"

  # Show plan
  print_header
  bold "Installation plan:"
  echo -e "  Target: ${CYAN}$target${RESET}"
  echo -e "  Modules: ${GREEN}${resolved[*]}${RESET}\n"

  # Validate modules
  for mod in "${resolved[@]}"; do
    if [[ ! -f "$MODULES_DIR/$mod/module.json" ]]; then
      error "Unknown module: $mod"
      echo "Run ./install.sh --list to see available modules"
      exit 1
    fi
  done

  # Create target .claude structure
  mkdir -p "$target/.claude/agents"
  mkdir -p "$target/.claude/skills"
  mkdir -p "$target/.claude/commands/workflows"
  mkdir -p "$target/.claude/commands/tools"
  mkdir -p "$target/.claude/hooks/scripts"
  mkdir -p "$target/.claude/hooks/config"

  echo ""
  # Install each module
  for mod in "${resolved[@]}"; do
    install_module "$mod" "$target"
  done

  # Generate summary and save tracking metadata
  echo ""
  generate_summary "${resolved[@]}" "$target"
  save_tracking "${resolved[@]}" "$target"

  # Count results
  read -ra counts <<< "$(count_installed "$target")"
  local agents="${counts[0]:-0}" skills="${counts[1]:-0}"
  local workflows="${counts[2]:-0}" tools="${counts[3]:-0}"

  echo ""
  bold "Installation complete!"
  echo -e "  ${GREEN}✓${RESET} ${BOLD}$agents${RESET} agents  |  ${BOLD}$skills${RESET} skills  |  ${BOLD}$workflows${RESET} workflows  |  ${BOLD}$tools${RESET} tools"
  echo ""
  echo -e "  Next steps:"
  echo -e "  1. Copy your ${CYAN}CLAUDE.md${RESET} to $target/ (or use the installed CLAUDE-INSTALLED.md as reference)"
  echo -e "  2. Copy your ${CYAN}.mcp.json${RESET} if needed"
  echo -e "  3. Start Claude Code in $target/"
  echo ""
  echo -e "  To update later:"
  echo -e "  ${CYAN}./update.sh $target${RESET}"
  echo -e "  or remotely: ${CYAN}curl -fsSL $REPO_URL/raw/main/update.sh | bash -s $target${RESET}"
  echo ""
}

# ─── Entry point ─────────────────────────────────────────────────────────────
main() {
  local args=("$@")
  local modules_flag=""
  local bundle_flag=""
  local all_flag=false
  local list_flag=false
  local target=""

  # Parse flags
  while [[ ${#args[@]} -gt 0 ]]; do
    case "${args[0]}" in
      --modules)
        modules_flag="${args[1]}"
        args=("${args[@]:2}")
        ;;
      --bundle)
        bundle_flag="${args[1]}"
        args=("${args[@]:2}")
        ;;
      --all)
        all_flag=true
        args=("${args[@]:1}")
        ;;
      --list|-l)
        list_flag=true
        args=("${args[@]:1}")
        ;;
      -*)
        error "Unknown flag: ${args[0]}"
        exit 1
        ;;
      *)
        target="${args[0]}"
        args=("${args[@]:1}")
        ;;
    esac
  done

  # Handle --list
  if $list_flag; then
    cmd_list
    exit 0
  fi

  # Determine modules to install
  local selected_modules=()

  if $all_flag; then
    selected_modules=("${ALL_MODULES[@]}")
  elif [[ -n "$bundle_flag" ]]; then
    local bundle_file="$BUNDLES_DIR/$bundle_flag.json"
    if [[ ! -f "$bundle_file" ]]; then
      error "Bundle not found: $bundle_flag"
      echo "Available bundles: full-stack, ai-developer, complete"
      exit 1
    fi
    IFS=' ' read -ra selected_modules <<< "$(parse_bundle "$bundle_file")"
  elif [[ -n "$modules_flag" ]]; then
    IFS=',' read -ra selected_modules <<< "$modules_flag"
  elif [[ -n "$target" ]]; then
    # Interactive mode
    IFS=' ' read -ra selected_modules <<< "$(interactive_select)"
  else
    print_header
    echo "Usage: ./install.sh [--modules m1,m2,...] [--bundle name] [--all] [--list] <target-dir>"
    echo ""
    echo "Examples:"
    echo "  ./install.sh --list"
    echo "  ./install.sh --modules vscode /path/to/project"
    echo "  ./install.sh --bundle full-stack /path/to/project"
    echo "  ./install.sh --all /path/to/project"
    echo "  ./install.sh /path/to/project  (interactive)"
    exit 0
  fi

  if [[ -z "$target" ]]; then
    echo -n "Target directory: "
    read -r target
  fi

  do_install "${selected_modules[@]}" "$target"
}

main "$@"
