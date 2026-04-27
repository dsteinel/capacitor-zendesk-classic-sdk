export interface ChatConfig {
    tags?: string[];
    department?: string;
}
export interface VisitorInfo {
    name?: string;
    email?: string;
    phoneNumber?: string;
}
export interface ZendeskTheme {
    primaryColor?: string;
}
export interface InitializeOptions {
    appId: string;
    clientId: string;
    zendeskUrl: string;
    theme?: ZendeskTheme;
    locale?: string;
    /** Set to false to hide the live chat option in your UI. Defaults to true. */
    enableLiveChat?: boolean;
}
export interface ZendeskChatPlugin {
    initialize(options: InitializeOptions): Promise<void>;
    isLiveChatEnabled(): Promise<{
        enabled: boolean;
    }>;
    setVisitorInfo(visitorInfo: VisitorInfo): Promise<void>;
    setTheme(theme: ZendeskTheme): Promise<void>;
    setLocale(options: {
        locale: string;
    }): Promise<void>;
    open(config: ChatConfig): Promise<void>;
    openHelpCenter(config: ChatConfig): Promise<void>;
    openTicketList(options?: {
        primaryColor?: string;
    }): Promise<void>;
    createTicket(): Promise<void>;
    registerPushToken(options: {
        token: string;
    }): Promise<void>;
    /**
     * Forward a received push notification payload to the Zendesk SDK.
     *
     * Returns whether the notification originated from Zendesk (`isZendeskNotification`)
     * and whether the native SDK was already initialised and handled the UI itself
     * (`wasHandled`). When `wasHandled` is false the caller should navigate to the
     * Support page so Zendesk can be initialised and the ticket/chat UI can be opened.
     */
    handleNotification(options: {
        data: Record<string, string>;
    }): Promise<{
        isZendeskNotification: boolean;
        wasHandled: boolean;
    }>;
    /**
     * Returns the total number of unread agent comments across all open requests
     * for the current device/identity, using the SDK's built-in `getUpdatesForDevice`
     * API. Results are cached by the SDK for up to one hour.
     *
     * Returns `{ count: 0 }` when the SDK is not yet initialised or on web.
     */
    getUnreadCount(): Promise<{
        count: number;
    }>;
}
