import { WebPlugin } from '@capacitor/core';
import { ZendeskChatPlugin, ChatConfig, VisitorInfo, InitializeOptions, ZendeskTheme } from './definitions';

declare global {
  interface Window {
    zE: any;
    zESettings: any;
  }
}

export class ZendeskChatWeb extends WebPlugin implements ZendeskChatPlugin {
  async initialize(options: InitializeOptions): Promise<void> {
    if (window.zE) {
      console.warn('Zendesk Web: Already initialized.');
      return;
    }

    const key = options.webKey || options.appId;

    if (!key) {
      console.error('Zendesk Web: webKey (or appId) is required for initialization.');
      return;
    }

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
}
