import { WebPlugin } from '@capacitor/core';
import { ZendeskChatPlugin, ChatConfig, VisitorInfo, InitializeOptions, ZendeskTheme } from './definitions';
declare global {
    interface Window {
        zE: any;
        zESettings: any;
    }
}
export declare class ZendeskChatWeb extends WebPlugin implements ZendeskChatPlugin {
    initialize(options: InitializeOptions): Promise<void>;
    setTheme(theme: ZendeskTheme): Promise<void>;
    setLocale(options: {
        locale: string;
    }): Promise<void>;
    open(config: ChatConfig): Promise<void>;
    openHelpCenter(config: ChatConfig): Promise<void>;
    openTicketList(): Promise<void>;
    createTicket(): Promise<void>;
    private applyConfig;
    registerPushToken(_options: {
        token: string;
    }): Promise<void>;
    handleNotification(_options: {
        data: Record<string, string>;
    }): Promise<{
        isZendeskNotification: boolean;
        wasHandled: boolean;
    }>;
    isLiveChatEnabled(): Promise<{
        enabled: boolean;
    }>;
    getUnreadCount(): Promise<{
        count: number;
    }>;
    setVisitorInfo(visitorData: VisitorInfo): Promise<void>;
}
