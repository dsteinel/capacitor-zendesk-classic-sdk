import { WebPlugin } from '@capacitor/core';
import { ZendeskChatPlugin, ChatConfig, VisitorInfo, InitializeOptions, ZendeskTheme } from './definitions';

declare global {
  interface Window {
    zE: any;
    zESettings: any;
  }
}

export class ZendeskChatWeb extends WebPlugin implements ZendeskChatPlugin {
  private jwtEndpointUrl: string | undefined;
  private isJwtAuthenticated = false;

  async initialize(options: InitializeOptions): Promise<void> {
    if (window.zE) {
      console.warn('Zendesk Web: Already initialized.');
      return;
    }

    const key = options.appId;

    if (!key) {
      console.error('Zendesk Web: appId is required for initialization.');
      return;
    }

    this.jwtEndpointUrl = options.jwtEndpointUrl;

    if (options.theme) {
      await this.setTheme(options.theme);
    }

    if (options.locale) {
      await this.setLocale({ locale: options.locale });
    }

    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.type = 'text/javascript';
      script.id = 'ze-snippet';
      script.async = true;
      // Use the resolved webKey or appId
      script.src = `https://static.zdassets.com/ekr/snippet.js?key=${key}`;
      
      script.onload = () => {
        if (window.zE) {
          window.zE('webWidget', 'hide');
        }
        resolve();
      };

      script.onerror = (e) => {
        console.error('Zendesk Web: Failed to load snippet. Check your webKey or appId.', e);
        reject(e);
      };

      document.head.appendChild(script);
    });
  }

  async setTheme(theme: ZendeskTheme): Promise<void> {
    if (theme.primaryColor) {
      window.zESettings = {
        ...window.zESettings,
        webWidget: {
          ...window.zESettings?.webWidget,
          color: {
            theme: theme.primaryColor,
            launcher: theme.primaryColor, // Ensure launcher also reflects the theme
          }
        }
      };
      
      if (window.zE) {
        window.zE('webWidget', 'updateSettings', window.zESettings);
      }
    }
  }

  async setLocale(options: { locale: string }): Promise<void> {
    window.zESettings = {
      ...window.zESettings,
      webWidget: {
        ...window.zESettings?.webWidget,
        locale: options.locale
      }
    };
    
    if (window.zE) {
      window.zE('webWidget', 'updateSettings', window.zESettings);
      window.zE('webWidget', 'setLocale', options.locale);
    }
  }

  async open(config: ChatConfig): Promise<void> {
    if (!window.zE) {
      console.error('Zendesk not initialized. Call initialize() first.');
      return;
    }

    this.applyConfig(config);
    window.zE('webWidget', 'show');
    window.zE('webWidget', 'open');
  }

  async openHelpCenter(config: ChatConfig): Promise<void> {
    if (!window.zE) {
      console.error('Zendesk not initialized. Call initialize() first.');
      return;
    }

    this.applyConfig(config);
    window.zE('webWidget', 'show');
    window.zE('webWidget', 'open');
  }

  async openTicketList(): Promise<void> {
    if (window.zE) {
      window.zE('webWidget', 'show');
      window.zE('webWidget', 'open');
    }
  }

  async createTicket(): Promise<void> {
    if (window.zE) {
      window.zE('webWidget', 'show');
      window.zE('webWidget', 'open');
    }
  }

  private applyConfig(config: ChatConfig) {
    if (config.department) {
      window.zE('webWidget', 'updateSettings', {
        webWidget: {
          chat: {
            departments: {
              enabled: [config.department],
              select: config.department
            }
          }
        }
      });
    }

    if (config.tags && config.tags.length > 0) {
      window.zE('webWidget', 'updateSettings', {
        webWidget: {
          chat: {
            tags: config.tags
          }
        }
      });
    }
  }

  async registerPushToken(_options: { token: string }): Promise<void> {
    // Push notifications are not applicable on web
    console.warn('Zendesk Web: registerPushToken is not supported on web.');
  }

  async handleNotification(_options: {
    data: Record<string, string>;
  }): Promise<{ isZendeskNotification: boolean; wasHandled: boolean }> {
    // Push notifications are not applicable on web
    return { isZendeskNotification: false, wasHandled: false };
  }

  async isLiveChatEnabled(): Promise<{ enabled: boolean }> {
    return { enabled: true };
  }

  async getUnreadCount(): Promise<{ count: number }> {
    // On web the Zendesk messenger widget manages its own unread count via the
    // 'messenger:on unreadMessages' event. There is no synchronous query API.
    return { count: 0 };
  }

  async setVisitorInfo(visitorData: VisitorInfo): Promise<void> {
    if (!window.zE) {
      console.error('Zendesk not initialized. Call initialize() first.');
      return;
    }

    // Skip anonymous prefill when JWT auth is active — the JWT payload is the
    // source of truth and calling identify() here would override it.
    if (this.isJwtAuthenticated) {
      return;
    }

    window.zE('webWidget', 'identify', {
      name: visitorData.name,
      email: visitorData.email,
      phone: visitorData.phoneNumber
    });

    window.zE('webWidget', 'prefill', {
      name: {
        value: visitorData.name,
        readOnly: true
      },
      email: {
        value: visitorData.email,
        readOnly: true
      },
      phone: {
        value: visitorData.phoneNumber,
        readOnly: true
      }
    });
  }

  async authenticateUser(options: { userToken: string }): Promise<void> {
    if (!this.jwtEndpointUrl) {
      console.error('Zendesk Web: jwtEndpointUrl is required for JWT auth. Pass it in initialize().');
      return;
    }

    const endpointUrl = this.jwtEndpointUrl;

    // jwtFn is called by the widget whenever it needs a fresh token.
    // The callback receives a function to call with the signed JWT string.
    const jwtFn = (callback: (jwt: string) => void) => {
      fetch(endpointUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `user_token=${encodeURIComponent(options.userToken)}`,
      })
        .then(res => {
          if (!res.ok) throw new Error(`JWT endpoint returned ${res.status}`);
          return res.json();
        })
        .then((body: { jwt: string }) => callback(body.jwt))
        .catch(err => console.error('Zendesk Web: JWT fetch failed', err));
    };

    window.zESettings = {
      ...window.zESettings,
      webWidget: {
        ...window.zESettings?.webWidget,
        authenticate: { jwtFn },
      },
    };

    if (window.zE) {
      window.zE('webWidget', 'updateSettings', window.zESettings);
    }

    this.isJwtAuthenticated = true;
  }

  async logoutUser(): Promise<void> {
    this.isJwtAuthenticated = false;

    if (window.zE) {
      window.zE('webWidget', 'logout');
    }
  }
}
