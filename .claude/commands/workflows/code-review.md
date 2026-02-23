---
description: "Review de code multi-perspectives par 5 agents spécialisés. Lance des analyses en parallèle sur qualité, sécurité, tests, architecture et performance, puis compile un rapport structuré avec priorités."
allowed-tools: Bash, Read, Grep, Glob, Task
---

# Code Review Multi-Perspectives

Review complète du code suivant : **$ARGUMENTS**

## Préparation

```bash
# Lire les fichiers concernés
cat $ARGUMENTS 2>/dev/null || find . -path "*$ARGUMENTS*" -name "*.ts" | head -10

# Contexte git : qu'est-ce qui a changé ?
git diff HEAD -- $ARGUMENTS 2>/dev/null | head -100
git log --oneline -5 -- $ARGUMENTS 2>/dev/null
```

## Analyses parallèles — 5 agents (lancer avec Task)

### Agent 1 — `code-reviewer agent`
**Skills activées : async-patterns, testing-patterns, security-scanning, error-handling-patterns, database-patterns, auth-patterns**

Analyse globale multi-axes :
- Lisibilité, nommage, complexité cyclomatique
- Respect des conventions du projet (CLAUDE.md)
- DRY, SOLID, couplage/cohésion
- Gestion d'erreurs (Result type, error boundaries, edge cases)
- Patterns async (unhandled promises, séquentiel inutile)

### Agent 2 — `security-auditor agent`
**Skills activées : security-scanning, auth-patterns, error-handling-patterns, api-design**

- OWASP Top 10 complet
- Injection (SQL, NoSQL, command, template)
- Authentification et autorisation (RBAC, IDOR, privilege escalation)
- Exposition de données sensibles (PII, credentials, tokens)
- Secrets hardcodés ou loggués
- XSS, CSRF, headers de sécurité manquants

### Agent 3 — `qa-engineer agent`
**Skills activées : testing-patterns, error-handling-patterns, async-patterns**

- Présence et qualité des tests
- Couverture des cas d'erreur, cas limites, cas nominaux
- Testabilité du code (injection de dépendances, mocks)
- Tests async corrects (await manquants, timeouts)
- Assertions significatives (pas de tests qui testent les mocks)

### Agent 4 — `architect agent`
**Skills activées : api-design, database-patterns, architecture-diagrams, observability-patterns, auth-patterns, async-patterns**

- Respect de l'architecture du projet
- Couplage entre modules, dépendances circulaires
- Patterns architecturaux corrects (Repository, Service layer, etc.)
- Impact sur la scalabilité et la maintenabilité
- Dettes techniques introduites
- Schémas de BDD et requêtes (N+1, index manquants)
- Observabilité : logs, métriques, traces présents ?

### Agent 5 — `performance-engineer agent`
**Skills activées : async-patterns, database-patterns, observability-patterns, error-handling-patterns**

- Complexité algorithmique (O(n²) évitable ?)
- Requêtes en boucle (N+1 patterns)
- Mémoire : fuites, objets non libérés
- Appels I/O séquentiels au lieu de parallèles
- Bundle size (imports inutiles, tree-shaking)
- Opportunités de cache

## Agents supplémentaires selon le contexte

**Si le code contient du code LLM/IA :**
→ Ajouter `ai-engineer agent` (skills: llm-ai-patterns, prompt-engineering)
→ Vérifier : prompt injection, coûts LLM, structured output validation

**Si le code concerne des composants React/Next.js :**
→ Ajouter `frontend-specialist agent` (skills: frontend-frameworks)
→ Vérifier : Server vs Client Components, hydration, bundle size

**Si le code concerne de la gestion de données :**
→ Ajouter `data-scientist agent` (skills: data-engineering, database-patterns)
→ Vérifier : qualité des données, validation, schémas

## Format du rapport final

```markdown
# Code Review — $ARGUMENTS
**Date** : [date]  **Reviewers** : 5 agents spécialisés

## Score global : X/10
| Dimension | Score | Résumé |
|-----------|-------|--------|
| Qualité & Maintenabilité | X/10 | ... |
| Sécurité | X/10 | ... |
| Tests | X/10 | ... |
| Architecture | X/10 | ... |
| Performance | X/10 | ... |

## ✅ Points positifs
- ...

## 🔴 Bloquants — Must fix avant merge
| # | Fichier:Ligne | Problème | Catégorie | Solution |
|---|--------------|----------|-----------|---------|
| 1 | ... | ... | Security/Perf/Quality | ... |

## 🟡 Importants — Should fix
| # | Fichier:Ligne | Problème | Catégorie | Solution |
|---|--------------|----------|-----------|---------|

## 🟢 Suggestions — Nice to have
- ...

## Skills recommandées pour la correction
- [error-handling-patterns] si gestion d'erreurs insuffisante
- [auth-patterns] si problèmes d'authentification
- [async-patterns] si code async mal géré
```
