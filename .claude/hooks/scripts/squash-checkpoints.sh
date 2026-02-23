#!/usr/bin/env bash
# squash-checkpoints.sh
# Hook Stop : Squash les commits de checkpoint en un seul commit propre
# Se déclenche à la fin de chaque réponse Claude Code

set -euo pipefail

# Vérifier qu'on est dans un repo git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  exit 0
fi

# Compter les commits de checkpoint
CHECKPOINT_COUNT="$(git log --oneline | grep -c "^[a-f0-9]* checkpoint:" 2>/dev/null || echo 0)"

# Ne squasher que s'il y a au moins 2 checkpoints
if [ "$CHECKPOINT_COUNT" -lt 2 ]; then
  exit 0
fi

# Trouver le commit avant le premier checkpoint
FIRST_CHECKPOINT_HASH="$(git log --oneline | grep "checkpoint:" | tail -1 | awk '{print $1}')"
PARENT_HASH="$(git rev-parse "${FIRST_CHECKPOINT_HASH}^" 2>/dev/null || echo "")"

if [ -z "$PARENT_HASH" ]; then
  exit 0
fi

# Créer le message du commit squashé
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
FILES_CHANGED="$(git diff --name-only "$PARENT_HASH" HEAD | head -10 | tr '\n' ', ' | sed 's/,$//')"

# Soft reset vers le parent du premier checkpoint
git reset --soft "$PARENT_HASH" 2>/dev/null || exit 0

# Créer le commit final propre
git commit -m "feat: Claude Code session [$TIMESTAMP]

Files changed: $FILES_CHANGED

Squashed $CHECKPOINT_COUNT checkpoint commits." \
  --no-verify \
  2>/dev/null || exit 0

exit 0
