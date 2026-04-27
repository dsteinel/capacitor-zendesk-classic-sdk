<p align="center">
  <img src="./logo.svg" alt="Logo" height="120" />
</p>

<h1 align="center">Capacitor Zendesk Classic SDK</h1>

<p align="center">
  <a href="https://www.npmjs.com/package/capacitor-zendesk-classic-sdk"><img src="https://img.shields.io/npm/v/capacitor-zendesk-classic-sdk" alt="npm version" /></a>
  <img src="https://img.shields.io/npm/l/capacitor-zendesk-classic-sdk" alt="license" />
  <img src="https://img.shields.io/badge/capacitor-8-blue" alt="Capacitor 8" />
  <img src="https://img.shields.io/badge/platforms-iOS%20%7C%20Android%20%7C%20Web-success" alt="platforms" />
</p>

<div align="center">
  <a href="#installation">Installation</a>
  <span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
  <a href="#usage">Usage</a>
  <span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
  <a href="#api">API</a>
  <span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
  <a href="https://github.com/dsteinel/capacitor-zendesk-classic-sdk/issues">Issues</a>
</div>

---

Capacitor 8 plugin for integrating the **Zendesk Support SDK (Classic/Unified)** into iOS, Android, and Web apps — using Zendesk's native UI components.

**Features:** Help Center · Ticket List · Ticket Creation · Unified Messaging · Push Notifications · Theme & Locale customization

## Requirements

| Platform  | Minimum        |
|-----------|----------------|
| iOS       | 17.0           |
| Android   | SDK 24 (7.0)   |
| Capacitor | 8              |

---

## Installation

```bash
npm install capacitor-zendesk-classic-sdk
npx cap sync
```

### Android

Add the Zendesk Maven repository to `android/build.gradle`:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://zendesk.jfrog.io/zendesk/repo' }
    }
}
```

### iOS

Automatically linked via Swift Package Manager — no extra steps after `npx cap sync`.

---

## Usage

### Initialize

Call once on app start. Get credentials from Zendesk Admin Center → **Channels > Classic > Mobile SDK**.

```typescript
import { ZendeskChat } from 'capacitor-zendesk-classic-sdk';

await ZendeskChat.initialize({
  appId: 'YOUR_APP_ID',
  clientId: 'YOUR_CLIENT_ID',
  zendeskUrl: 'https://your_domain.zendesk.com',
  enableLiveChat: false, // set to false to hide the live chat option in your UI
});
```

### Identify the user

```typescript
await ZendeskChat.setVisitorInfo({
  name: 'Jane Doe',
  email: 'jane@example.com',
});
```

### Open UI components

```typescript
await ZendeskChat.openHelpCenter({});  // Knowledge Base
await ZendeskChat.open({});            // Unified Messaging / Chat
await ZendeskChat.openTicketList();    // My Requests
await ZendeskChat.createTicket();      // New Ticket form
```

#### Per-call color override (iOS only)

`openTicketList` accepts an optional `primaryColor` that overrides the color set via `initialize` or `setTheme` for that screen:

```typescript
await ZendeskChat.openTicketList({ primaryColor: '#006e25' });
```

If omitted the color from `initialize({ theme: { primaryColor } })` is used as the fallback.

---

## API

| Method | Description |
|--------|-------------|
| `initialize(options)` | Initialize the SDK with credentials |
| `isLiveChatEnabled()` | Returns `{ enabled: boolean }` — reflects the `enableLiveChat` flag passed to `initialize` |
| `setVisitorInfo(options)` | Identify the current user |
| `open(options)` | Open the Unified Messaging UI |
| `openHelpCenter(options)` | Open the Help Center |
| `openTicketList(options?)` | Open the user's ticket list (iOS: optional `primaryColor` override) |
| `createTicket()` | Open the new ticket form |
| `setTheme(options)` | Set primary color — iOS & Web only (Android: use `styles.xml`) |
| `setLocale(options)` | Set language (BCP 47 tag) |
| `registerPushToken(options)` | Register device push token |
| `handleNotification(options)` | Handle incoming push notification |

---

## Branding & Localization

```typescript
// Set during initialization
await ZendeskChat.initialize({
  // ...credentials
  theme: { primaryColor: '#3880ff' }, // hex color
  locale: 'de-DE',                    // BCP 47 language tag
});

// Or update at runtime
await ZendeskChat.setTheme({ primaryColor: '#3880ff' }); // iOS & Web only
await ZendeskChat.setLocale({ locale: 'en-US' });
```

> **Android**: `setTheme()` is not supported programmatically. Use `styles.xml` targeting Zendesk's activity themes instead.

### Help Center article CSS

Place `help_center_article_style.css` in:
- **Android**: `src/main/assets/`
- **iOS**: app root, added to Xcode's **Copy Bundle Resources** build phase

---

## Push Notifications

```typescript
// Register device token (from your push notification plugin)
await ZendeskChat.registerPushToken({ token: 'DEVICE_TOKEN' });

// In your notification handler
const { wasHandled } = await ZendeskChat.handleNotification({ payload });
if (!wasHandled) {
  // Handle non-Zendesk notification yourself
}
```

---

## Example Project

A working Ionic React example is in [`/example`](./example).

1. Open `example/src/pages/Home.tsx` and replace the credential placeholders.
2. Run:

```bash
cd example && npm install
npm run start            # Web
npm run start:ios        # iOS
npm run start:android    # Android
```
