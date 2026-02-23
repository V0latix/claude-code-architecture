---
description: "Développement end-to-end d'une feature. Orchestre le cycle complet : specs → UX → architecture → implémentation → tests → performance → review → docs."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Feature Development End-to-End

Développement complet de la feature : **$ARGUMENTS**

## Phase 0 — Qualification

Analyser la nature de la feature pour activer les bons agents :

```bash
# Contexte projet
cat CLAUDE.md | grep -A5 "Stack"
```

Identifier :
- **Feature UI** → activer `ux-expert` + `frontend-specialist`
- **Feature API/Backend** → activer `developer` + `architect`
- **Feature LLM/IA** → rediriger vers `/workflows/ai-feature`
- **Feature data** → activer `data-scientist`
- **Feature avec auth** → activer `security-auditor` en priorité
- **Feature critique perf** → activer `performance-engineer`

## Phase 1 — Spécification

### `product-manager agent` (skills: architecture-diagrams, prompt-engineering)

Rédiger le PRD de `$ARGUMENTS` :
- Problème à résoudre + valeur utilisateur
- Exigences Must/Should/Could
- Critères d'acceptation (Given/When/Then)
- Métriques de succès + KPIs
- Hors périmètre

### `scrum-master agent` (skills: architecture-diagrams)

Découper en user stories avec estimations Fibonacci.

### `ux-expert agent` (skills: frontend-frameworks, architecture-diagrams)
*(Uniquement si la feature a une composante UI)*

- Wireframes ASCII/Mermaid du flow utilisateur
- Design tokens et composants nécessaires
- Parcours utilisateur complet
- Points d'attention accessibilité (WCAG 2.1 AA)

## Phase 2 — Architecture

### `architect agent` (skills: api-design, database-patterns, docker-k8s, architecture-diagrams, observability-patterns, auth-patterns, async-patterns)

1. Analyser l'impact sur l'architecture existante
2. Proposer le design technique avec diagramme Mermaid
3. Identifier les dépendances et risques
4. Décider du schéma de données si BDD touchée
5. Définir les endpoints API si applicable (spec OpenAPI)
6. Créer un ADR dans `/docs/decisions/` si décision significative

**Vérifications spécifiques :**
- Observabilité : logs/métriques/traces à ajouter ?
- Auth : nouvelle route = nouvelle vérification de permissions ?
- Database : index nécessaires ? Migrations backward-compatible ?

## Phase 3 — Implémentation

### Si feature UI → `frontend-specialist agent` (skills: frontend-frameworks, async-patterns, testing-patterns, auth-patterns, error-handling-patterns)

```bash
# Scaffolding des composants
/tools/scaffold component [nom-composant]
```

Ordre d'implémentation :
1. Composants atomiques (sans état)
2. Composants avec état local
3. Intégration des Server Actions/API calls
4. Gestion des états de chargement et d'erreur (error-handling-patterns)
5. Accessibilité (ARIA, focus, contraste)

### Si feature backend → `developer agent` (skills: async-patterns, testing-patterns, api-design, database-patterns, error-handling-patterns, auth-patterns)

Ordre TDD :
1. **Tests d'abord** selon les critères d'acceptation
2. **Implémentation minimale** qui fait passer les tests
3. **Refactoring** (Result type, error hierarchy si nouvelle erreur)
4. **Types stricts** — TypeScript strict check

```bash
npm run type-check
npm test
npm run lint
```

## Phase 4 — Qualité & Sécurité

### `qa-engineer agent` (skills: testing-patterns, error-handling-patterns, async-patterns)
- Coverage report — aucune régression sous le seuil projet
- Tests des edge cases et cas d'erreur
- Tests e2e pour le chemin critique utilisateur

### `security-auditor agent` (skills: security-scanning, auth-patterns, error-handling-patterns, api-design)
- Nouvelle surface d'attaque créée par la feature ?
- Auth correcte sur toutes les nouvelles routes ?
- Validation des inputs côté serveur ?
- Pas de PII dans les logs ?

### `performance-engineer agent` (skills: async-patterns, database-patterns, observability-patterns)
*(Activer si la feature touche des données volumineuses ou des chemins chauds)*
- Benchmark before/after si modification d'un endpoint existant
- N+1 queries ? Index nécessaires ?
- Opportunités de cache ?
- Réponse < SLO défini (p95 < 200ms par défaut)

## Phase 5 — Observabilité

### `devops-engineer agent` (skills: docker-k8s, observability-patterns, incident-response)

Pour chaque feature production :
- Logs structurés ajoutés aux points clés
- Métriques métier (compteur d'utilisation, taux d'erreur)
- Alerte définie si la feature a un SLO
- Health check mis à jour si nouveau service

## Phase 6 — Documentation

### `doc-writer agent` (skills: architecture-diagrams, api-design, document-processing)

- README mis à jour si changement d'interface publique
- Nouveaux endpoints documentés (OpenAPI/Swagger)
- Diagramme Mermaid si nouveau flux de données
- CHANGELOG mis à jour

## Phase 7 — Review finale

Lancer `/workflows/code-review $ARGUMENTS` avant merge.

## Rapport de livraison

```markdown
## Feature Livrée : $ARGUMENTS

### Agents utilisés
- [x] product-manager — PRD rédigé
- [x] architect — ADR créé : /docs/decisions/XXX.md
- [ ] ux-expert — N/A (pas de UI)
- [x] developer / frontend-specialist — Implémentation
- [x] qa-engineer — Tests (coverage: X%)
- [x] security-auditor — ✅ Aucun bloquant
- [ ] performance-engineer — N/A (pas de chemin chaud)
- [x] devops-engineer — Observabilité ajoutée

### Skills utilisées
- [error-handling-patterns] : Result type pour processOrder
- [auth-patterns] : Middleware /api/orders protégé
- [testing-patterns] : 12 nouveaux tests

### Fichiers modifiés : X
### Nouveaux tests : X | Coverage : X%
### Prêt pour merge : ✅ / ❌
```
