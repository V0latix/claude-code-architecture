---
description: "Développement end-to-end d'une feature sur un projet existant. Commence par un diagnostic des artifacts existants, crée une story BMAD, puis orchestre le cycle complet : architecture → implémentation → tests → sécurité → observabilité → docs → review."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Feature Development End-to-End

Feature / amélioration à développer : **$ARGUMENTS**

---

## Phase 0 — Diagnostic & Qualification

### 0A — Vérifier les artifacts existants

```bash
echo "=== Diagnostic Projet ==="

echo "--- Artifacts BMAD ---"
[ -f docs/project-context.md ] && echo "✅ project-context.md" || echo "⬜ project-context.md (manquant)"
[ -f docs/prd.md ]              && echo "✅ prd.md"              || echo "⬜ prd.md"
[ -f docs/architecture.md ]     && echo "✅ architecture.md"     || echo "⬜ architecture.md"
ls docs/epic-*.md 2>/dev/null   && echo "✅ Épics trouvés"       || echo "⬜ Pas d'épics"
ls docs/stories/ 2>/dev/null    && echo "✅ Stories trouvées"    || echo "⬜ Pas de stories"

echo "--- Codebase ---"
cat package.json 2>/dev/null | grep '"version"' | head -1
find src -name "*.ts" 2>/dev/null | wc -l
find src -name "*.test.ts" -o -name "*.spec.ts" 2>/dev/null | wc -l
git log --oneline -5 2>/dev/null
```

**Décision selon le diagnostic** :

| Situation | Action |
|-----------|--------|
| `project-context.md` existe | → Passer à Phase 1 directement |
| Pas de `project-context.md` mais `architecture.md` existe | → Phase 0B (génération rapide) |
| Rien n'existe | → Phase 0C (génération complète via `/workflows/repo-context` recommandé) |

### 0B — Générer `docs/project-context.md` si inexistant

### `architect agent` + `developer agent`

```bash
# Stack réel
cat package.json | grep -E '"(dependencies|devDependencies)"' -A 40 | head -60
cat tsconfig.json 2>/dev/null

# Patterns existants
find src -name "*.service.ts" | head -3 | xargs cat 2>/dev/null | head -80
find src -name "*.test.ts" | head -2 | xargs cat 2>/dev/null | head -60

# Auth et error handling
grep -r "getServerSession\|auth()\|middleware" src/ --include="*.ts" -l 2>/dev/null | head -5
grep -r "Result\|AppError\|throw new" src/ --include="*.ts" -l 2>/dev/null | head -5

# Schéma BDD
cat prisma/schema.prisma 2>/dev/null | head -60
```

Créer `docs/project-context.md` (constitution du projet) :

```markdown
# Project Context — [Nom du projet]
> Généré le [date] via /workflows/feature-dev

## Technology Stack & Versions
- [Versions exactes]

## Critical Implementation Rules

### TypeScript
- [Strict mode ? any autorisé ?]
- [Conventions de nommage]

### Code Organization
- [Où créer les composants, services, etc.]
- [Conventions de nommage fichiers]

### Patterns Obligatoires
- Error handling : [Result type / throw / codes]
- Auth : [Comment vérifier les permissions]
- DB access : [Direct Prisma / Repository pattern]
- Async : [Patterns utilisés]

### Testing
- [Framework, patterns, où mettre les tests]
- [Coverage minimum]

### Ce qu'il NE FAUT PAS faire
- [Anti-patterns observés dans le code existant]
- [Pièges identifiés]
```

### 0C — Qualifier la nature de la feature

Identifier pour router les bons agents :

- **Feature UI** → activer `ux-expert` + `frontend-specialist`
- **Feature API/Backend** → activer `developer` + `architect`
- **Feature LLM/IA** → rediriger vers `/workflows/ai-feature`
- **Feature data** → activer `data-scientist`
- **Feature avec auth** → activer `security-auditor` en priorité
- **Feature critique perf** → activer `performance-engineer`
- **Changement petit/clair** → envisager `/workflows/bmad-quick` à la place

---

## Phase 1 — Cadrage

### `analyst agent` (skills: architecture-diagrams, prompt-engineering)

```bash
cat docs/project-context.md 2>/dev/null || cat CLAUDE.md
cat docs/prd.md 2>/dev/null | head -40
cat docs/architecture.md 2>/dev/null | head -60
```

Cadrer la demande `$ARGUMENTS` :
- La demande est-elle dans le périmètre du PRD existant ?
- Quel(s) module(s) existants sont touchés ?
- Y a-t-il des dépendances sur des stories/épics existants ?
- Nécessite-t-elle un changement d'architecture ?
- Périmètre : 1 composant ou plusieurs ?

### `product-manager agent` (skills: architecture-diagrams, prompt-engineering)

Si pas de PRD existant ou la feature dépasse le périmètre :
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
- Observabilité : logs/métriques/traces à ajouter ?
- Auth : nouvelle route = nouvelle vérification de permissions ?
- Database : index nécessaires ? Migrations backward-compatible ?

### `product-manager agent` (si épic nécessaire)

```bash
ls docs/epic-*.md 2>/dev/null | xargs grep "## Titre" 2>/dev/null
```

*(Sauter si la feature s'intègre dans un épic existant)*

Créer `docs/epic-[N].md` selon `docs/bmad/templates/epic-tmpl.md`. Aligner sur le PRD, pas de scope creep.

### `scrum-master agent` (skills: architecture-diagrams)

```bash
cat docs/project-context.md 2>/dev/null || cat CLAUDE.md
cat docs/architecture.md 2>/dev/null | head -60
cat docs/epic-[N].md 2>/dev/null
ls docs/stories/ 2>/dev/null
```

Créer `docs/stories/epic-[N]-story-[M].md` selon `docs/bmad/templates/story-tmpl.md`.

**Dans les Dev Notes, toujours inclure pour un projet existant :**
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

Ordre d'implémentation :
1. Composants atomiques (sans état)
2. Composants avec état local
3. Intégration Server Actions/API calls
4. Gestion des états de chargement et d'erreur
5. Accessibilité (ARIA, focus, contraste)

### Si feature backend → `developer agent` (skills: async-patterns, testing-patterns, api-design, database-patterns, error-handling-patterns, auth-patterns)

```bash
cat docs/project-context.md 2>/dev/null || cat CLAUDE.md
cat docs/stories/epic-[N]-story-[M].md 2>/dev/null
```

Ordre TDD :
1. **Tests d'abord** selon les critères d'acceptation
2. Analyser les tests existants avant d'écrire les nouveaux
3. **Implémentation minimale** qui fait passer les tests
4. Ne pas changer le comportement de l'existant sans l'indiquer dans la story
5. Suivre exactement les patterns de `project-context.md`
6. **Refactoring** (Result type, error hierarchy si nouvelle erreur)

```bash
npm run type-check
npm test
npm run lint
```

---

## Phase 4 — Qualité & Sécurité

### `qa-engineer agent` (skills: testing-patterns, error-handling-patterns, async-patterns)
- Coverage report — aucune régression sous le seuil projet
- Tests des edge cases et cas d'erreur
- Tests e2e pour le chemin critique utilisateur
- Suite de tests existante toujours au vert

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

---

## Phase 5 — Observabilité

### `devops-engineer agent` (skills: docker-k8s, observability-patterns, incident-response)

Pour chaque feature production :
- Logs structurés ajoutés aux points clés
- Métriques métier (compteur d'utilisation, taux d'erreur)
- Alerte définie si la feature a un SLO
- Health check mis à jour si nouveau service

---

## Phase 6 — Documentation & Review

### `doc-writer agent` (skills: architecture-diagrams, api-design, document-processing)

- README mis à jour si changement d'interface publique
- Nouveaux endpoints documentés (OpenAPI/Swagger)
- Diagramme Mermaid si nouveau flux de données
- CHANGELOG mis à jour

### Mise à jour de `docs/project-context.md`

Si de nouveaux patterns ont émergé pendant l'implémentation :

```bash
# Ajouter les nouvelles conventions découvertes
# Documenter les pièges rencontrés
# Mettre à jour les chemins de fichiers si structure modifiée
```

### Review finale

Lancer `/workflows/code-review $ARGUMENTS` avant merge.

---

## Rapport de livraison

```markdown
## Feature Livrée : $ARGUMENTS

### Artifacts BMAD
- project-context.md : ✅ Utilisé / ✅ Mis à jour
- Story : docs/stories/epic-[N]-story-[M].md ✅

### Agents utilisés
- [x] analyst — Cadrage validé
- [x] architect — ADR créé : /docs/decisions/XXX.md
- [ ] ux-expert — N/A (pas de UI)
- [ ] product-manager — PRD existant réutilisé / ✅ mis à jour
- [x] developer / frontend-specialist — Implémentation
- [x] qa-engineer — Tests (coverage: X%)
- [x] security-auditor — ✅ Aucun bloquant
- [ ] performance-engineer — N/A (pas de chemin chaud)
- [x] devops-engineer — Observabilité ajoutée

### Impact sur l'existant
- Régressions : Aucune / [liste si applicable]
- Migrations BDD : Oui ([fichier]) / Non
- Nouveaux patterns documentés : Oui / Non

### Fichiers modifiés : X
### Nouveaux tests : X | Coverage : X%
### Prêt pour merge : ✅ / ❌
```
