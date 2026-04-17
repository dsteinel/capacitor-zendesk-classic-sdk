# Capacitor Zendesk Support SDK (Classic)

Capacitor plugin for integrating the **Zendesk Support SDK (Classic/Unified)** into your cross-platform apps.

## Features

- **Capacitor 8 Support**: Fully compatible with the latest Capacitor version.
- **Native UI**: Uses Zendesk's native UI components for iOS and Android.
- **Support SDK Suite**:
  - Help Center (Knowledge Base)
  - Ticket List (User Requests)
  - Ticket Creation (Contact Us Form)
  - Unified Messaging interface.
- **Web Support**: Integrates with the Zendesk Web Widget (Classic).

## Installation

```bash
npm install capacitor-zendesk-classic-sdk
npx cap sync
```

### Android Configuration

In your **app's** `build.gradle` or `settings.gradle`, add the Zendesk Maven repository:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://zendesk.jfrog.io/zendesk/repo' }
    }
}
```

### iOS Configuration

In Capacitor 8, the plugin is automatically linked via Swift Package Manager (SPM). No additional steps are required beyond `npx cap sync ios`.

---

## Usage

### 1. Initialization

Initialize the SDK with your Zendesk credentials. You can find these in your Zendesk Admin Center under **Channels > Classic > Mobile SDK**.

```typescript
import { ZendeskChat } from 'capacitor-zendesk-classic-sdk';

await ZendeskChat.initialize({
  appId: 'YOUR_APP_ID',
  clientId: 'mobile_sdk_client_YOUR_CLIENT_ID',
  zendeskUrl: 'https://your_domain.zendesk.com'
});
```

### 2. Set Visitor Identity

Identify the user so their tickets are correctly linked.

```typescript
await ZendeskChat.setVisitorInfo({
  name: 'John Doe',
  email: 'john@example.com'
});
```

### 3. Launch UI Components

```typescript
// Open the Help Center
await ZendeskChat.openHelpCenter({});

// Open the Ticket List (My Requests)
await ZendeskChat.openTicketList();

// Open the Ticket Creation form
await ZendeskChat.createTicket();

// Open the Unified Messaging/Chat UI
await ZendeskChat.open({});
```

---

## Branding & Customization

You can customize the **Primary Color** and **Language (Locale)** during initialization or dynamically at runtime.

### 1. During Initialization

```typescript
await ZendeskChat.initialize({
  appId: '...',
  clientId: '...',
  zendeskUrl: '...',
  theme: {
    primaryColor: '#8a2be2' // Hex color code
  },
  locale: 'fr-FR' // BCP 47 language tag (e.g., 'en-US', 'fr-FR')
});
```

### 2. Dynamically Update at Runtime

```typescript
// Update the primary branding color (iOS and Web only)
await ZendeskChat.setTheme({ primaryColor: '#3880ff' });

// Update the language/locale (iOS, Android, and Web)
await ZendeskChat.setLocale({ locale: 'en-US' });
```

> **Note for Android**: Programmatic color customization is limited on the Android Classic/Unified SDK. For Android branding, please customize your app's `styles.xml` to target Zendesk's activity themes.

### Help Center Article Styling

You can customize the appearance of articles in the Help Center by adding a file named **`help_center_article_style.css`** to your native projects. The SDK automatically detects and applies this file to the native WebView.

- **Android**: Place the file in `src/main/assets/help_center_article_style.css`.
- **iOS**: Place the file in your app's root folder and add it to your Xcode project's **"Copy Bundle Resources"** build phase.

---

## Example Project

A complete **Ionic React** example project is available in the `/example` directory.

### Where to add your API Keys
Open `example/src/pages/Home.tsx` and replace the placeholders:
- `YOUR_APP_ID`
- `mobile_sdk_client_YOUR_CLIENT_ID`
- `https://your_domain.zendesk.com`

### How to run the example

1.  **Setup**:
    ```bash
    cd example
    npm install
    ```

2.  **Web**:
    ```bash
    npm run dev
    ```

3.  **iOS**:
    ```bash
    npm run dev:ios
    ```

4.  **Android**:
    ```bash
    npm run dev:android
    ```

---

## Integration in another project

To use this plugin in your own Ionic React project:

1.  **Add the plugin**:
    ```bash
    npm install capacitor-zendesk-classic-sdk
    ```
2.  **Sync native platforms**:
    ```bash
    npx cap sync
    ```
3.  **Import and use**:
    ```typescript
    import { ZendeskChat } from 'capacitor-zendesk-classic-sdk';
    
    // ... inside your component
    const handleSupport = async () => {
      await ZendeskChat.initialize({ ... });
      await ZendeskChat.openHelpCenter({});
    };
    ```
