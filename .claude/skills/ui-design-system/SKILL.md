---
name: ui-design-system
description: "Patterns UI avancés pour applications modernes : shadcn/ui, Radix UI, Framer Motion, dark mode CSS variables, design token scales, composants avancés (Command, Sheet, Combobox) et CVA compound components. Activer pour créer des UIs polished, implémenter des animations ou architecturer un design system."
license: MIT
---

# UI Design System

## Quand utiliser cette skill

- Mise en place d'un design system avec shadcn/ui
- Implémentation d'animations avec Framer Motion
- Configuration dark mode / theming dynamique
- Création de composants avancés (Command Palette, Sheets, Drawers)
- Architecture d'une bibliothèque de composants composables

---

## 1. shadcn/ui — Configuration et theming

```bash
# Initialisation
npx shadcn@latest init

# Ajout de composants
npx shadcn@latest add button card dialog sheet command
```

```json
// components.json — configuration du projet
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "app/globals.css",
    "baseColor": "slate",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui"
  }
}
```

```css
/* app/globals.css — CSS variables pour le theming */
@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 221.2 83.2% 53.3%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 221.2 83.2% 53.3%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --primary: 217.2 91.2% 59.8%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 224.3 76.3% 48%;
  }
}
```

### Customisation d'un composant shadcn/ui

```typescript
// components/ui/button.tsx — Extension du composant shadcn
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  'inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
        secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
        link: 'text-primary underline-offset-4 hover:underline',
        // Variant custom ajouté
        gradient: 'bg-gradient-to-r from-primary to-primary/70 text-primary-foreground hover:from-primary/90 hover:to-primary/60 shadow-lg shadow-primary/25',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 rounded-md px-3',
        lg: 'h-11 rounded-md px-8',
        icon: 'h-10 w-10',
        xs: 'h-7 rounded px-2 text-xs',
      },
    },
    defaultVariants: { variant: 'default', size: 'default' },
  }
)
```

---

## 2. Radix UI — Primitives accessibles

```typescript
// Popover composable
import * as Popover from '@radix-ui/react-popover'

export function FilterPopover({ children, content }: FilterPopoverProps) {
  return (
    <Popover.Root>
      <Popover.Trigger asChild>{children}</Popover.Trigger>
      <Popover.Portal>
        <Popover.Content
          className="z-50 w-72 rounded-md border bg-popover p-4 shadow-md outline-none data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0"
          sideOffset={8}
          align="start"
        >
          {content}
          <Popover.Arrow className="fill-border" />
        </Popover.Content>
      </Popover.Portal>
    </Popover.Root>
  )
}

// Dialog avec focus trap et scroll lock
import * as Dialog from '@radix-ui/react-dialog'

export function Modal({ trigger, title, children }: ModalProps) {
  return (
    <Dialog.Root>
      <Dialog.Trigger asChild>{trigger}</Dialog.Trigger>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 z-50 bg-black/80 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0" />
        <Dialog.Content className="fixed left-[50%] top-[50%] z-50 grid w-full max-w-lg translate-x-[-50%] translate-y-[-50%] gap-4 border bg-background p-6 shadow-lg duration-200 data-[state=open]:animate-in data-[state=closed]:animate-out">
          <Dialog.Title className="text-lg font-semibold">{title}</Dialog.Title>
          {children}
          <Dialog.Close className="absolute right-4 top-4 rounded-sm opacity-70 hover:opacity-100">
            ✕
          </Dialog.Close>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}
```

---

## 3. Framer Motion — Animations

### Variants et animations d'entrée

```typescript
import { motion, AnimatePresence, type Variants } from 'framer-motion'

// Variants réutilisables
export const fadeInUp: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: 'easeOut' } },
  exit: { opacity: 0, y: -10, transition: { duration: 0.2 } },
}

export const staggerContainer: Variants = {
  hidden: {},
  visible: { transition: { staggerChildren: 0.08, delayChildren: 0.1 } },
}

export const scaleIn: Variants = {
  hidden: { opacity: 0, scale: 0.95 },
  visible: { opacity: 1, scale: 1, transition: { type: 'spring', stiffness: 300, damping: 24 } },
  exit: { opacity: 0, scale: 0.95 },
}

// Usage : liste avec stagger
function FeatureList({ features }: { features: Feature[] }) {
  return (
    <motion.ul variants={staggerContainer} initial="hidden" animate="visible">
      {features.map((feature) => (
        <motion.li key={feature.id} variants={fadeInUp}>
          <FeatureCard feature={feature} />
        </motion.li>
      ))}
    </motion.ul>
  )
}

// AnimatePresence pour les entrées/sorties conditionnelles
function Notification({ show, message }: NotificationProps) {
  return (
    <AnimatePresence>
      {show && (
        <motion.div
          variants={fadeInUp}
          initial="hidden"
          animate="visible"
          exit="exit"
          className="fixed bottom-4 right-4"
        >
          {message}
        </motion.div>
      )}
    </AnimatePresence>
  )
}
```

### Layout animations

```typescript
// Shared layout transitions (ex: tab indicator, selected item)
function Tabs({ tabs, activeTab, onChange }: TabsProps) {
  return (
    <div className="relative flex gap-1">
      {tabs.map((tab) => (
        <button key={tab.id} onClick={() => onChange(tab.id)} className="relative px-4 py-2">
          {activeTab === tab.id && (
            <motion.div
              layoutId="active-tab"    // Clé partagée = animation fluide entre tabs
              className="absolute inset-0 rounded-md bg-primary/10"
              transition={{ type: 'spring', stiffness: 500, damping: 35 }}
            />
          )}
          <span className="relative z-10">{tab.label}</span>
        </button>
      ))}
    </div>
  )
}

// Page transitions (dans layout.tsx)
export default function Template({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3, ease: 'easeOut' }}
    >
      {children}
    </motion.div>
  )
}
```

### Gestures et micro-interactions

```typescript
// Bouton avec tap feedback
<motion.button
  whileHover={{ scale: 1.02 }}
  whileTap={{ scale: 0.98 }}
  transition={{ type: 'spring', stiffness: 400, damping: 17 }}
>
  Envoyer
</motion.button>

// Card avec hover 3D subtil
<motion.div
  whileHover={{ y: -4, boxShadow: '0 20px 40px rgba(0,0,0,0.12)' }}
  transition={{ type: 'spring', stiffness: 300, damping: 20 }}
  className="rounded-xl border bg-card p-6"
>
  <CardContent />
</motion.div>
```

---

## 4. Dark Mode avec next-themes

```bash
npm install next-themes
```

```typescript
// app/providers.tsx
'use client'

import { ThemeProvider } from 'next-themes'

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider
      attribute="class"
      defaultTheme="system"
      enableSystem
      disableTransitionOnChange
    >
      {children}
    </ThemeProvider>
  )
}

// components/theme-toggle.tsx
'use client'

import { useTheme } from 'next-themes'
import { Moon, Sun } from 'lucide-react'
import { Button } from '@/components/ui/button'

export function ThemeToggle() {
  const { theme, setTheme } = useTheme()

  return (
    <Button
      variant="ghost"
      size="icon"
      onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
      aria-label="Toggle theme"
    >
      <Sun className="h-4 w-4 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
      <Moon className="absolute h-4 w-4 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
    </Button>
  )
}
```

---

## 5. Design Token Scales

```typescript
// lib/design-tokens.ts — Scales sémantiques
export const tokens = {
  // Palette HSL (compatible CSS variables shadcn)
  colors: {
    brand: {
      50:  'hsl(214, 100%, 97%)',
      100: 'hsl(214, 95%, 93%)',
      500: 'hsl(221, 83%, 53%)',
      600: 'hsl(221, 83%, 45%)',
      900: 'hsl(221, 83%, 20%)',
    },
    semantic: {
      success: 'hsl(142, 76%, 36%)',
      warning: 'hsl(38, 92%, 50%)',
      error:   'hsl(0, 84%, 60%)',
      info:    'hsl(199, 89%, 48%)',
    },
  },

  // Spacing scale (base 4px)
  spacing: {
    px: '1px', 0.5: '2px', 1: '4px', 2: '8px', 3: '12px',
    4: '16px', 5: '20px', 6: '24px', 8: '32px', 10: '40px',
    12: '48px', 16: '64px', 20: '80px', 24: '96px',
  },

  // Typography scale
  typography: {
    xs:   { size: '0.75rem', lineHeight: '1rem' },
    sm:   { size: '0.875rem', lineHeight: '1.25rem' },
    base: { size: '1rem', lineHeight: '1.5rem' },
    lg:   { size: '1.125rem', lineHeight: '1.75rem' },
    xl:   { size: '1.25rem', lineHeight: '1.75rem' },
    '2xl': { size: '1.5rem', lineHeight: '2rem' },
    '3xl': { size: '1.875rem', lineHeight: '2.25rem' },
    '4xl': { size: '2.25rem', lineHeight: '2.5rem' },
  },

  // Shadow scale
  shadows: {
    sm:  '0 1px 2px 0 rgb(0 0 0 / 0.05)',
    md:  '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
    lg:  '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
    xl:  '0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)',
    glow: '0 0 20px -5px hsl(var(--primary) / 0.4)',
  },
} as const
```

---

## 6. Composants avancés

### Command Palette (cmdk)

```typescript
// components/ui/command-palette.tsx
'use client'

import { useEffect, useState } from 'react'
import { Command, CommandDialog, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from '@/components/ui/command'

export function CommandPalette() {
  const [open, setOpen] = useState(false)

  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === 'k' && (e.metaKey || e.ctrlKey)) {
        e.preventDefault()
        setOpen((prev) => !prev)
      }
    }
    document.addEventListener('keydown', down)
    return () => document.removeEventListener('keydown', down)
  }, [])

  return (
    <CommandDialog open={open} onOpenChange={setOpen}>
      <CommandInput placeholder="Rechercher une commande..." />
      <CommandList>
        <CommandEmpty>Aucun résultat.</CommandEmpty>
        <CommandGroup heading="Navigation">
          <CommandItem onSelect={() => { setOpen(false) }}>
            Dashboard
          </CommandItem>
        </CommandGroup>
      </CommandList>
    </CommandDialog>
  )
}
```

### Sheet / Drawer mobile-responsive

```typescript
// Pattern responsive : Sheet sur desktop, Drawer sur mobile
import { useMediaQuery } from '@/hooks/use-media-query'
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from '@/components/ui/sheet'
import { Drawer, DrawerContent, DrawerHeader, DrawerTitle, DrawerTrigger } from '@/components/ui/drawer'

interface ResponsivePanelProps {
  trigger: React.ReactNode
  title: string
  children: React.ReactNode
}

export function ResponsivePanel({ trigger, title, children }: ResponsivePanelProps) {
  const isDesktop = useMediaQuery('(min-width: 768px)')

  if (isDesktop) {
    return (
      <Sheet>
        <SheetTrigger asChild>{trigger}</SheetTrigger>
        <SheetContent>
          <SheetHeader><SheetTitle>{title}</SheetTitle></SheetHeader>
          {children}
        </SheetContent>
      </Sheet>
    )
  }

  return (
    <Drawer>
      <DrawerTrigger asChild>{trigger}</DrawerTrigger>
      <DrawerContent>
        <DrawerHeader><DrawerTitle>{title}</DrawerTitle></DrawerHeader>
        {children}
      </DrawerContent>
    </Drawer>
  )
}

// hooks/use-media-query.ts
'use client'
import { useEffect, useState } from 'react'
export function useMediaQuery(query: string) {
  const [matches, setMatches] = useState(false)
  useEffect(() => {
    const media = window.matchMedia(query)
    setMatches(media.matches)
    const listener = (e: MediaQueryListEvent) => setMatches(e.matches)
    media.addEventListener('change', listener)
    return () => media.removeEventListener('change', listener)
  }, [query])
  return matches
}
```

### Toast avec Sonner

```typescript
// app/layout.tsx
import { Toaster } from 'sonner'
export default function RootLayout({ children }) {
  return (
    <html lang="fr">
      <body>
        {children}
        <Toaster position="bottom-right" richColors closeButton />
      </body>
    </html>
  )
}

// Usage dans une Server Action ou Client Component
import { toast } from 'sonner'

// Succès
toast.success('Sauvegardé', { description: 'Vos modifications ont été enregistrées.' })

// Erreur avec action
toast.error('Échec de la sauvegarde', {
  description: 'Vérifiez votre connexion.',
  action: { label: 'Réessayer', onClick: () => retry() },
})

// Promise
toast.promise(saveData(), {
  loading: 'Sauvegarde...',
  success: 'Sauvegardé !',
  error: 'Erreur lors de la sauvegarde',
})
```

---

## 7. CVA + Compound Components

```typescript
// Pattern Compound Component avec Context
import { createContext, useContext } from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

// Card composable
const CardContext = createContext<{ variant: 'default' | 'bordered' | 'elevated' }>({ variant: 'default' })

const cardVariants = cva('rounded-xl bg-card text-card-foreground', {
  variants: {
    variant: {
      default:  'border shadow-sm',
      bordered: 'border-2 border-primary/20',
      elevated: 'shadow-lg shadow-black/5 dark:shadow-black/20',
    },
    padding: {
      none: '',
      sm:   'p-4',
      md:   'p-6',
      lg:   'p-8',
    },
  },
  defaultVariants: { variant: 'default', padding: 'md' },
})

export interface CardProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof cardVariants> {}

function Card({ className, variant = 'default', padding, ...props }: CardProps) {
  return (
    <CardContext.Provider value={{ variant: variant ?? 'default' }}>
      <div className={cn(cardVariants({ variant, padding }), className)} {...props} />
    </CardContext.Provider>
  )
}

function CardHeader({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('flex flex-col space-y-1.5 pb-4', className)} {...props} />
}

function CardTitle({ className, ...props }: React.HTMLAttributes<HTMLHeadingElement>) {
  return <h3 className={cn('text-lg font-semibold leading-none tracking-tight', className)} {...props} />
}

function CardContent({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('pt-0', className)} {...props} />
}

// Export en namespace
export { Card, CardHeader, CardTitle, CardContent }

// Usage : interface composable et intuitive
<Card variant="elevated" padding="lg">
  <CardHeader>
    <CardTitle>Titre</CardTitle>
  </CardHeader>
  <CardContent>Contenu</CardContent>
</Card>
```

---

## Anti-patterns à éviter

```typescript
// ❌ Inline styles pour le theming (pas de dark mode possible)
<div style={{ backgroundColor: '#ffffff', color: '#000000' }}>

// ✅ CSS variables via Tailwind
<div className="bg-background text-foreground">

// ❌ Animation CSS sans AnimatePresence (composant reste dans le DOM)
{isOpen && <div className="animate-fade-in">...</div>}

// ✅ AnimatePresence gère le unmount avec exit animation
<AnimatePresence>{isOpen && <motion.div exit={...}>...</motion.div>}</AnimatePresence>

// ❌ Framer Motion sur tous les éléments (perf dégradée)
{items.map(item => <motion.div whileHover={...} key={item.id}>{item.name}</motion.div>)}

// ✅ Utiliser CSS hover pour les animations simples, Framer pour les complexes
{items.map(item => <div className="hover:scale-105 transition-transform" key={item.id}>{item.name}</div>)}

// ❌ ThemeProvider côté serveur
// app/layout.tsx (Server Component)
export default function Layout({ children }) {
  return <ThemeProvider>{children}</ThemeProvider>  // Erreur !
}

// ✅ Wrapper dans un Client Component (providers.tsx)
'use client'
export function Providers({ children }) {
  return <ThemeProvider attribute="class">{children}</ThemeProvider>
}
```
