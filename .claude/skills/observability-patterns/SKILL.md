---
name: observability-patterns
description: "Patterns d'observabilité pour systèmes de production : métriques Prometheus, dashboards Grafana, distributed tracing OpenTelemetry, SLOs/SLAs et structured logging. Activer pour mettre en place le monitoring, analyser des incidents ou instrumenter une application."
license: MIT
sources: "wshobson/agents (prometheus-configuration, grafana-dashboards, distributed-tracing, slo-implementation, observability-engineer)"
---

# Observability Patterns

## Quand utiliser cette skill

- Instrumenter une application pour la production
- Configurer le monitoring (Prometheus, Grafana)
- Mettre en place le distributed tracing
- Définir des SLOs et alertes
- Analyser les performances en production

## Les 3 piliers de l'observabilité

| Pilier | Outil | Usage |
|--------|-------|-------|
| **Métriques** | Prometheus + Grafana | Tendances, alertes, capacité |
| **Logs** | Structured JSON + Loki/ELK | Debugging, audit |
| **Traces** | OpenTelemetry + Jaeger/Tempo | Latence, dépendances |

## 1. OpenTelemetry — Instrumentation Node.js

```typescript
// instrumentation.ts — À charger AVANT tout autre import
import { NodeSDK } from '@opentelemetry/sdk-node'
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node'
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http'
import { Resource } from '@opentelemetry/resources'
import { SEMRESATTRS_SERVICE_NAME, SEMRESATTRS_SERVICE_VERSION } from '@opentelemetry/semantic-conventions'

const sdk = new NodeSDK({
  resource: new Resource({
    [SEMRESATTRS_SERVICE_NAME]: process.env.SERVICE_NAME ?? 'unknown-service',
    [SEMRESATTRS_SERVICE_VERSION]: process.env.npm_package_version ?? '0.0.0',
  }),
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? 'http://localhost:4318/v1/traces',
  }),
  instrumentations: [getNodeAutoInstrumentations()],
})

sdk.start()
process.on('SIGTERM', () => sdk.shutdown())
```

## 2. Traces personnalisées

```typescript
import { trace, context, SpanStatusCode } from '@opentelemetry/api'

const tracer = trace.getTracer('my-service', '1.0.0')

const processOrder = async (orderId: string): Promise<Order> => {
  return tracer.startActiveSpan('processOrder', async (span) => {
    span.setAttributes({
      'order.id': orderId,
      'order.source': 'api',
    })

    try {
      const order = await fetchOrder(orderId)
      span.setAttributes({ 'order.total': order.total, 'order.items': order.items.length })

      const result = await chargePayment(order)
      span.setStatus({ code: SpanStatusCode.OK })
      return result
    } catch (error) {
      span.setStatus({ code: SpanStatusCode.ERROR, message: String(error) })
      span.recordException(error as Error)
      throw error
    } finally {
      span.end()
    }
  })
}
```

## 3. Métriques Prometheus (Node.js)

```typescript
import { Registry, Counter, Histogram, Gauge } from 'prom-client'

const registry = new Registry()

// RED Metrics (Rate, Errors, Duration)
const httpRequests = new Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [registry],
})

const httpDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
  registers: [registry],
})

const activeConnections = new Gauge({
  name: 'active_connections',
  help: 'Number of active connections',
  registers: [registry],
})

// Middleware Express/Next.js
export const metricsMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const end = httpDuration.startTimer({ method: req.method, route: req.route?.path ?? req.path })

  res.on('finish', () => {
    httpRequests.inc({ method: req.method, route: req.route?.path ?? req.path, status_code: res.statusCode })
    end()
  })

  next()
}

// Endpoint /metrics
app.get('/metrics', async (_req, res) => {
  res.set('Content-Type', registry.contentType)
  res.end(await registry.metrics())
})
```

## 4. Structured Logging

```typescript
import pino from 'pino'

const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  formatters: {
    level: (label) => ({ level: label }),
  },
  base: {
    service: process.env.SERVICE_NAME,
    version: process.env.npm_package_version,
    env: process.env.NODE_ENV,
  },
  // Redaction des données sensibles
  redact: {
    paths: ['req.headers.authorization', 'body.password', 'body.token', '*.creditCard'],
    censor: '[REDACTED]',
  },
})

// Logger avec contexte de trace
const getLoggerWithTrace = () => {
  const span = trace.getActiveSpan()
  const spanContext = span?.spanContext()
  return logger.child({
    traceId: spanContext?.traceId,
    spanId: spanContext?.spanId,
  })
}

// Usage
logger.info({ userId, action: 'login', ip: req.ip }, 'User logged in')
logger.error({ err: error, orderId }, 'Failed to process order')
```

## 5. SLOs (Service Level Objectives)

```typescript
// Définition des SLOs
const SLOs = {
  availability: {
    target: 0.999,    // 99.9% — max 43.8 min/mois d'indisponibilité
    window: '30d',
  },
  latency: {
    p95: 200,         // 95% des requêtes < 200ms
    p99: 500,         // 99% des requêtes < 500ms
    window: '7d',
  },
  errorRate: {
    target: 0.001,    // < 0.1% d'erreurs
    window: '24h',
  },
}

// Calcul du budget d'erreurs restant
const errorBudget = {
  totalMinutes: 30 * 24 * 60,  // 30 jours
  allowedDowntime: 30 * 24 * 60 * (1 - SLOs.availability.target), // ~43.8 min
  consumed: 0, // à récupérer depuis les métriques
  remaining: function() { return this.allowedDowntime - this.consumed },
  burnRate: function() { return this.consumed / this.allowedDowntime },
}
```

## 6. Alertes Prometheus (règles)

```yaml
# prometheus-rules.yaml
groups:
  - name: service-slo
    rules:
      # Alerte si error rate > 1% sur 5 minutes
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status_code=~"5.."}[5m]))
          /
          sum(rate(http_requests_total[5m])) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Error rate {{ $value | humanizePercentage }} above 1%"

      # Alerte latence p95 > 500ms
      - alert: HighLatency
        expr: |
          histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.5
        for: 10m
        labels:
          severity: warning
```

## 7. Dashboard Grafana — Panels essentiels

```json
{
  "panels": [
    { "title": "Request Rate (req/s)", "type": "stat",
      "expr": "sum(rate(http_requests_total[5m]))" },
    { "title": "Error Rate (%)", "type": "stat",
      "expr": "sum(rate(http_requests_total{status_code=~'5..'}[5m])) / sum(rate(http_requests_total[5m])) * 100",
      "thresholds": [{ "value": 1, "color": "red" }] },
    { "title": "P95 Latency (ms)", "type": "graph",
      "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) * 1000" },
    { "title": "Active Connections", "type": "gauge", "expr": "active_connections" }
  ]
}
```

## Anti-patterns à éviter

```typescript
// ❌ Logs en format texte libre (impossible à parser)
console.log(`User ${userId} logged in at ${new Date()}`)

// ✅ Structured JSON logging
logger.info({ userId, event: 'login', timestamp: Date.now() })

// ❌ Métriques sans labels (impossible de filtrer)
requestCounter.inc()

// ✅ Labels pertinents
requestCounter.inc({ method, route, status })

// ❌ Tracer uniquement les succès (masque les problèmes)
try {
  span.end()
} catch (e) {
  // erreur ignorée, span pas fermé
}

// ✅ Toujours fermer les spans dans un finally
try { ... } finally { span.end() }
```
