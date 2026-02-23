# Projet : [NOM DU PROJET]

## Stack technique

- Language : TypeScript strict
- Framework : Next.js 15 App Router
- Base de données : PostgreSQL + Prisma ORM
- Tests : Vitest + Testing Library
- Style : Tailwind CSS + Prettier + ESLint flat config

## Conventions de code

- Pas de `any` TypeScript
- Composants fonctionnels uniquement
- Noms de fichiers en kebab-case
- Imports absolus avec alias `@/`
- Commits en format conventionnel (feat, fix, chore, docs, refactor, test)

## Architecture des dossiers

- `/src/app` → Routes Next.js (App Router)
- `/src/components` → Composants réutilisables
- `/src/lib` → Utilitaires et helpers
- `/src/server` → Logique serveur (actions, API)
- `/prisma` → Schéma et migrations BDD
- `/docs` → Documentation projet
- `/docs/decisions` → Architecture Decision Records (ADR)

## Routing des agents

| Tâche | Agent à utiliser |
|-------|-----------------|
| Brainstorming, recherche, briefs | `use analyst agent` |
| Design système, choix tech, ADR | `use architect agent` |
| Implémentation, debugging, refactoring | `use developer agent` |
| Tests, qualité, performance | `use qa-engineer agent` |
| Audit sécurité, SAST, compliance | `use security-auditor agent` |
| CI/CD, Docker, Kubernetes, infra | `use devops-engineer agent` |
| Code review multi-critères | `use code-reviewer agent` |
| PRD, spécifications, roadmap | `use product-manager agent` |
| Stories, sprints, agile | `use scrum-master agent` |
| UI/UX, wireframes, design | `use ux-expert agent` |
| Documentation technique | `use doc-writer agent` |

## Commandes disponibles

### Workflows

- `/workflows/full-context` — Analyse multi-agents complète d'une feature
- `/workflows/code-review` — Review parallèle par 4+ agents spécialisés
- `/workflows/feature-dev` — Développement feature end-to-end
- `/workflows/security-audit` — Audit sécurité complet
- `/workflows/refactor` — Refactoring intelligent avec tests

### Tools

- `/tools/create-docs` — Génération documentation projet
- `/tools/update-docs` — Synchronisation docs/code
- `/tools/scaffold` — Scaffolding de composants/modules
- `/tools/git-status` — Git status enrichi avec suggestions
- `/tools/test-gen` — Génération automatique de tests

## Règles importantes

- Toujours écrire des tests avant d'implémenter (TDD)
- Ne jamais modifier `.env`, `.env.*` ou `package-lock.json`
- Utiliser les conventions de commit conventionnel
- Documenter les décisions d'architecture dans `/docs/decisions/` (ADR)
- Ne pas utiliser `any` en TypeScript — préférer `unknown` + type guards
- Chaque PR doit inclure des tests
- Toujours vérifier la sécurité avant de merger (use security-auditor agent)
