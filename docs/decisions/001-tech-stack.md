# ADR-001 : Choix du Stack Technique

## Statut : Accepté

## Contexte

Nous devons choisir le stack technique pour ce projet. La décision doit prendre en compte la productivité de l'équipe, la performance, la maintenabilité et l'écosystème disponible.

## Options considérées

### Option A : Next.js + TypeScript + Prisma + PostgreSQL ✅

**Avantages** :
- TypeScript strict = moins de bugs runtime
- Next.js App Router = SSR/RSC out of the box
- Prisma = ORM typé, migrations automatiques
- PostgreSQL = base relationnelle éprouvée
- Écosystème npm mature

**Inconvénients** :
- Courbe d'apprentissage React Server Components
- PostgreSQL nécessite une infra dédiée

### Option B : Express.js + JavaScript + Sequelize + MySQL

**Avantages** :
- Stack simple et bien connu
- MySQL très répandu

**Inconvénients** :
- Pas de types → plus de bugs runtime
- Sequelize moins ergonomique que Prisma
- Pas de SSR natif

## Décision

**Option A retenue** : Next.js + TypeScript + Prisma + PostgreSQL.

La sécurité des types TypeScript, combinée à Prisma (ORM typé) et Next.js (SSR/performance), offre le meilleur rapport productivité/qualité.

## Conséquences

### Positives
- Moins de bugs grâce à TypeScript strict
- DX excellente avec Prisma Studio et les migrations
- SEO et performance avec Next.js App Router
- Un seul langage front + back (TypeScript)

### Négatives
- PostgreSQL nécessite un service managé en production (Supabase, Neon, Railway)
- Temps d'apprentissage React Server Components pour les nouveaux développeurs

## Date de décision

2024-01-01
