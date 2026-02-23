---
name: security-scanning
description: "Pratiques de sécurité applicative : OWASP Top 10, SAST, analyse de dépendances, secrets scanning, CSP et hardening. Activer lors de reviews de sécurité, avant les déploiements ou pour implémenter des contrôles de sécurité."
license: MIT
---

# Security Scanning

## Quand utiliser cette skill

- Review de sécurité avant merge ou déploiement
- Implémentation de contrôles de sécurité
- Analyse de vulnérabilités dans les dépendances
- Configuration des headers de sécurité HTTP
- Audit de code pour OWASP Top 10

## Checklist de sécurité

### Injection

```typescript
// ❌ SQL Injection
const user = await db.query(`SELECT * FROM users WHERE id = ${userId}`)

// ✅ Parameterized queries
const user = await db.query('SELECT * FROM users WHERE id = $1', [userId])

// ✅ ORM (Prisma, TypeORM)
const user = await prisma.user.findUnique({ where: { id: userId } })

// ❌ Command Injection
exec(`ls ${userInput}`)

// ✅ Validation stricte + pas de shell
execFile('ls', ['-la', validatedPath], { shell: false })
```

### Authentification & Sessions

```typescript
// Hachage sécurisé des mots de passe
import bcrypt from 'bcrypt'
const SALT_ROUNDS = 12

const hash = await bcrypt.hash(password, SALT_ROUNDS)
const isValid = await bcrypt.compare(password, storedHash)

// JWT sécurisé
const token = jwt.sign(
  { sub: userId, role: userRole },
  process.env.JWT_SECRET!,
  { expiresIn: '15m', algorithm: 'HS256' }
)

// Session cookie sécurisé
res.cookie('session', token, {
  httpOnly: true,   // Pas d'accès JavaScript
  secure: true,     // HTTPS uniquement
  sameSite: 'strict', // Protection CSRF
  maxAge: 900_000,  // 15 minutes
})
```

### XSS Prevention

```typescript
// ❌ Insertion directe de HTML
element.innerHTML = userContent

// ✅ Sanitisation
import DOMPurify from 'dompurify'
element.innerHTML = DOMPurify.sanitize(userContent)

// ✅ Encore mieux : textContent pour du texte
element.textContent = userContent

// Headers CSP (Content Security Policy)
const cspHeader = [
  "default-src 'self'",
  "script-src 'self' 'nonce-{random}'",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: https:",
  "connect-src 'self' https://api.example.com",
  "frame-ancestors 'none'",
].join('; ')
```

### Headers de sécurité HTTP

```typescript
// Next.js — next.config.js
const securityHeaders = [
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'X-XSS-Protection', value: '1; mode=block' },
  { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
]
```

### Gestion des secrets

```bash
# ❌ Ne jamais faire
const API_KEY = 'sk-prod-abc123...'  # dans le code
git commit -m "add API key"          # dans git

# ✅ Variables d'environnement
const apiKey = process.env.API_KEY
if (!apiKey) throw new Error('API_KEY is required')

# ✅ Scan des secrets avant commit
npm install -g @secretlint/secretlint
echo '{ "rules": [{ "id": "@secretlint/secretlint-rule-preset-recommend" }] }' > .secretlintrc.json
```

### Validation des entrées

```typescript
import { z } from 'zod'

const CreateUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100).trim(),
  age: z.number().int().min(0).max(150),
  role: z.enum(['user', 'admin']),
})

// Dans un handler API
const result = CreateUserSchema.safeParse(req.body)
if (!result.success) {
  return res.status(422).json({ errors: result.error.flatten() })
}
```

## Outils de scan

```bash
# Dépendances vulnérables
npm audit
npx audit-ci --high

# Secrets dans le code
npx secretlint "**/*"
npx trufflehog git file://. --only-verified

# SAST statique
npx semgrep scan --config=auto .

# Analyse des headers
npx securityheaders.com check https://your-site.com
```

## Anti-patterns critiques

```typescript
// ❌ eval() avec données utilisateur
eval(userInput)  // Remote Code Execution

// ❌ Désactiver la vérification SSL
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'

// ❌ Logs avec données sensibles
console.log('User logged in:', { email, password })

// ❌ Erreurs trop verbeuses en prod
res.status(500).json({ error: err.stack })  // Expose la structure interne
```
