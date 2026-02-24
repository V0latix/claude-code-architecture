---
name: git-worktrees
description: "Gestion des git worktrees pour isoler les features en développement : création, baseline de tests, navigation entre worktrees, nettoyage. Activer pour les features longues (> 1 jour), l'expérimentation risquée ou la review de PR en parallèle."
license: MIT
---

# Git Worktrees

## Quand utiliser cette skill

- Feature longue (> 1 jour) à développer sans polluer `main`
- Expérimentation risquée (refactoring profond, changement d'architecture)
- Review d'un PR en parallèle du travail en cours
- Comparaison de deux approches différentes en simultané

---

## Concepts fondamentaux

Un **git worktree** est un répertoire de travail supplémentaire lié au même dépôt git. Contrairement à `git stash` ou aux branches, chaque worktree a son propre working directory et peut être sur une branche différente simultanément.

```
monrepo/                    ← worktree principal (branch: main)
.worktrees/
  feature-auth/            ← worktree 2 (branch: feat/auth)
  refactor-db/             ← worktree 3 (branch: refactor/database)
```

---

## Setup initial

### 1. Vérifier le .gitignore

```bash
# Toujours vérifier avant de créer des worktrees
grep ".worktrees" .gitignore
# Si absent :
echo ".worktrees/" >> .gitignore
git add .gitignore && git commit -m "chore: ignore .worktrees directory"
```

### 2. Créer un worktree

```bash
# Syntaxe : git worktree add <chemin> -b <branche>
git worktree add .worktrees/feature-auth -b feat/feature-auth

# Si la branche existe déjà :
git worktree add .worktrees/feature-auth feat/feature-auth

# Depuis une base différente de HEAD :
git worktree add .worktrees/hotfix-payment -b hotfix/payment origin/main
```

### 3. Établir la baseline de tests

**Toujours faire avant de commencer à coder.**

```bash
cd .worktrees/feature-auth

# Installer les dépendances si nécessaire
npm install

# Lancer les tests et sauvegarder la baseline
npm test 2>&1 | tee test-baseline.txt

# Vérifier que la baseline est propre
grep "failed" test-baseline.txt && echo "⚠️ Tests échouent déjà sur main" || echo "✅ Baseline propre"
```

---

## Workflow quotidien

### Naviguer entre worktrees

```bash
# Lister tous les worktrees
git worktree list
# worktree /Users/dev/monrepo  abc1234 [main]
# worktree /Users/dev/monrepo/.worktrees/feature-auth  def5678 [feat/feature-auth]

# Aller dans un worktree
cd .worktrees/feature-auth

# Revenir au worktree principal
cd ../..   # ou utiliser le chemin absolu
```

### Synchroniser avec main

```bash
# Dans le worktree feature
git fetch origin
git rebase origin/main   # préféré à merge pour garder un historique propre
# Résoudre les conflits si nécessaire
npm test   # vérifier que la baseline est toujours propre après rebase
```

### Commits dans un worktree

Les commits dans un worktree s'appliquent à la branche du worktree, indépendamment du worktree principal.

```bash
# Dans .worktrees/feature-auth
git add src/lib/auth.ts src/lib/auth.test.ts
git commit -m "feat: add JWT token validation"

# Le worktree principal (main) n'est pas affecté
```

---

## Nettoyage

### Après merge ou abandon

```bash
# 1. Sortir du worktree (si on y est)
cd /chemin/vers/repo/principal

# 2. Supprimer le worktree
git worktree remove .worktrees/feature-auth

# 3. Supprimer la branche (si mergée)
git branch -d feat/feature-auth

# 4. Nettoyer les références orphelines
git worktree prune
```

### En cas de worktree corrompu

```bash
# Forcer la suppression
git worktree remove --force .worktrees/feature-auth

# Nettoyage manuel si nécessaire
rm -rf .worktrees/feature-auth
git worktree prune
```

---

## Commandes de référence

```bash
# Créer
git worktree add .worktrees/<nom> -b <branche>

# Lister
git worktree list

# Supprimer
git worktree remove .worktrees/<nom>

# Nettoyer les références
git worktree prune

# Déplacer un worktree
git worktree move .worktrees/ancien-nom .worktrees/nouveau-nom

# Verrouiller (empêcher suppression accidentelle)
git worktree lock .worktrees/<nom>
git worktree unlock .worktrees/<nom>
```

---

## Patterns avancés

### Review de PR en parallèle

```bash
# Worktree dédié pour la review
git worktree add .worktrees/review-pr-123 origin/feat/some-feature

cd .worktrees/review-pr-123
npm install && npm test   # vérifier que la PR passe les tests

# Revenir au travail en cours sans stash
cd ../..  # worktree principal inchangé
```

### Comparaison de deux approches

```bash
git worktree add .worktrees/approach-a -b experiment/approach-a
git worktree add .worktrees/approach-b -b experiment/approach-b

# Implémenter A dans le premier, B dans le second
# Comparer les benchmarks :
cd .worktrees/approach-a && npm run bench
cd ../approach-b && npm run bench
```

---

## Anti-patterns

```bash
# ❌ Créer des worktrees dans un dossier suivi par git
git worktree add src/worktrees/feature -b feat/feature   # pollue le repo

# ✅ Toujours dans .worktrees/ (hors du suivi git)
git worktree add .worktrees/feature -b feat/feature

# ❌ Oublier d'établir la baseline
# → impossible de savoir si les échecs viennent du code ou de l'état initial

# ❌ Laisser des worktrees orphelins
git worktree list   # vérifier régulièrement et nettoyer

# ❌ La même branche dans deux worktrees
# → git interdira la checkout de la même branche dans deux worktrees simultanément
```
