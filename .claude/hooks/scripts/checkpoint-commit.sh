#!/usr/bin/env bash
# checkpoint-commit.sh
# Hook PostToolUse (Write|MultiEdit) : Crée des commits de checkpoint automatiques
# Ces commits sont squashés en fin de session par squash-checkpoints.sh

set -euo pipefail

# Vérifier qu'on est dans un repo git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  exit 0
fi

# Vérifier s'il y a des changements à committer
if git diff --quiet && git diff --cached --quiet; then
  exit 0
fi

# Vérifier que git est configuré
if ! git config user.email > /dev/null 2>&1; then
  git config user.email "claude-code@checkpoint" 2>/dev/null || exit 0
  git config user.name "Claude Code" 2>/dev/null || exit 0
fi

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# Stager tous les fichiers modifiés (sauf les sensibles)
git add --all -- \
  ':!.env' ':!.env.*' ':!*.pem' ':!*.key' ':!package-lock.json' \
  2>/dev/null || true

# Vérifier à nouveau après staging
if git diff --cached --quiet; then
  exit 0
fi

# Créer le commit de checkpoint
CHANGED_FILES="$(git diff --cached --name-only | head -3 | tr '\n' ', ' | sed 's/,$//')"
git commit -m "checkpoint: auto-save [$TIMESTAMP] — $CHANGED_FILES" \
  --no-verify \
  2>/dev/null || exit 0

exit 0
