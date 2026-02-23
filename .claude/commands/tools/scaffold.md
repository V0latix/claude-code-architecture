---
description: "Génère le scaffolding d'un composant, module, feature ou service. Crée la structure de fichiers complète avec tests, types et exports."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Scaffold

Génération du scaffolding pour : **$ARGUMENTS**

## Instructions

Analyser d'abord la structure du projet pour respecter les conventions :

```bash
# Comprendre la structure existante
ls src/components/ 2>/dev/null | head -10
ls src/lib/ 2>/dev/null | head -10
ls src/server/ 2>/dev/null | head -10
cat CLAUDE.md | grep -A20 "Architecture"
```

## Types de scaffolding

### Si `$ARGUMENTS` contient "component" :

Créer dans `src/components/[nom]/` :
- `[nom].tsx` — Composant React avec TypeScript
- `[nom].test.tsx` — Tests avec Testing Library
- `[nom].stories.tsx` — Storybook (si présent dans le projet)
- `index.ts` — Export barrel

```typescript
// Template composant
interface [Nom]Props {
  // props typées
}

export const [Nom] = ({ }: [Nom]Props) => {
  return (
    <div>
      {/* ... */}
    </div>
  )
}
```

### Si `$ARGUMENTS` contient "service" :

Créer dans `src/server/[nom]/` :
- `[nom].service.ts` — Logique métier
- `[nom].repository.ts` — Accès aux données
- `[nom].types.ts` — Types et interfaces
- `[nom].test.ts` — Tests unitaires
- `index.ts` — Export barrel

### Si `$ARGUMENTS` contient "api" ou "route" :

Créer dans `src/app/api/[nom]/` :
- `route.ts` — Handler Next.js
- `route.test.ts` — Tests d'intégration
- Types dans `[nom].types.ts`

### Si `$ARGUMENTS` contient "hook" :

Créer dans `src/lib/hooks/` :
- `use[Nom].ts` — Hook React
- `use[Nom].test.ts` — Tests avec renderHook

## Après la génération

Afficher la liste des fichiers créés et rappeler les prochaines étapes :
1. Implémenter la logique métier
2. Compléter les tests
3. Mettre à jour les exports du module parent
