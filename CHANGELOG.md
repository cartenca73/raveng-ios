# CHANGELOG FirmaCDC iOS

## v3.0.0 — 2026-04-14 — "The WOW release"

### 🎨 Grafica
- **MeshBackground animato** sostituisce i gradient statici — blob colorati che morphano in loop
- **Time-of-day theming**: 6 fasi (alba / mattina / giorno / pomeriggio / tramonto / notte) con paletta dedicata per ciascuna
- **Floating tab bar** con matched geometry pill animata e materiale vetro (stile Telegram)
- **Parallax hero** stretch-on-pull (stile App Store)
- **Empty state animati** SwiftUI nativi (orbiting dot, pulse, trim-path check)
- **Skeleton shimmer loaders** su tutte le liste (stile LinkedIn / Instagram)
- **3D gyroscope tilt** opzionale (Apple Wallet style)
- **Premium gradient buttons** con inner highlight + icon chip + colored shadow

### 🔒 Sicurezza
- **Face ID / Touch ID gate** con auto-lock configurable background timeout
- **BiometricLockOverlay** full-screen con icona type-specific (faceid/touchid/opticid)
- **Keychain** per access & refresh token

### 🚀 Automatismi
- **Spotlight search globale** ⌘K style con debounce + indice documenti + template + azioni
- **Document Camera** (VisionKit) per scansione e conversione a PDF multipagina
- **OCR autofill** via Apple Vision — riconosce label italiane (nome, CF, data, firma…) e propone posizioni dei campi
- **Siri App Intents** + AppShortcuts: "Hey Siri, apri FirmaCDC da firmare / verifica / nuovo template"
- **QR code share** con CIFilter H-correction per condividere la verifica blockchain
- **AI on-device summary** via NaturalLanguage — estrae parole/minuti stimati + top-5 frasi + entità nominate

### 🌐 Offline-first
- **OfflineCache** actor con JSON persistence di liste (render istantaneo al cold start)
- **Reachability** con NWPathMonitor + banner "Offline · dati in cache"
- **Queue di azioni pending** pronta per retry quando la rete torna

### 🛠 Infrastruttura
- Bump v3.0.0 (build 5)
- onboarding 3-slide con AppStorage gate
- Bundle display name: **FirmaCDC**
- 20+ nuovi file swift ben organizzati in Components/, Theme/, Auth/, Networking/

## v2.2.0 — Wave 4 (Camera + OCR + Siri intents)
## v2.1.0 — Wave 3 (Spotlight search + QR share)
## v2.0.0 — Wave 2 (Parallax + Floating tab bar + Illustrations + Onboarding)
## v1.x — Foundation (skeleton, time-of-day, FaceID)

## v1.0.0 — MVP
- Lista pendenti, Sign in with Apple, firma via WebView, verifica blockchain, admin templates
