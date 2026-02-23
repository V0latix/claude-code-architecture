---
name: docker-k8s
description: "Containerisation avec Docker et orchestration Kubernetes : Dockerfiles optimisés, docker-compose, manifests K8s, Helm charts et bonnes pratiques de production. Activer pour containeriser une application ou déployer sur K8s."
license: MIT
---

# Docker & Kubernetes

## Quand utiliser cette skill

- Containerisation d'une application
- Configuration de docker-compose pour le développement
- Déploiement sur Kubernetes
- Optimisation des images Docker
- Création de Helm charts

## Docker — Best Practices

### Dockerfile multi-stage optimisé

```dockerfile
# ---- Build Stage ----
FROM node:20-alpine AS builder
WORKDIR /app

# Copier les manifestes en premier (cache Docker)
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# ---- Production Stage ----
FROM node:20-alpine AS runtime

# Sécurité : utilisateur non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Seulement les dépendances de production
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copier les artefacts du build
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --chown=appuser:appgroup public ./public

USER appuser

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "dist/index.js"]
```

### .dockerignore

```
node_modules
.git
.env*
*.md
coverage
dist
.next
```

### docker-compose pour le développement

```yaml
# docker-compose.yml
version: '3.9'

services:
  app:
    build:
      context: .
      target: builder  # Stage de développement
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules  # Éviter d'écraser node_modules
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://postgres:password@db:5432/mydb
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mydb
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

## Kubernetes — Manifests essentiels

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  labels:
    app: app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    metadata:
      labels:
        app: app
    spec:
      containers:
        - name: app
          image: myrepo/app:1.0.0
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: database-url
          readinessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 10
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 30
```

### HorizontalPodAutoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

## Anti-patterns à éviter

```dockerfile
# ❌ Image non taguée
FROM node:latest  # Imprévisible

# ✅ Image figée
FROM node:20.10.0-alpine

# ❌ Secrets dans l'image
ENV API_KEY=secret123

# ✅ Secrets via runtime
# Utiliser K8s Secrets ou vault

# ❌ Tout en root
RUN npm install && ...
CMD ["node", "server.js"]

# ✅ Utilisateur dédié non-root
USER appuser
```
