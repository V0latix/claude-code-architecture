#!/usr/bin/env bash
# Claude Code Architecture — Updater
# Updates previously installed modules to the latest version.
#
# Usage (from source repo):
#   ./update.sh [target-dir]
#   ./update.sh /path/to/project
#
# Usage (remote, no repo needed):
#   curl -fsSL https://raw.githubusercontent.com/V0latix/claude-code-architecture/main/update.sh | bash -s [target-dir]
#
# What it does:
#   1. Reads .claude/claude-architecture.json from target to find installed modules
#   2. Pulls/fetches the latest version of this repo
#   3. Re-installs the same modules (preserving your project files)

set -euo pipefail

REPO_URL="https://github.com/V0latix/claude-code-architecture"
REPO_RAW="https://raw.githubusercontent.com/V0latix/claude-code-architecture/main"

# ─── Colors ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}ℹ${RESET}  $*"; }
success() { echo -e "${GREEN}✓${RESET}  $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET}  $*"; }
error()   { echo -e "${RED}✗${RESET}  $*" >&2; }
bold()    { echo -e "${BOLD}$*${RESET}"; }

print_header() {
  echo -e "\n${BOLD}${BLUE}╔══════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${BLUE}║   Claude Code Architecture — Updater                     ║${RESET}"
  echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════╝${RESET}\n"
}

# ─── Detect execution context ─────────────────────────────────────────────────
# Are we running from inside the source repo, or piped from curl?
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
IS_SOURCE_REPO=false
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/install.sh" && -d "$SCRIPT_DIR/modules" ]]; then
  IS_SOURCE_REPO=true
fi

# ─── Read tracking metadata ───────────────────────────────────────────────────
read_tracking() {
  local target="$1"
  local tracking="$target/.claude/claude-architecture.json"

  if [[ ! -f "$tracking" ]]; then
    error "No tracking file found at $tracking"
    echo ""
    echo "This project was not installed with this tool, or was installed"
    echo "with an older version that didn't track metadata."
    echo ""
    echo "To update manually, re-run install.sh with your desired modules:"
    echo "  ./install.sh --modules <modules> $target"
    exit 1
  fi

  echo "$tracking"
}

get_modules() {
  local tracking="$1"
  python3 -c "
import json
with open('$tracking') as f:
    d = json.load(f)
print(' '.join(d['modules']))
"
}

get_version() {
  local tracking="$1"
  python3 -c "
import json
with open('$tracking') as f:
    d = json.load(f)
print(d.get('version', 'unknown'))
"
}

# ─── Get latest version from repo ────────────────────────────────────────────
get_latest_version() {
  local repo_dir="$1"
  if [[ -f "$repo_dir/VERSION" ]]; then
    cat "$repo_dir/VERSION" | tr -d '[:space:]'
  else
    echo "unknown"
  fi
}

get_latest_version_remote() {
  curl -fsSL "$REPO_RAW/VERSION" 2>/dev/null | tr -d '[:space:]' || echo "unknown"
}

# ─── Update via source repo ───────────────────────────────────────────────────
pull_source_repo() {
  local repo_dir="$SCRIPT_DIR"

  info "Pulling latest changes from GitHub..." >&2
  if git -C "$repo_dir" pull --ff-only origin main > /dev/null 2>&1; then
    success "Repository updated" >&2
  else
    warn "Could not fast-forward. Trying fetch + reset..." >&2
    git -C "$repo_dir" fetch origin main > /dev/null 2>&1
    git -C "$repo_dir" reset --hard origin/main > /dev/null 2>&1
    success "Repository reset to origin/main" >&2
  fi

  echo "$repo_dir"
}

# ─── Update via temp clone ────────────────────────────────────────────────────
clone_remote_repo() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  # Register cleanup on script exit
  trap "rm -rf '$tmp_dir'" EXIT

  info "Cloning latest version from GitHub..." >&2
  git clone --depth 1 "$REPO_URL" "$tmp_dir/repo" > /dev/null 2>&1
  success "Clone complete" >&2

  echo "$tmp_dir/repo"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  local target="${1:-$(pwd)}"

  # Resolve absolute path
  target="$(cd "$target" 2>/dev/null && pwd)" || {
    error "Directory not found: $1"
    exit 1
  }

  print_header

  # Read tracking metadata
  local tracking
  tracking=$(read_tracking "$target")

  local installed_modules installed_version
  IFS=' ' read -ra installed_modules <<< "$(get_modules "$tracking")"
  installed_version=$(get_version "$tracking")

  info "Target: ${BOLD}$target${RESET}"
  info "Installed version: ${YELLOW}$installed_version${RESET}"
  info "Installed modules: ${CYAN}${installed_modules[*]}${RESET}"
  echo ""

  # Get source repo (local or remote)
  local repo_dir latest_version

  if $IS_SOURCE_REPO; then
    repo_dir=$(pull_source_repo)
  else
    if ! command -v git &>/dev/null; then
      error "git is required for remote updates"
      exit 1
    fi
    repo_dir=$(clone_remote_repo)
  fi

  latest_version=$(get_latest_version "$repo_dir")

  info "Latest version: ${GREEN}$latest_version${RESET}"

  # Compare versions
  if [[ "$installed_version" == "$latest_version" ]]; then
    echo ""
    success "Already up to date! (version $latest_version)"
    echo ""
    exit 0
  fi

  echo ""
  bold "Updating $installed_version → $latest_version"
  echo ""

  # Re-install with same modules using the updated install.sh
  bash "$repo_dir/install.sh" --modules "$(IFS=','; echo "${installed_modules[*]}")" "$target"

  echo ""
  success "Update complete! ${BOLD}$installed_version${RESET} → ${BOLD}$latest_version${RESET}"
  echo ""
}

main "$@"
