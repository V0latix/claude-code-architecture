---
description: "Développement d'une extension VSCode end-to-end : concept → scaffold → implémentation → tests → sécurité → documentation → publication Marketplace ou Open VSX. Orchestre vscode-developer, architect, qa-engineer, security-auditor et doc-writer."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# VSCode Extension Development

Développement de l'extension VSCode : **$ARGUMENTS**

`$ARGUMENTS` doit décrire l'extension (type + fonctionnalité + audience cible).
Exemples :
- `"prisma-explorer : TreeView des modèles Prisma dans la sidebar"`
- `"code-reviewer : Chat Participant Copilot pour review de code TypeScript"`
- `"myconfig-support : Language support (completion + diagnostics) pour fichiers .myconfig"`

---

## Phase 0 — Qualification

Identifier le type d'extension depuis `$ARGUMENTS` :

| Type | Caractéristiques |
|------|-----------------|
| **Command** | Action déclenchée via palette, raccourci ou menu contextuel |
| **TreeView** | Panneau latéral hiérarchique (Explorer, Source Control style) |
| **Webview** | Interface HTML/CSS/JS dans un panneau VSCode |
| **Language Support** | Completion, diagnostics, hover, go-to-definition pour un langage |
| **Chat Participant** | Integration dans GitHub Copilot Chat (`@nom-agent`) |
| **Debugger** | Intégration Debug Adapter Protocol |
| **Theme** | Thème de couleurs ou d'icônes |

Décider du modèle de publication :
- **Marketplace** → nécessite un compte Azure DevOps + Personal Access Token (PAT)
- **Open VSX** → pour éditeurs open-source (VSCodium, Theia, Gitpod) via jeton ovsx

---

## Phase 1 — Spécification

### `product-manager agent` (skills: architecture-diagrams, prompt-engineering)

Pour `$ARGUMENTS`, définir :
- **Problème utilisateur** résolu par l'extension (1-2 phrases)
- **Contributes attendus** : quelles commandes, vues, settings, keybindings
- **Activation events** appropriés : `onCommand:`, `onLanguage:`, `workspaceContains:`
- **Critères d'acceptation** par fonctionnalité (Given/When/Then)
- **Permissions et accès requis** : workspace, réseau, fichiers, secrets

---

## Phase 2 — Architecture

### `architect agent` (skills: api-design, architecture-diagrams, async-patterns)

1. Sélectionner les **namespaces VSCode API** nécessaires (commands, window, workspace, languages, lm, scm...)
2. Rédiger le **`package.json` manifest complet** :
   - `contributes` exhaustifs (commandes, vues, configuration, keybindings, grammars si LSP)
   - `activationEvents` spécifiques (jamais `*`)
   - `engines.vscode` minimum requis
3. Identifier les **dépendances npm** (ex: `vscode-languageclient` si LSP, `@vscode/chat` si Chat Participant)
4. Choisir la stratégie de **bundling** : esbuild recommandé (target `node`, `format: cjs`, `external: ['vscode']`)
5. Définir l'**architecture des modules** : `commands/`, `providers/`, `webviews/`, `utils/`
6. Créer un ADR dans `/docs/decisions/` si décision significative (choix LSP vs providers inline, architecture Webview, etc.)

---

## Phase 3 — Scaffold

### `vscode-developer agent` (skills: vscode-extension)

```bash
# Vérifier les outils disponibles
which node npm npx 2>/dev/null && node --version
```

Utiliser la commande `scaffold-extension $NOM $TYPE` pour générer le projet complet.

Fichiers générés :
```
$NOM-EXTENSION/
├── package.json              # Manifest avec contributes de Phase 2
├── src/extension.ts          # activate() + deactivate() squelettes
├── src/providers/            # Provider selon le type (TreeDataProvider, WebviewPanel, etc.)
├── test/suite/extension.test.ts  # Smoke test + test type-spécifique
├── test/runTest.ts           # Runner @vscode/test-cli
├── esbuild.js                # Bundle script (--production + --watch)
├── tsconfig.json             # strict: true, module: commonjs, target: ES2020
├── .vscodeignore             # Exclut src/, test/, node_modules/, *.map
├── .vscode/launch.json       # "Run Extension" + "Extension Tests"
└── CHANGELOG.md              # Format Keep a Changelog
```

```bash
# Installer les dépendances et tester le scaffold
cd $NOM-EXTENSION
npm install
npm run compile
# Ouvrir dans VSCode et tester via F5 → "Run Extension"
```

---

## Phase 4 — Implémentation

### `vscode-developer agent` (skills: vscode-extension, async-patterns, error-handling-patterns)

**Règle universelle** : chaque disposable doit être pushé dans `context.subscriptions`.

**Si Command :**
```typescript
// 1. registerCommand avec withProgress si opération > 500ms
// 2. CancellationToken pour les opérations annulables
// 3. showErrorMessage pour les erreurs utilisateur (jamais throw silencieux)
// 4. Mettre à jour package.json contributes.commands + menus
```

**Si TreeView :**
```typescript
// 1. TreeDataProvider<T> avec EventEmitter pour refresh
// 2. TreeItem avec iconPath (ThemeIcon pour icônes built-in VSCode)
// 3. contextValue pour les menus contextuels (when: "view/item/context")
// 4. createTreeView (pas registerTreeDataProvider — plus de contrôle)
// 5. Commande refresh dans package.json contributes
```

**Si Webview :**
```typescript
// 1. createWebviewPanel avec localResourceRoots restreint
// 2. Nonce CSP généré par session (crypto.randomBytes)
// 3. postMessage (extension → webview) + onDidReceiveMessage (webview → extension)
// 4. onDidDispose pour le cleanup
// 5. retainContextWhenHidden: true si état important
```

**Si Language Support :**
```typescript
// Choix architecture :
// a) Providers inline : registerCompletionItemProvider, registerHoverProvider, etc.
// b) Language Server (LSP) : vscode-languageclient + processus serveur séparé
//    (recommandé si features riches : completion, diagnostics, formatting, rename...)
// Contribuer language + grammar dans package.json pour nouveau langage
```

**Si Chat Participant :**
```typescript
// 1. Contribuer chatParticipants dans package.json
// 2. createChatParticipant avec ChatRequestHandler
// 3. lm.selectChatModels pour accès aux modèles Copilot
// 4. stream.markdown + stream.progress pour le streaming
// 5. followupProvider pour les suggestions de continuation
```

Validation continue :
```bash
npx tsc --noEmit    # Vérification TypeScript strict
node esbuild.js     # Rebuild après chaque modification
# F5 dans VSCode → tester manuellement dans l'Extension Development Host
```

---

## Phase 5 — Tests

### `qa-engineer agent` (skills: testing-patterns, error-handling-patterns)

```typescript
// Pattern Mocha Extension Host
suite('Extension Test Suite', () => {
  suiteSetup(async () => {
    const ext = vscode.extensions.getExtension('publisher.$NOM')
    if (ext && !ext.isActive) await ext.activate()
  })

  test('Extension should activate', () => {
    assert.ok(vscode.extensions.getExtension('publisher.$NOM')?.isActive)
  })
})
```

Tests à couvrir selon le type :
- **Command** : commande bien enregistrée dans `getCommands()`, résultat attendu, gestion d'erreur si no workspace
- **TreeView** : items racine non nuls, rafraîchissement après changement de données, actions contextuelles
- **Webview** : panel créé, messages reçus, dispose nettoie les ressources
- **Language** : completions retournées aux positions attendues, diagnostics générés sur code invalide
- **Chat Participant** : participant enregistré, handler appelé, stream contient du markdown

```bash
# Lancer les tests Extension Host
npm test

# En CI (headless VSCode 1.86+)
npx @vscode/test-cli run --headless
```

---

## Phase 6 — Sécurité

### `security-auditor agent` (skills: security-scanning, error-handling-patterns)

Points critiques spécifiques aux extensions VSCode :

- **Webview CSP** : nonce présent sur chaque script, `script-src 'nonce-...'` configuré, pas de `unsafe-inline`
- **Secrets** : `context.secrets` utilisé (chiffré), jamais `globalState` pour tokens ou credentials
- **Injection shell** : si `child_process.exec` ou `spawn` avec arguments utilisateur → sanitisation obligatoire
- **Requêtes réseau** : HTTPS uniquement, valider les URLs, pas de certificats auto-signés sans confirmation
- **Permissions manifest** : l'extension déclare-t-elle plus que nécessaire ? (`untrustedWorkspaces`, `capabilities`)
- **Dépendances** : `npm audit` sur les packages bundlés (non exclus par `external`)
- **globalState** : ne contient pas de données sensibles exploitables

---

## Phase 7 — Documentation

### `doc-writer agent` (skills: architecture-diagrams, document-processing)

- **`README.md`** orienté Marketplace :
  - Section **Features** avec captures d'écran ou GIF animé
  - Section **Requirements** (versions VSCode, dépendances)
  - Section **Extension Settings** (description de chaque `contributes.configuration` property)
  - Section **Known Issues** et **Release Notes**
- **`CHANGELOG.md`** au format Keep a Changelog (affiché tel quel sur le Marketplace)
- **Badges README** : `vscode-marketplace-version`, `installs`, `rating`
- **Documenter les `contributes.commands`** : title, keybinding, contexte d'activation

---

## Phase 8 — Publication

### `vscode-developer agent` (skills: vscode-extension)

```bash
# Installer les outils de publication
npm install -g @vscode/vsce

# Vérifier le contenu du package avant publication
vsce ls                    # Liste les fichiers inclus
du -sh *.vsix 2>/dev/null  # Taille du bundle (objectif : < 5 MB)

# Package (génère .vsix local pour test)
vsce package

# Publier sur le Marketplace VS Code
# Nécessite un PAT Azure DevOps (scope: Marketplace > Manage)
vsce publish --pat $VSCE_PAT
vsce publish patch   # Auto-incrémente la version patch

# Publier sur Open VSX (VSCodium, Theia, Gitpod)
npm install -g ovsx
ovsx publish *.vsix --pat $OVSX_PAT
```

Checklist pré-publication :
```
□ publisher défini dans package.json
□ repository.url défini
□ icon.png 128×128px présente
□ .vscodeignore à jour
□ CHANGELOG.md mis à jour avec la nouvelle version
□ version bumped dans package.json
□ vsce ls vérifié (bundle propre)
□ Testé dans VSCode Stable + extension Development Host
□ README avec au moins une capture d'écran
```

---

## Rapport de livraison

```markdown
## Extension VSCode Livrée : $ARGUMENTS

### Type : [Command | TreeView | Webview | Language | Chat Participant | Theme]
### Publication : [Marketplace | Open VSX | Privé .vsix]

### Agents utilisés
- [x] product-manager — Spécification et contributes définis
- [x] architect — package.json manifest + ADR (si applicable)
- [x] vscode-developer — Scaffold + implémentation complète
- [x] qa-engineer — Tests Extension Host (X tests)
- [x] security-auditor — ✅ CSP, secrets, injection
- [x] doc-writer — README + CHANGELOG Marketplace-ready

### Package
- Extension ID : publisher.$NOM
- Version : X.Y.Z
- Bundle : X KB (.vsix)
- Activation event : [onCommand:... | onLanguage:... | workspaceContains:...]

### Tests Extension Host : X
### Prêt pour publication : ✅ / ❌
```
