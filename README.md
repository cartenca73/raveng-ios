# RAVENG iOS

App nativa iOS (Swift / SwiftUI) per il sistema di firma digitale RAVENG.it / docusign.ce4u.it.

## Caratteristiche

- **Sign in with Apple** per autenticazione sicura
- **3 sezioni**: Firmatario, Amministratore, Verifica pubblica
- **Apple Pay (PassKit)** per pagamento certificazione CDC + fallback carta
- **PencilKit** per firma autografa
- **PDFKit** per anteprima documenti
- **Verifica blockchain** documenti (OpenTimestamps su Bitcoin)
- Design WOW: gradient azzurro, glass morphism, spring animations, haptic feedback

## Requisiti

- iOS 17.0+
- Xcode 15.0+
- Apple Developer Account (per Apple Pay + Sign in with Apple + TestFlight)

## Setup

Il progetto Xcode è generato tramite [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
cd /opt/raveng-ios
xcodegen generate
open Raveng.xcodeproj
```

## Struttura

```
Raveng/
├── App/            # Entry point + AppState + RootView
├── Theme/          # Colori, font, gradient, haptics
├── Models/         # Modelli dati (User, Submission, ...)
├── Networking/     # APIClient, Keychain, errori
├── Auth/           # Welcome, SIWA, Login fallback
├── Signer/         # Lista pendenti, dettaglio, firma, payment Apple Pay
├── Admin/          # Dashboard, templates, submissions
├── Verify/         # Verifica pubblica blockchain
├── Components/     # UI riusabili (GradientButton, Card, ...)
└── Resources/      # Info.plist, entitlements, Assets.xcassets
```

## Backend API

Base URL: `https://docusign.ce4u.it/api/app/v1`

Endpoints principali:
- `POST /auth/apple_sign_in`
- `GET  /signer/pending`
- `POST /cdc/:slug/apple_pay/merchant_validation`
- `POST /cdc/:slug/apple_pay/process`
- `POST /verify/blockchain`

Tutti gli endpoint autenticati richiedono `Authorization: Bearer <jwt>`.

## Branding

- Brand: **RAVENG.it**
- Colori: `#0f4c75` (deep blue) → `#1b6ca8` (mid) → `#3b82f6` (bright)
- Accent: `#06b6d4` (cyan)
