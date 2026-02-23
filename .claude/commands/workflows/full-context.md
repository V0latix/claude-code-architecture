---
description: "Analyse multi-agents complète d'une feature ou d'un problème. Lance des analyses en parallèle selon la nature de la demande et compile une synthèse actionnable."
allowed-tools: Bash, Read, Grep, Glob, Task
---

# Full Context Analysis

Analyse complète de la demande suivante : **$ARGUMENTS**

## Étape 1 — Découverte du contexte

Lire et comprendre le projet actuel :
- Lire `CLAUDE.md` (stack, conventions, routing agents)
- Identifier les fichiers et modules concernés par `$ARGUMENTS`
- Détecter la nature de la demande (feature, bug, architecture, IA, performance, incident...)

```bash
# Cartographier les fichiers concernés
grep -r "$ARGUMENTS" src/ --include="*.ts" -l 2>/dev/null | head -20
cat CLAUDE.md
```

## Étape 2 — Sélection et lancement des agents

Lancer en **parallèle avec Task** les agents pertinents selon la nature de `$ARGUMENTS` :

### Agents de base (toujours actifs)

**`analyst agent`** (skills: architecture-diagrams, prompt-engineering)
→ Cadrer le problème, identifier les besoins utilisateur, risques métier

**`architect agent`** (skills: api-design, database-patterns, docker-k8s, architecture-diagrams, observability-patterns, auth-patterns, async-patterns)
→ Impact architectural, dépendances, design, diagramme C4 si pertinent

**`security-auditor agent`** (skills: security-scanning, auth-patterns, error-handling-patterns)
→ Risques de sécurité, surfaces d'attaque, conformité

**`qa-engineer agent`** (skills: testing-patterns, error-handling-patterns, async-patterns)
→ Stratégie de tests, critères de qualité, edge cases

### Agents spécialisés (selon la nature de la demande)

**Si la demande concerne du code applicatif :**
→ `developer agent` (skills: async-patterns, error-handling-patterns, database-patterns, auth-patterns)
→ Plan d'implémentation, patterns à utiliser, dépendances

**Si la demande concerne l'UI/UX ou des composants frontend :**
→ `ux-expert agent` (skills: frontend-frameworks, architecture-diagrams) — design
→ `frontend-specialist agent` (skills: frontend-frameworks, auth-patterns, error-handling-patterns) — implémentation

**Si la demande concerne un LLM, RAG, agent ou feature IA :**
→ `ai-engineer agent` (skills: llm-ai-patterns, prompt-engineering, async-patterns)
→ Architecture pipeline LLM, choix de modèle, stratégie de prompt

**Si la demande concerne les performances ou la scalabilité :**
→ `performance-engineer agent` (skills: observability-patterns, database-patterns, async-patterns)
→ Benchmarks, goulots d'étranglement, optimisations

**Si la demande concerne l'infra, le déploiement ou le monitoring :**
→ `devops-engineer agent` (skills: docker-k8s, observability-patterns, mcp-builder, incident-response)
→ Pipeline CI/CD, infrastructure, SLOs

**Si la demande concerne les données ou le machine learning :**
→ `data-scientist agent` (skills: data-engineering, database-patterns)
→ Analyse, pipeline de données, modélisation

## Étape 3 — Plan d'implémentation

Consolider les analyses et produire un plan ordonné :
- Étapes avec dépendances explicites
- Estimation de complexité par étape (S/M/L)
- Risques identifiés et mitigations

## Étape 4 — Synthèse finale

```markdown
# Analyse Complète : $ARGUMENTS

## Résumé exécutif
[2-3 phrases — ce que c'est, pourquoi c'est important, l'approche retenue]

## Contexte & Problème
[Analyse de l'analyst — besoins utilisateur, valeur métier, risques]

## Architecture proposée
[Recommandations de l'architect — avec diagramme Mermaid si pertinent]

## Impacts croisés
| Dimension | Impact | Agent |
|-----------|--------|-------|
| Sécurité | ... | security-auditor |
| Performance | ... | performance-engineer |
| Tests | ... | qa-engineer |
| UX | ... | ux-expert |
| IA | ... | ai-engineer |
| Infra | ... | devops-engineer |

## Plan d'implémentation
### Phase 1 (S) — ...
### Phase 2 (M) — ...
### Phase 3 (L) — ...

## Skills recommandées pour cette feature
- [skill-name] : [pourquoi]

## Prochaines étapes
1. ...
2. ...
3. ...

## Agents à utiliser pour la suite
- Implémentation : `use developer agent` / `use frontend-specialist agent`
- Tests : `use qa-engineer agent`
- Review finale : `/workflows/code-review`
```
