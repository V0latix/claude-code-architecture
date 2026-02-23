---
description: "Review de code multi-perspectives. Lance des analyses en parallèle depuis 4 expertises différentes et compile un rapport structuré avec priorités."
allowed-tools: Bash, Read, Grep, Glob, Task
---

# Code Review Multi-Perspectives

Review complète du code suivant : **$ARGUMENTS**

## Instructions

Lance une review parallèle avec les 4 agents spécialisés suivants :

### Agent 1 — Developer (Qualité & Maintenabilité)
Analyser :
- Lisibilité et clarté du code
- Respect des conventions du projet (CLAUDE.md)
- DRY, SOLID, principes de clean code
- Complexité cyclomatique et cognitive
- Gestion d'erreurs et edge cases

### Agent 2 — Security Auditor (Sécurité)
Analyser :
- OWASP Top 10
- Injection, XSS, CSRF
- Exposition de données sensibles
- Contrôle d'accès et autorisation
- Secrets ou credentials dans le code

### Agent 3 — QA Engineer (Testabilité & Qualité)
Analyser :
- Présence et qualité des tests
- Couverture des cas d'erreur et edge cases
- Testabilité du code (injection de dépendances)
- Assertions et contrats d'interface

### Agent 4 — Architect (Architecture & Design)
Analyser :
- Respect de l'architecture existante
- Couplage et cohésion
- Patterns utilisés (corrects ?)
- Impact sur la scalabilité
- Dettes techniques introduites

## Format du rapport final

```markdown
# Code Review — $ARGUMENTS

## Score global : X/10

## ✅ Points positifs
- ...

## 🔴 Bloquants (must fix avant merge)
| # | Fichier:Ligne | Problème | Catégorie | Solution |
|---|--------------|----------|-----------|---------|
| 1 | ... | ... | Security | ... |

## 🟡 Importants (should fix)
| # | Fichier:Ligne | Problème | Catégorie |
|---|--------------|----------|-----------|

## 🟢 Suggestions (nice to have)
- ...

## Résumé par dimension
- Qualité : X/10
- Sécurité : X/10
- Tests : X/10
- Architecture : X/10
```
