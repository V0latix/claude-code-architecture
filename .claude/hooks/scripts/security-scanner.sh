#!/usr/bin/env bash
# security-scanner.sh
# Hook PreToolUse (Edit|Write) : Bloque l'écriture dans les fichiers sensibles
# Exit code 2 = bloquer l'opération
# Exit code 0 = autoriser l'opération

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

# Liste des fichiers et patterns sensibles à protéger
BLOCKED_PATTERNS=(
  ".env"
  ".env.local"
  ".env.production"
  ".env.staging"
  "package-lock.json"
  "yarn.lock"
  "pnpm-lock.yaml"
  ".git/"
  "*.pem"
  "*.key"
  "*.p12"
  "*.pfx"
  "id_rsa"
  "id_ed25519"
  ".npmrc"
  ".netrc"
)

# Vérifier si le fichier correspond à un pattern bloqué
for pattern in "${BLOCKED_PATTERNS[@]}"; do
  # Vérification exacte du nom de fichier
  BASENAME="$(basename "$FILE_PATH")"
  if [[ "$BASENAME" == "$pattern" ]] || [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "⛔ BLOCKED: Modification of sensitive file '$FILE_PATH' is not allowed." >&2
    echo "   This file is protected by the security-scanner hook." >&2
    echo "   If you need to modify it, do it manually." >&2
    exit 2
  fi
done

# Vérifier l'extension pour les fichiers de clés
case "$FILE_PATH" in
  *.pem|*.key|*.p12|*.pfx|*.crt|*.cer)
    echo "⛔ BLOCKED: Modification of certificate/key file '$FILE_PATH' is not allowed." >&2
    exit 2
    ;;
esac

# Autoriser l'opération
exit 0
