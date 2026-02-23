---
description: "Audit de performance complet. Profiling applicatif, analyse des requêtes DB, benchmarks before/after, identification des goulots d'étranglement, et plan d'optimisation priorisé par ROI."
allowed-tools: Bash, Read, Grep, Glob, Task
---

# Performance Audit Complet

Audit de performance de : **$ARGUMENTS**

Si `$ARGUMENTS` est vide → auditer l'ensemble du projet.
Sinon → focaliser sur le module/endpoint spécifié.

## Étape 1 — Baseline metrics

```bash
# Vérifier l'état des tests avant tout
npm test -- --silent 2>&1 | tail -5

# Identifier les endpoints/fonctions critiques
grep -r "export.*async\|router\.\|app\.\(get\|post\|put\)" \
  --include="*.ts" -l | grep -v node_modules | head -20

# Détecter les await en boucle (anti-pattern fréquent)
grep -rn "for.*await\|while.*await\|\.forEach.*async" \
  --include="*.ts" | grep -v node_modules | grep -v "// ok"

# Requêtes N+1 potentielles (findMany dans une boucle)
grep -rn "findMany\|findOne\|findAll" \
  --include="*.ts" | grep -v node_modules | head -30

# Bundle size si frontend
ls -lh .next/static/chunks/*.js 2>/dev/null | sort -rh | head -10
```

## Étape 2 — Analyses parallèles (lancer avec Task)

### `performance-engineer agent`
**Skills activées : async-patterns, database-patterns, observability-patterns, error-handling-patterns**

Profiler et analyser `$ARGUMENTS` :
1. **Complexité algorithmique** : O(n²) évitables, boucles imbriquées sur grands datasets
2. **Appels I/O séquentiels** : convertir en Promise.all quand sans dépendance
3. **Requêtes N+1** : identifier les findMany/findAll dans des boucles, proposer include/select Prisma
4. **Allocations mémoire** : objets créés inutilement à chaque requête, closures qui retiennent des références
5. **Imports lourds** : packages importés en entier au lieu de tree-shaking
6. **Cache manquant** : résultats recalculés à chaque appel (candidates pour Redis/in-memory)

Produire un benchmark avec `autocannon` :
```typescript
// Benchmark pattern
import autocannon from 'autocannon'
const result = await autocannon({
  url: 'http://localhost:3000/api/$ARGUMENTS',
  connections: 10,
  duration: 10
})
// Extraire : p50, p95, p99, requests/sec, errors
```

### `architect agent`
**Skills activées : database-patterns, async-patterns, api-design, observability-patterns**

Analyser l'architecture de `$ARGUMENTS` pour :
- Schéma DB : index manquants, colonnes non indexées dans WHERE/ORDER BY
- Requêtes Prisma : chargement de données non utilisées (over-fetching), absence de `select`
- Stratégie de cache : CDN, Redis, memoïzation — quoi, où, TTL ?
- Connection pooling : configuration PgBouncer/Prisma pool size vs nombre de workers
- Architecture de chargement : eager vs lazy loading, pagination cursor vs offset

### `devops-engineer agent`
**Skills activées : observability-patterns, docker-k8s, incident-response**

Analyser l'infrastructure de `$ARGUMENTS` :
- Métriques APM actuelles (si disponibles) : p95/p99 latency, error rate, throughput
- Ressources allouées vs consommées (CPU/RAM) : sur-provisionnement ou sous-provisionnement ?
- Bottlenecks réseau : connexions DB persistent ? Keep-alive HTTP configuré ?
- Horizontal scaling possible ? Stateful ou stateless ?
- SLOs définis ? Alertes configurées ?

## Étape 3 — Benchmark détaillé

```bash
# Démarrer l'app localement (si applicable)
# npm run dev &

# Test de charge rapide (si autocannon disponible)
npx autocannon -c 10 -d 10 http://localhost:3000/api/$ARGUMENTS 2>/dev/null || echo "autocannon non disponible"

# Analyse des requêtes lentes Prisma (si logs activés)
grep -i "slow\|timeout\|duration" logs/*.log 2>/dev/null | tail -20

# Memory heap (Node.js)
node --expose-gc -e "
const used = process.memoryUsage();
Object.entries(used).forEach(([k,v]) => console.log(k, Math.round(v/1024/1024) + 'MB'));
" 2>/dev/null || true

# Vérifier les index DB manquants (si PostgreSQL)
# psql -c "SELECT relname, n_live_tup, idx_scan, seq_scan FROM pg_stat_user_tables ORDER BY seq_scan DESC LIMIT 10;" 2>/dev/null || true
```

## Étape 4 — Identification et priorisation

Classer les problèmes par **ROI** (gain estimé / effort) :

| Priorité | Problème | Gain estimé | Effort | Technique |
|----------|---------|-------------|--------|-----------|
| P0 | N+1 sur /api/orders | -80% latency | S | Prisma include |
| P1 | await en boucle (5x) | -60% CPU | S | Promise.all |
| P2 | Index manquant sur user.email | -70% query time | XS | Migration DB |
| P3 | Bundle js 2MB non splitté | -40% LCP | M | dynamic import |
| P4 | Cache Redis manquant | -50% p95 | M | ioredis + TTL |

## Étape 5 — Rapport final

```markdown
# Rapport d'Audit Performance — $ARGUMENTS
**Date** : $(date)
**Périmètre** : [Module/Endpoint audité]

## Métriques actuelles (baseline)
| Métrique | Valeur | SLO cible | Statut |
|---------|--------|-----------|--------|
| p50 latency | Xms | < 50ms | ✅/❌ |
| p95 latency | Xms | < 200ms | ✅/❌ |
| p99 latency | Xms | < 500ms | ✅/❌ |
| Throughput | X req/s | > X req/s | ✅/❌ |
| Error rate | X% | < 0.1% | ✅/❌ |

## Goulots d'étranglement identifiés

### 🔴 Critiques — Impact immédiat
| # | Fichier:Ligne | Problème | Gain estimé | Technique |
|---|--------------|---------|-------------|-----------|
| P1 | src/api/orders.ts:45 | N+1 (100 requêtes/req) | -80% latency | Prisma include |

### 🟠 Importants
[même format]

### 🟡 Optimisations suggérées
[même format]

## Plan d'optimisation

### Sprint 1 (Quick wins — S effort)
1. [P1] Ajouter index sur `orders.userId` — migration SQL
2. [P2] Convertir 3 await séquentiels en Promise.all dans processOrder

### Sprint 2 (M effort — fort ROI)
3. [P3] Implémenter cache Redis pour /api/products (TTL: 60s)
4. [P4] Code splitting des composants lourds (dynamic import)

### Sprint 3 (L effort — scalabilité)
5. [P5] Connection pooling avec PgBouncer
6. [P6] Pagination cursor-based pour /api/orders (actuellement offset)

## Métriques projetées après optimisation
| Métrique | Avant | Après estimé | Delta |
|---------|-------|-------------|-------|
| p95 latency | Xms | Xms | -X% |
| Throughput | X/s | X/s | +X% |
| DB queries/req | X | X | -X% |

## Skills recommandées pour l'implémentation
- [async-patterns] : Promise.all, retry logic
- [database-patterns] : Prisma select/include, index migrations, N+1 fixes
- [observability-patterns] : Métriques p95/p99, alertes SLO

## Agents à utiliser pour la suite
- Implémentation : `use performance-engineer agent` + `use developer agent`
- Validation : `/workflows/refactor $ARGUMENTS`
```
