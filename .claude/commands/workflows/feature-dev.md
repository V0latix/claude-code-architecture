---
description: "Développement end-to-end d'une nouvelle feature sur un projet existant. Assume que le contexte projet existe (project-context.md, architecture.md). Si ce n'est pas le cas, lancer d'abord /workflows/bmad-brownfield."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Feature Development End-to-End

Feature à développer : **$ARGUMENTS**

---

## Prérequis — Contexte projet

```bash
[ -f docs/project-context.md ] && echo "✅ Contexte disponible" || echo "⚠️ STOP : lancer /workflows/bmad-brownfield en premier"
[ -f docs/architecture.md ]    && echo "✅ Architecture disponible" || echo "⬜ architecture.md absent"
```

> **Si `docs/project-context.md` est absent → STOP.**
> Lancer `/workflows/bmad-brownfield` d'abord pour créer le contexte du projet, puis revenir ici.

---

## Phase 0 — Qualification

Lire le contexte et qualifier la feature :

```bash
cat docs/project-context.md | head -40
cat docs/architecture.md 2>/dev/null | head -30
cat docs/prd.md 2>/dev/null | head -30
ls docs/epic-*.md 2>/dev/null
```

Identifier le type de feature pour router les bons agents :

- **Feature UI** → activer `ux-expert` + `frontend-specialist`
- **Feature API/Backend** → activer `developer` + `architect`
- **Feature LLM/IA** → rediriger vers `/workflows/ai-feature`
- **Feature data** → activer `data-scientist`
- **Feature avec auth** → activer `security-auditor` en priorité
- **Feature critique perf** → activer `performance-engineer`
- **Changement petit/clair (< 2h)** → envisager `/workflows/bmad-quick` à la place

---

## Phase 1 — Specs

### `product-manager agent` (skills: architecture-diagrams, prompt-engineering)

Vérifier si la feature entre dans le périmètre du PRD existant. Si non ou si pas de PRD :
- Problème à résoudre + valeur utilisateur
- Exigences Must/Should/Could
- Critères d'acceptation (Given/When/Then)
- Métriques de succès + KPIs
- Hors périmètre

### `ux-expert agent` (skills: frontend-frameworks, architecture-diagrams)
*(Uniquement si la feature a une composante UI)*

- Wireframes ASCII/Mermaid du flow utilisateur
- Design tokens et composants nécessaires
- Parcours utilisateur complet
- Points d'attention accessibilité (WCAG 2.1 AA)

---

## Phase 2 — Architecture & Story

### `architect agent` (skills: api-design, database-patterns, docker-k8s, architecture-diagrams, observability-patterns, auth-patterns, async-patterns)

1. Analyser l'impact sur l'architecture existante
2. Proposer le design technique avec diagramme Mermaid
3. Identifier les dépendances et risques
4. Décider du schéma de données si BDD touchée
5. Définir les endpoints API si applicable (spec OpenAPI)
6. Créer un ADR dans `/docs/decisions/` si décision significative

**Vérifications :**
- Auth : nouvelle route = nouvelle vérification de permissions ?
- Database : index nécessaires ? Migrations backward-compatible ?
- Observabilité : logs/métriques à ajouter ?

### `product-manager agent` — Épic si nécessaire

```bash
ls docs/epic-*.md 2>/dev/null | xargs grep "## Titre" 2>/dev/null
```

*(Sauter si la feature s'intègre dans un épic existant)*

Créer `docs/epic-[N].md` selon `docs/bmad/templates/epic-tmpl.md`. Aligner sur le PRD, pas de scope creep.

### `scrum-master agent` (skills: architecture-diagrams)

```bash
cat docs/project-context.md
cat docs/epic-[N].md 2>/dev/null
ls docs/stories/ 2>/dev/null
```

Créer `docs/stories/epic-[N]-story-[M].md` selon `docs/bmad/templates/story-tmpl.md`.

**Dev Notes — toujours inclure :**
- Les fichiers existants à modifier (chemins exacts)
- Les patterns existants à respecter (exemples du code actuel)
- Les tests existants à mettre à jour
- Les migrations BDD nécessaires
- Les edge cases liés à l'existant

Valider avec `docs/bmad/checklists/story-creation.md`.

---

## Phase 3 — Implémentation

### Si feature UI → `frontend-specialist agent` (skills: frontend-frameworks, async-patterns, testing-patterns, auth-patterns, error-handling-patterns)

```bash
/tools/scaffold component [nom-composant]
```

Ordre :
1. Composants atomiques (sans état)
2. Composants avec état local
3. Intégration Server Actions/API calls
4. Gestion des états de chargement et d'erreur
5. Accessibilité (ARIA, focus, contraste)

### Si feature backend → `developer agent` (skills: async-patterns, testing-patterns, api-design, database-patterns, error-handling-patterns, auth-patterns)

```bash
cat docs/project-context.md
cat docs/stories/epic-[N]-story-[M].md
```

Ordre TDD :
1. **Tests d'abord** selon les critères d'acceptation
2. Analyser les tests existants avant d'écrire les nouveaux
3. **Implémentation minimale** qui fait passer les tests
4. Suivre exactement les patterns de `project-context.md`
5. **Refactoring** (Result type, error hierarchy si nouvelle erreur)

```bash
npm run type-check && npm test && npm run lint
```

---

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
- Benchmark before/after
- N+1 queries ? Index nécessaires ?
- Réponse < SLO (p95 < 200ms par défaut)

---

## Phase 5 — Observabilité

### `devops-engineer agent` (skills: docker-k8s, observability-patterns, incident-response)

- Logs structurés aux points clés
- Métriques métier (compteur d'utilisation, taux d'erreur)
- Alerte si la feature a un SLO
- Health check mis à jour si nouveau service

---

## Phase 6 — Documentation & Review

### `doc-writer agent` (skills: architecture-diagrams, api-design, document-processing)

- README mis à jour si changement d'interface publique
- Nouveaux endpoints documentés (OpenAPI/Swagger)
- CHANGELOG mis à jour

### Mise à jour de `docs/project-context.md`

Si de nouveaux patterns ont émergé pendant l'implémentation, les documenter dans `project-context.md`.

### Review finale

Lancer `/workflows/code-review $ARGUMENTS` avant merge.

---

## Rapport de livraison

```markdown
## Feature Livrée : $ARGUMENTS

### Artifacts BMAD
- Story : docs/stories/epic-[N]-story-[M].md ✅
- project-context.md : ✅ Mis à jour (si nouveaux patterns)

### Agents utilisés
- [x] product-manager — PRD / epic
- [x] architect — ADR : /docs/decisions/XXX.md
- [ ] ux-expert — N/A
- [x] developer / frontend-specialist — Implémentation TDD
- [x] qa-engineer — Coverage : X%
- [x] security-auditor — ✅ Aucun bloquant
- [ ] performance-engineer — N/A
- [x] devops-engineer — Observabilité ajoutée

### Fichiers modifiés : X | Nouveaux tests : X | Coverage : X%
### Prêt pour merge : ✅ / ❌
```
