---
description: "Workflow BMAD pour faire le tour complet d'un projet existant : diagnostic du codebase, génération de project-context.md (constitution du projet), mise à jour de l'architecture, création des artifacts BMAD manquants (PRD, épics, stories). À lancer en premier sur tout projet existant avant de coder."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# BMAD — Brownfield : Découverte de Projet Existant

Projet à analyser : **$ARGUMENTS**

> **Brownfield** = le projet a déjà du code, des patterns, une histoire.
> L'objectif est de le comprendre complètement et de créer tous les artifacts
> BMAD nécessaires pour travailler dessus sereinement.
>
> **Après ce workflow** → utiliser `/workflows/feature-dev` pour ajouter des features.

---

## Phase 0 — Diagnostic Initial

```bash
echo "=== BMAD Brownfield Diagnostic ==="

echo "--- Artifacts BMAD existants ---"
[ -f docs/project-context.md ]   && echo "✅ project-context.md" || echo "⬜ project-context.md (à créer)"
[ -f docs/prd.md ]                && echo "✅ prd.md"              || echo "⬜ prd.md (à créer)"
[ -f docs/architecture.md ]       && echo "✅ architecture.md"     || echo "⬜ architecture.md (à créer)"
[ -f CLAUDE.md ]                  && echo "✅ CLAUDE.md"           || echo "⬜ CLAUDE.md"
ls docs/epic-*.md 2>/dev/null     && echo "✅ Épics trouvés"       || echo "⬜ Pas d'épics"
ls docs/stories/ 2>/dev/null      && echo "✅ Stories trouvées"    || echo "⬜ Pas de stories"

echo "--- Codebase ---"
cat package.json 2>/dev/null | grep '"version"' | head -1
echo "Fichiers TypeScript : $(find src -name '*.ts' 2>/dev/null | wc -l)"
echo "Fichiers de test    : $(find src -name '*.test.ts' -o -name '*.spec.ts' 2>/dev/null | wc -l)"
echo "Coverage moyen      : $(cat coverage/coverage-summary.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['total']['lines']['pct'],'%')" 2>/dev/null || echo 'non mesuré')"
git log --oneline -10 2>/dev/null

echo "--- Stack ---"
cat package.json | grep -E '"(next|react|prisma|vitest|jest|express|fastify)"' | head -10
```

**Décision selon le diagnostic** :

| Situation | Action |
|-----------|--------|
| `project-context.md` complet et à jour | → Phase 1 allégée (vérification uniquement) |
| `project-context.md` absent ou partiel | → Phase 1 complète (génération) |
| `architecture.md` absent | → Phase 2 complète |
| Pas d'épics ni de PRD | → Phase 3 + 4 complètes |

---

## Phase 1 — Génération de `docs/project-context.md`

> **Constitution du projet** — Ce fichier est la référence pour tout développement futur.
> Chaque développeur (humain ou IA) doit le lire en premier.

### `architect agent` + `developer agent` en parallèle

#### 1A — Analyser le code réel

```bash
# Stack et dépendances exactes
cat package.json | python3 -c "
import json, sys
d = json.load(sys.stdin)
print('=== Dependencies ===')
for k,v in d.get('dependencies', {}).items(): print(f'  {k}: {v}')
print('=== DevDependencies ===')
for k,v in d.get('devDependencies', {}).items(): print(f'  {k}: {v}')
"

# Configuration TypeScript
cat tsconfig.json 2>/dev/null

# Structure des dossiers
find src -type d | head -30

# Patterns de code existants — Services
find src -name "*.service.ts" | head -3 | xargs cat 2>/dev/null | head -100

# Patterns de code existants — Tests
find src -name "*.test.ts" | head -2 | xargs cat 2>/dev/null | head -80

# Auth
grep -r "getServerSession\|auth()\|useSession\|middleware" src/ --include="*.ts" -l 2>/dev/null | head -5 | xargs cat 2>/dev/null | head -60

# Error handling
grep -r "Result\|AppError\|throw new\|ZodError" src/ --include="*.ts" -l 2>/dev/null | head -3 | xargs cat 2>/dev/null | head -60

# Schéma BDD
cat prisma/schema.prisma 2>/dev/null

# Variables d'environnement
cat .env.example 2>/dev/null || grep -r "process\.env\." src/ --include="*.ts" | sed 's/.*process\.env\.\([A-Z_]*\).*/\1/' | sort -u | head -20
```

#### 1B — Créer `docs/project-context.md`

```markdown
# Project Context — [Nom du projet]
> Généré le [date] via /workflows/bmad-brownfield
> **Ce fichier est la constitution du projet. Le lire en premier avant tout développement.**

## Technology Stack & Versions
- Runtime : Node.js [version]
- Framework : [Next.js XX / Express / etc.]
- Language : TypeScript [version] (strict: [oui/non])
- Base de données : [PostgreSQL / SQLite / etc.] via [Prisma / Drizzle / etc.]
- Tests : [Vitest / Jest] + [Testing Library / Supertest]
- Style : [Tailwind CSS / CSS Modules / etc.]

## Structure du projet
```
src/
├── app/          # [Routes / Controllers]
├── components/   # [Composants UI]
├── lib/          # [Utilitaires]
├── server/       # [Logique serveur]
└── ...
```

## Critical Implementation Rules

### TypeScript
- any interdit : [oui/non] — utiliser `unknown` + type guards
- Conventions : [camelCase / PascalCase pour composants]
- Imports : [alias @/ / chemins relatifs]

### Patterns Obligatoires
- Error handling : [Result type / throw AppError / ZodError]
  ```ts
  // Exemple du pattern utilisé dans le projet
  ```
- Auth : [Comment vérifier les permissions — exemple de code]
- DB access : [Direct Prisma / Repository pattern / Service layer]
- Async : [async/await partout / callbacks tolérés]

### Organisation des fichiers
- Composants React → `src/components/[feature]/[Component].tsx`
- Server Actions → `src/server/actions/[feature].ts`
- Services → `src/server/services/[feature].service.ts`
- Tests → co-localisés avec le code (`[nom].test.ts`)

### Variables d'environnement
| Variable | Utilisation | Requis |
|----------|-------------|--------|
| DATABASE_URL | Connexion BDD | ✅ |
| [autres] | [...] | [...] |

### Ce qu'il NE FAUT PAS faire
- [Anti-pattern 1 observé dans le code]
- [Anti-pattern 2]
- [Pièges identifiés lors de l'analyse]

## Commandes utiles
```bash
npm run dev        # Démarrer en développement
npm test           # Lancer les tests
npm run type-check # Vérifier les types TypeScript
npm run lint       # Lint
npm run db:migrate # Migrations BDD
```
```

---

## Phase 2 — Architecture

### `architect agent` (skills: api-design, database-patterns, architecture-diagrams, auth-patterns)

#### 2A — Cartographier l'architecture réelle

```bash
# Routes API
find src -name "route.ts" -o -name "*.controller.ts" 2>/dev/null | head -15 | xargs head -20 2>/dev/null

# Modèles de données
cat prisma/schema.prisma 2>/dev/null | grep "^model" | head -20

# Middleware et auth
find src -name "middleware*" 2>/dev/null | xargs cat 2>/dev/null | head -60

# Commits récents (évolution du code)
git log --oneline --since="60 days ago" | head -20
```

#### 2B — Créer ou mettre à jour `docs/architecture.md`

```markdown
# Architecture — [Nom du projet]
> Mis à jour le [date] via /workflows/bmad-brownfield

## Vue d'ensemble
[Diagramme Mermaid C4 ou flowchart du système]

## Modèles de données
[Diagramme ER Mermaid]

## API Endpoints
| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| GET | /api/... | ✅ | ... |

## Flux d'authentification
[Description du mécanisme auth]

## Décisions techniques connues
[Liste des ADRs identifiés dans le code]
```

Si l'architecture a évolué depuis le dernier `architecture.md`, identifier et documenter les divergences.

---

## Phase 3 — PRD et Épics

### `analyst agent` + `product-manager agent`

#### 3A — Comprendre le produit actuel

```bash
# Commits pour comprendre l'histoire du produit
git log --oneline | head -50

# README
cat README.md 2>/dev/null | head -60

# PRD existant ?
cat docs/prd.md 2>/dev/null | head -60
```

Répondre à :
- Quel problème ce projet résout-il ?
- Qui sont les utilisateurs ?
- Quelles features sont déjà livrées ?
- Quelles features sont planifiées ?

#### 3B — Créer ou mettre à jour `docs/prd.md`

Si pas de PRD → créer selon `docs/bmad/templates/prd-tmpl.md`.
Si PRD existant → vérifier sa cohérence avec le code actuel et mettre à jour.

#### 3C — Cartographier les épics existants

```bash
ls docs/epic-*.md 2>/dev/null | xargs grep -h "^# \|## Titre\|## Status" 2>/dev/null
```

Créer les épics manquants si le PRD identifie des groupes de fonctionnalités non encore épisés.

---

## Phase 4 — Stories existantes

### `scrum-master agent` (skills: architecture-diagrams)

#### 4A — Analyser le backlog actuel

```bash
ls docs/stories/ 2>/dev/null | head -30
# Pour chaque story trouvée, lire le statut
grep -l "Status: Complete\|status: done" docs/stories/*.md 2>/dev/null | wc -l
grep -l "Status: In Progress\|status: in-progress" docs/stories/*.md 2>/dev/null
grep -l "Status: Draft\|status: draft" docs/stories/*.md 2>/dev/null
```

#### 4B — Créer les stories manquantes pour les features connues

Pour chaque feature identifiée dans le PRD mais sans story → créer via `/tools/bmad-story`.

---

## Rapport de découverte

```markdown
# Rapport Brownfield — [Nom du projet]
> Généré le [date]

## État des artifacts BMAD

| Artifact | Statut | Action |
|----------|--------|--------|
| `project-context.md` | ✅ Créé / ✅ Mis à jour / ⬜ N/A | — |
| `architecture.md` | ✅ Créé / ✅ Mis à jour | — |
| `prd.md` | ✅ Créé / ✅ Existant et à jour | — |
| Épics | X créés / Y existants | — |
| Stories | X créées / Y existantes | — |

## État du codebase

- Fichiers TypeScript : X
- Couverture de tests : X%
- Dernière activité : [date du dernier commit]
- Erreurs TypeScript connues : [oui/non]

## Observations importantes

### Points forts
- [Ce qui est bien fait dans le code]

### Risques identifiés
- [Technical debt, patterns incohérents, zones fragiles]

### Pièges à éviter
- [Anti-patterns observés, zones dangereuses]

## Recommandations

### Prochaine étape suggérée
- Pour ajouter une feature → `/workflows/feature-dev [nom-feature]`
- Pour un petit fix → `/workflows/bmad-quick [description]`
- Pour un audit complet → `/workflows/security-audit` ou `/workflows/full-context`

### Stories prioritaires identifiées
1. [Story 1 — priorité haute]
2. [Story 2 — priorité moyenne]
```
