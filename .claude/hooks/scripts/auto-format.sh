#!/usr/bin/env bash
# auto-format.sh
# Hook PostToolUse (Edit|Write) : Formate automatiquement le fichier après écriture
# Lit le chemin du fichier depuis stdin (JSON de Claude Code)

set -euo pipefail

# Lire le JSON depuis stdin et extraire le chemin du fichier
FILE_PATH="$(cat - | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null || echo "")"

# Sortir si pas de chemin
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Sortir si le fichier n'existe pas
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Formatter selon l'extension
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss)
    # Prettier si disponible
    if command -v npx &>/dev/null; then
      npx prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.py)
    # Black si disponible
    if command -v black &>/dev/null; then
      black "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.go)
    # gofmt si disponible
    if command -v gofmt &>/dev/null; then
      gofmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.sh)
    # shfmt si disponible
    if command -v shfmt &>/dev/null; then
      shfmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

exit 0
