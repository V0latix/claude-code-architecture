#!/usr/bin/env bash
# context-injector.sh
# Hook SessionStart : Injecte le contexte projet dans les logs de session
# Se déclenche au démarrage de chaque session Claude Code

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LOG_FILE="${HOME}/.claude/session-log.txt"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# Créer le répertoire de logs si nécessaire
mkdir -p "$(dirname "$LOG_FILE")"

# Logger le démarrage de session
echo "[$TIMESTAMP] Session started in: $PROJECT_ROOT" >> "$LOG_FILE"

# Afficher un résumé du contexte projet
if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
  echo "[$TIMESTAMP] CLAUDE.md found — project context loaded" >> "$LOG_FILE"
fi

# Compter les agents, skills et commandes disponibles
AGENTS_COUNT=$(find "$PROJECT_ROOT/.claude/agents" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
SKILLS_COUNT=$(find "$PROJECT_ROOT/.claude/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
COMMANDS_COUNT=$(find "$PROJECT_ROOT/.claude/commands" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

echo "[$TIMESTAMP] Available: ${AGENTS_COUNT} agents, ${SKILLS_COUNT} skills, ${COMMANDS_COUNT} commands" >> "$LOG_FILE"

# Afficher le statut git si dans un repo
if git rev-parse --git-dir > /dev/null 2>&1; then
  BRANCH="$(git branch --show-current 2>/dev/null || echo 'unknown')"
  UNCOMMITTED="$(git status --short 2>/dev/null | wc -l | tr -d ' ')"
  echo "[$TIMESTAMP] Git: branch=$BRANCH, uncommitted_files=$UNCOMMITTED" >> "$LOG_FILE"
fi

# Afficher les leçons apprises si le fichier existe
LESSONS_FILE="$PROJECT_ROOT/tasks/lessons.md"
if [ -f "$LESSONS_FILE" ]; then
  echo ""
  echo "📚 Leçons apprises (tasks/lessons.md) :"
  cat "$LESSONS_FILE"
  echo ""
fi

exit 0
