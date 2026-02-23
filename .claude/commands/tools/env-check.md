---
description: "Scanne le codebase pour recenser toutes les variables d'environnement utilisées, détecte les manquantes ou non documentées, et génère un .env.example à jour."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Env Check

Vérification des variables d'environnement pour : **$ARGUMENTS**

## Instructions

### 1. Recenser toutes les variables utilisées dans le code

```bash
# Variables process.env dans TypeScript/JavaScript
grep -r "process\.env\." --include="*.ts" --include="*.tsx" --include="*.js" \
  -h --no-filename | grep -oE 'process\.env\.[A-Z_]+' | sort -u

# Variables via next.config (NEXT_PUBLIC_*)
grep -r "NEXT_PUBLIC_" --include="*.ts" --include="*.tsx" --include="*.js" \
  -h --no-filename | grep -oE 'NEXT_PUBLIC_[A-Z_]+' | sort -u

# Variables via t3-env ou @t3-oss/env-nextjs si présent
grep -r "createEnv\|z\.string" --include="*.ts" -l 2>/dev/null | head -5
```

### 2. Comparer avec la documentation existante

```bash
# Variables dans .env.example
cat .env.example 2>/dev/null || echo "⚠️ Pas de .env.example"

# Variables dans .env.local (si présent et non sensible)
cat .env.local 2>/dev/null | grep -v "^#" | grep "=" | cut -d= -f1 | sort

# Variables documentées dans CLAUDE.md ou README
grep -E "[A-Z_]{3,}=" README.md CLAUDE.md 2>/dev/null | head -20
```

### 3. Identifier les divergences

Utiliser le `developer agent` pour croiser les données et identifier :
- Variables utilisées dans le code **mais absentes** de `.env.example` → à documenter
- Variables dans `.env.example` **mais plus utilisées** dans le code → à supprimer
- Variables sans valeur par défaut dans un contexte de test → risque CI/CD
- Variables `NEXT_PUBLIC_*` exposées côté client → vérifier si données sensibles

### 4. Générer / mettre à jour `.env.example`

Format cible pour `.env.example` :

```bash
# ============================================================
# APPLICATION
# ============================================================

# URL publique de l'application
APP_URL=http://localhost:3000

# ============================================================
# BASE DE DONNÉES
# ============================================================

# PostgreSQL — format : postgresql://user:password@host:port/dbname
DATABASE_URL=postgresql://postgres:password@localhost:5432/mydb

# ============================================================
# AUTHENTIFICATION
# ============================================================

# Secret NextAuth (générer avec: openssl rand -base64 32)
NEXTAUTH_SECRET=
NEXTAUTH_URL=http://localhost:3000

# ============================================================
# SERVICES EXTERNES
# ============================================================

# Stripe (optionnel)
# STRIPE_SECRET_KEY=sk_test_...
# NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...

# ============================================================
# FEATURE FLAGS (optionnel)
# ============================================================

# ENABLE_ANALYTICS=false
```

### 5. Rapport de sortie

```markdown
## Rapport env-check

### Variables détectées dans le code : X
### Variables dans .env.example : Y

### ➕ Manquantes dans .env.example
- `VARIABLE_NAME` — utilisée dans `src/lib/xxx.ts`

### ➖ Obsolètes dans .env.example (plus utilisées)
- `OLD_VARIABLE` — peut être supprimée

### ⚠️ Points d'attention sécurité
- `SECRET_KEY` exposée côté client via NEXT_PUBLIC_ ?
- Variables sans valeur de fallback dans les tests

### ✅ .env.example mis à jour
```

### 6. Vérification finale

```bash
# Confirmer que .env.example ne contient pas de vraies valeurs sensibles
grep -E "(password|secret|key|token)" .env.example -i | grep -v "^#" | grep -v "=$"
```
