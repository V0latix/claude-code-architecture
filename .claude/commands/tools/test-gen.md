---
description: "Génère automatiquement des tests unitaires et d'intégration pour le code spécifié. Analyse le code, identifie les cas de test et produit des tests prêts à l'emploi."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Test Generation

Génération de tests pour : **$ARGUMENTS**

## Instructions

Utilise le `qa-engineer` agent pour analyser le code et générer des tests complets.

### 1. Analyser le code cible

```bash
cat $ARGUMENTS
```

Identifier :
- Toutes les fonctions/méthodes exportées
- Les types d'entrées et sorties
- Les cas d'erreur possibles
- Les effets de bord (I/O, BDD, réseau)

### 2. Générer les tests

#### Pour chaque fonction, créer des tests pour :

**Cas nominaux (happy path)**
- Entrées valides standard
- Différentes combinaisons de paramètres valides

**Cas limites (edge cases)**
- Valeurs null/undefined
- Chaînes vides
- Nombres négatifs, zéro, très grands nombres
- Tableaux vides ou avec un seul élément
- Dates limites

**Cas d'erreur**
- Entrées invalides
- Erreurs réseau/BDD simulées
- Timeouts

**Cas de sécurité**
- Injection dans les paramètres string
- Valeurs extrêmes

### 3. Structure des tests générés

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { [fonction] } from './$ARGUMENTS'

// Builders si nécessaire
const build[Type] = (overrides = {}) => ({
  // ...
  ...overrides,
})

describe('[NomModule]', () => {
  describe('[nomFonction]', () => {
    it('should [comportement] when [condition]', async () => {
      // Arrange
      // Act
      // Assert
    })
  })
})
```

### 4. Fichier de sortie

Créer le fichier de test à côté du fichier source :
- `src/lib/utils.ts` → `src/lib/utils.test.ts`
- `src/server/user.service.ts` → `src/server/user.service.test.ts`

### 5. Vérification

```bash
# Lancer les nouveaux tests
npx vitest run $ARGUMENTS.test.ts

# Vérifier la couverture
npx vitest run --coverage $ARGUMENTS
```
