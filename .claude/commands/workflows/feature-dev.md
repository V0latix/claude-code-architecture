---
description: "Développement end-to-end d'une feature. Orchestre le cycle complet : specs → architecture → implémentation → tests → review → docs."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Feature Development End-to-End

Développement complet de la feature : **$ARGUMENTS**

## Phase 1 — Spécification (product-manager agent)

1. Rédiger le PRD de `$ARGUMENTS` :
   - Contexte et problème à résoudre
   - Exigences fonctionnelles (Must/Should/Could)
   - Critères d'acceptation (Given/When/Then)
   - Métriques de succès
   - Hors périmètre

2. Créer les user stories avec le scrum-master agent

## Phase 2 — Architecture (architect agent)

1. Analyser l'impact sur l'architecture existante
2. Proposer le design technique détaillé
3. Identifier les dépendances et risques
4. Créer un ADR si décision significative

## Phase 3 — Implémentation (developer agent)

Suivre cet ordre :
1. **Tests d'abord** : Écrire les tests selon les critères d'acceptation
2. **Implémentation** : Code minimal qui fait passer les tests
3. **Refactoring** : Nettoyer sans casser les tests
4. **Types** : S'assurer que TypeScript strict passe

Commandes à exécuter :
```bash
npm run type-check  # Vérifier les types
npm test            # Lancer les tests
npm run lint        # Vérifier le style
```

## Phase 4 — Qualité (qa-engineer + security-auditor agents)

1. Review de la couverture de tests
2. Audit de sécurité de la feature
3. Vérification des critères d'acceptation

## Phase 5 — Documentation (doc-writer agent)

1. Mettre à jour le README si nécessaire
2. Documenter les nouvelles APIs
3. Mettre à jour le CHANGELOG

## Phase 6 — Synthèse

Produire un résumé de livraison :
```markdown
## Feature Livrée : $ARGUMENTS

### Ce qui a été implémenté
- ...

### Fichiers modifiés
- ...

### Tests ajoutés
- Coverage : X%
- Nouveaux tests : X

### Points d'attention
- ...

### Prêt pour merge : ✅ / ❌
```
