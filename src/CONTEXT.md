# Contexte du Module Source

> Ce fichier fournit le contexte Tier 3 pour le dossier `src/`.
> Mettez-le à jour avec les informations spécifiques à votre implémentation.

## Organisation du code

```
src/
├── app/           # Routes Next.js (App Router)
│   ├── (auth)/    # Routes authentifiées (route group)
│   ├── api/       # API Routes
│   └── layout.tsx # Layout racine
├── components/    # Composants React réutilisables
│   ├── ui/        # Composants UI de base (Button, Input, etc.)
│   └── features/  # Composants métier
├── lib/           # Utilitaires et helpers
│   ├── hooks/     # Custom React hooks
│   ├── utils/     # Fonctions utilitaires
│   └── types/     # Types TypeScript partagés
└── server/        # Logique serveur uniquement
    ├── actions/   # Server Actions Next.js
    ├── services/  # Services métier
    └── db/        # Accès base de données (Prisma)
```

## Conventions importantes

- Les Server Components sont le défaut (pas de `'use client'` sauf si nécessaire)
- Les Client Components sont dans des fichiers suffixés `.client.tsx`
- Les Server Actions sont dans `src/server/actions/`
- Les imports utilisent l'alias `@/` → `src/`

## Règles de ce module

1. **Pas de logique métier dans les composants** — les composants appellent les services
2. **Validation en entrée** — toutes les données utilisateur passent par Zod
3. **Gestion d'erreurs explicite** — utiliser le type `Result<T, E>`
4. **Tests colocalisés** — `feature.ts` et `feature.test.ts` dans le même dossier
