---
description: "Workflow BMAD Quick Flow pour les changements petits et bien compris. Remplace les phases 1-3 par une spec rapide, puis implémente directement. Idéal pour bug fixes, refactoring ciblé, petites features. Escalade automatiquement vers le Full Flow si le scope grandit."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# BMAD — Quick Flow

Changement rapide : **$ARGUMENTS**

> **Quick Flow** = 2 étapes : Quick Spec → Quick Dev
> Utiliser quand le scope est clairement défini et tient en 1-2 fichiers.
> **Si le scope grandit → escalader vers `/workflows/feature-dev`**

---

## 🔍 Pré-qualification (obligatoire)

```bash
cat docs/project-context.md 2>/dev/null | head -30
cat CLAUDE.md 2>/dev/null | head -20
```

**Critères Quick Flow (tous doivent être vrais)** :
- [ ] Scope ≤ 2 composants / services
- [ ] Comportement attendu clairement défini
- [ ] Pas de changement architectural
- [ ] Pas de nouveaux modèles BDD
- [ ] Pas de nouvelle route API publique
- [ ] Pas de dépendance externe à ajouter
- [ ] Durée estimée < 2h

**Si 3+ critères sont faux → utiliser `/workflows/feature-dev`**

---

## Étape 1 — Quick Spec (QS)

### `analyst agent` + `product-manager agent`

```bash
# Comprendre le contexte exact
cat docs/project-context.md 2>/dev/null
grep -r "$ARGUMENTS" src/ --include="*.ts" -l 2>/dev/null | head -10
```

Créer `docs/stories/quick-[date]-[slug].md` avec ce format condensé :

```markdown
# Quick Spec : [Titre court]

**Date** : [date]
**Type** : bug-fix | refactor | feature | chore
**Scope** : [fichiers concernés]

## Problème / Besoin
[1-3 phrases max — ce qui doit changer et pourquoi]

## Comportement attendu
[Description précise du résultat final]

## Acceptance Criteria
1. [Critère mesurable]
2. [Critère mesurable]

## Fichiers à toucher
- `[chemin/exact/fichier.ts]` — [ce qui change]
- `[chemin/test.ts]` — [tests à ajouter/modifier]

## Contraintes
- [Patterns à respecter tirés de project-context.md]
- [Pas de régression sur X]

## Non inclus (scope guard)
- [Ce qui est explicitement hors scope]

---
Status: ready-for-dev
```

**✅ Gate Quick Spec** : L'utilisateur confirme que la spec est correcte.

---

## Étape 2 — Quick Dev (QD)

### `developer agent` (skills: async-patterns, testing-patterns, error-handling-patterns)

```bash
cat docs/project-context.md 2>/dev/null     # Toujours charger en premier
cat docs/stories/quick-[date]-[slug].md
```

**Ordre d'implémentation** :
1. Lire et comprendre les fichiers concernés
2. Écrire les tests (TDD)
3. Implémenter le changement minimal
4. Vérifier que les tests passent
5. Vérifier qu'il n'y a pas de régression

```bash
# Tests
npx vitest run --reporter=verbose 2>/dev/null || npm test 2>/dev/null

# TypeScript
npx tsc --noEmit 2>/dev/null

# Lint
npm run lint 2>/dev/null
```

**⚠️ Scope guard** : Si pendant l'implémentation on découvre que le scope est plus large que prévu → **STOP** et escalader vers `/workflows/feature-dev`.

---

## Étape 3 — Code Review rapide (CR)

### `code-reviewer agent`

```bash
git diff HEAD --stat
cat docs/stories/quick-[date]-[slug].md
```

Vérifications minimales :
- [ ] Acceptance criteria satisfaits
- [ ] Tests ajoutés pour le nouveau comportement
- [ ] Pas de régression détectée
- [ ] Patterns de `project-context.md` respectés
- [ ] TypeScript strict (no `any`)
- [ ] Scope respecté (rien de superflu)

**Si OK** → Mettre `Status: complete` dans la quick spec.

---

## Escalade vers Full Flow

Escalader si pendant le Quick Flow on découvre :
- Impact sur plus de 2 fichiers non prévus
- Nécessité de modifier l'architecture
- Dépendances entre plusieurs features
- Impact utilisateur plus large que prévu

**Action d'escalade** :
1. Arrêter le Quick Dev
2. Convertir la Quick Spec en Epic (avec `/workflows/feature-dev` Étape 3)
3. Créer une story BMAD complète (outil `bmad-story`)

---

## Rapport Quick Flow

```markdown
# Quick Flow : $ARGUMENTS

**Durée** : X min
**Type** : [bug-fix / refactor / feature / chore]
**Fichiers modifiés** : X
**Tests ajoutés** : X

## Spec
docs/stories/quick-[date]-[slug].md → Status: complete

## Résultat
[Description en 1-2 phrases de ce qui a changé]

## Vérifications
- [x] Tests passent
- [x] TypeScript OK
- [x] Lint OK
- [x] Scope respecté
```
