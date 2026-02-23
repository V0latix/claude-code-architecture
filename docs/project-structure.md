# Structure du Projet

## Vue d'ensemble

```
project/
├── CLAUDE.md                          # Contexte projet permanent (chargé à chaque session)
├── .mcp.json                          # Configuration MCP servers
├── .claude/
│   ├── settings.json                  # Hooks et permissions
│   ├── agents/                        # Subagents spécialisés (11 agents)
│   ├── skills/                        # Paquets de connaissances modulaires (7 skills)
│   ├── commands/
│   │   ├── workflows/                 # Workflows multi-agents (5 workflows)
│   │   └── tools/                     # Outils utilitaires (5 tools)
│   └── hooks/
│       ├── scripts/                   # Scripts d'automatisation
│       └── config/                    # Configuration des hooks
├── docs/                              # Documentation
│   ├── project-structure.md           # Ce fichier
│   ├── architecture.md               # Architecture technique
│   ├── api-reference.md              # Référence API
│   └── decisions/                    # Architecture Decision Records
└── src/                              # Code source
    └── CONTEXT.md                    # Contexte module (Tier 3)
```

## Agents disponibles

| Agent | Modèle | Rôle |
|-------|--------|------|
| `analyst` | Sonnet | Brainstorming, recherche, briefs |
| `architect` | Opus | Design système, ADR, choix tech |
| `developer` | Opus | Implémentation, debugging |
| `qa-engineer` | Sonnet | Tests, qualité, performance |
| `security-auditor` | Opus | Audit sécurité, SAST |
| `devops-engineer` | Sonnet | CI/CD, Docker, K8s |
| `code-reviewer` | Opus | Review multi-critères |
| `product-manager` | Sonnet | PRD, spécifications |
| `scrum-master` | Haiku | Stories, agile |
| `ux-expert` | Sonnet | UI/UX, wireframes |
| `doc-writer` | Haiku | Documentation technique |

## Skills disponibles

| Skill | Cas d'usage |
|-------|-------------|
| `async-patterns` | Code asynchrone TypeScript/Node.js |
| `testing-patterns` | Écriture de tests (Vitest, Playwright) |
| `api-design` | Design d'API REST/GraphQL |
| `security-scanning` | Sécurité applicative, OWASP |
| `docker-k8s` | Containerisation et orchestration |
| `database-patterns` | Schémas Prisma, requêtes optimisées |
| `prompt-engineering` | Prompts LLM, agents IA |

## Commandes disponibles

### Workflows
- `/workflows/full-context` — Analyse multi-agents complète
- `/workflows/code-review` — Review par 4+ agents en parallèle
- `/workflows/feature-dev` — Développement E2E d'une feature
- `/workflows/security-audit` — Audit sécurité complet
- `/workflows/refactor` — Refactoring intelligent

### Tools
- `/tools/create-docs` — Génération de documentation
- `/tools/update-docs` — Synchronisation docs/code
- `/tools/scaffold` — Scaffolding de composants/modules
- `/tools/git-status` — Git status enrichi
- `/tools/test-gen` — Génération automatique de tests
