---
description: "Vérification orientée-objectif d'une feature ou story : vérifie que le code livré tient réellement ses promesses (vérités observables, artefacts substantiels, câblage des composants). Inspiré du goal-backward verification de get-shit-done. Différent de verification-before-completion qui vérifie les tests."
allowed-tools: Bash, Read, Write, Grep, Glob, Task
---

# Verify Goal

Vérification orientée-objectif pour : **$ARGUMENTS**

## Concept

> La question n'est pas "les tests passent-ils ?" mais "la feature tient-elle ses promesses ?"

Ce workflow vérifie trois dimensions orthogonales aux tests unitaires :
1. **Vérités observables** — Les comportements promis sont-ils réellement accessibles ?
2. **Artefacts requis** — Les implémentations sont-elles substantielles (pas de stubs) ?
3. **Câblage des composants** — Les pièces sont-elles connectées (pas orphelines) ?

---

## Phase 1 — Lire les promesses

Avant de vérifier, comprendre ce qui était promis :

```bash
# Story / ticket associé
cat docs/stories/*$ARGUMENTS* 2>/dev/null || true
cat docs/plans/*$ARGUMENTS* 2>/dev/null || true

# Commits liés à la feature
git log --oneline --grep="$ARGUMENTS" -20 2>/dev/null || true

# Fichiers créés/modifiés pour cette feature
git diff --stat HEAD~10 HEAD 2>/dev/null | head -30 || true
```

Identifier :
- Les comportements promis (user stories, acceptance criteria)
- Les fichiers créés ou modifiés
- Les APIs/endpoints/composants censés exister

---

## Phase 2 — Vérifications en parallèle

Lancer les trois vérifications simultanément via Task :

### Vérification A : Vérités observables (use developer agent)

Pour chaque comportement promis :
```bash
# Vérifier que les endpoints/fonctions existent et retournent quelque chose
# Pas juste que le fichier existe — vérifier le contenu réel

grep -r "export.*function\|export default\|module.exports" src/ --include="*.ts" | head -20

# Vérifier que les routes sont enregistrées
grep -r "app\.\(get\|post\|put\|delete\|use\)\|router\." src/ --include="*.ts" | head -20

# Vérifier que les composants sont importés et utilisés
grep -r "import.*from\|require(" src/app --include="*.tsx" | head -20
```

Pour chaque comportement promis :
- [ ] Est-il techniquement possible pour un utilisateur d'atteindre ce comportement ?
- [ ] Existe-t-il un chemin d'exécution qui l'active ?

### Vérification B : Artefacts requis (use qa-engineer agent)

Détecter les implémentations creuses :

```bash
# Stubs et TODO dans les chemins critiques
grep -rn "TODO\|FIXME\|throw new Error.*not implemented\|return null.*TODO\|placeholder\|stub" \
  src/ --include="*.ts" --include="*.tsx" | grep -v "\.test\." | head -20

# Fonctions vides ou avec return trivial
grep -rn "^\s*}\s*$\|return {}\|return \[\]\|return null\|return undefined" \
  src/ --include="*.ts" | grep -v "\.test\." | head -20

# Fichiers créés mais quasi-vides (< 10 lignes)
find src/ -name "*.ts" -not -name "*.test.ts" -newer package.json 2>/dev/null | \
  while read f; do lines=$(wc -l < "$f"); [ "$lines" -lt 10 ] && echo "$f ($lines lignes)"; done
```

Pour chaque artefact requis :
- [ ] Le fichier existe avec une implémentation substantielle (> 10 lignes, pas de stubs)
- [ ] Aucun TODO dans les chemins fonctionnels critiques

### Vérification C : Câblage des composants (use developer agent)

Vérifier que les pièces sont connectées :

```bash
# Imports manquants (fichiers référencés mais pas importés)
grep -rn "from '@/\|from '\.\." src/ --include="*.ts" --include="*.tsx" | \
  awk -F"'" '{print $2}' | sort -u | head -20

# Vérifier que les nouvelles routes sont dans le routeur principal
grep -rn "import.*Router\|app\.use\|export.*route" src/ --include="*.ts" | head -20

# Event handlers non enregistrés
grep -rn "addEventListener\|on(" src/ --include="*.ts" | head -10

# Composants créés mais pas utilisés
find src/components -name "*.tsx" | while read f; do
  name=$(basename "$f" .tsx)
  used=$(grep -r "import.*$name\|<$name" src/app src/pages 2>/dev/null | wc -l)
  [ "$used" -eq 0 ] && echo "⚠️ Composant orphelin: $name"
done
```

Pour chaque connexion attendue :
- [ ] Les imports sont résolus (pas de références brisées)
- [ ] Les routes/handlers sont enregistrés dans le fichier principal
- [ ] Les composants créés sont utilisés quelque part

---

## Phase 3 — Rapport de verdict

Compiler les résultats des 3 vérifications :

```markdown
## Rapport Verify-Goal : [FEATURE]
Date : [DATE]

### Verdict global : ✅ LIVRÉ / ❌ INCOMPLET / ⚠️ PARTIEL

---

### A. Vérités observables

| Comportement promis | Statut | Détail |
|---------------------|--------|--------|
| [comportement 1] | ✅/❌ | [chemin d'exécution ou problème] |
| [comportement 2] | ✅/❌ | [chemin d'exécution ou problème] |

### B. Artefacts requis

| Artefact | Statut | Détail |
|----------|--------|--------|
| [fichier/module] | ✅/❌ | [lignes, stubs trouvés] |

### C. Câblage

| Connexion | Statut | Détail |
|-----------|--------|--------|
| [composant → routeur] | ✅/❌ | [ligne d'import ou absence] |

---

### Issues trouvées

**Critiques (bloquent la livraison) :**
- [issue 1]

**Importants (à corriger avant merge) :**
- [issue 2]

### Prochaines actions

- [ ] [action corrective 1]
- [ ] [action corrective 2]
```

---

## Quand ce workflow est suffisant vs. insuffisant

**Suffisant pour valider :**
- Une feature complète après execute-plan
- Une story BMAD avant de la marquer done
- Un refactoring qui devait préserver des comportements

**Ne remplace PAS :**
- `verification-before-completion` (tests, TypeScript, lint)
- `workflows/code-review` (qualité du code, sécurité, performance)
- Tests manuels par un utilisateur réel

**Utiliser ensemble :**
```
verification-before-completion → tests passent ✅
verify-goal → feature tient ses promesses ✅
code-review → code de qualité ✅
→ Prêt pour merge
```
