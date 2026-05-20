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
  primaryColor?: string; // Hex string, e.g., "#FF0000"
}

export interface InitializeOptions {
  appId: string;
  clientId: string;
  zendeskUrl: string;
  theme?: ZendeskTheme;
  locale?: string;
  /** Set to false to hide the live chat option in your UI. Defaults to true. */
  enableLiveChat?: boolean;
  /**
   * HTTPS URL of your backend endpoint that exchanges a userToken for a
   * Zendesk-compatible signed JWT (web only). Required if you call
   * authenticateUser() on the web platform.
   *
   * Your endpoint must accept POST with body `user_token=<value>` and respond
   * with `{ "jwt": "<hs256-signed-token>" }`.
   */
  jwtEndpointUrl?: string;
}

export interface ZendeskChatPlugin {
  initialize(options: InitializeOptions): Promise<void>;
  isLiveChatEnabled(): Promise<{ enabled: boolean }>;
  setVisitorInfo(visitorInfo: VisitorInfo): Promise<void>;
  setTheme(theme: ZendeskTheme): Promise<void>;
  setLocale(options: { locale: string }): Promise<void>;
  open(config: ChatConfig): Promise<void>; // Opens Messaging/Chat
  openHelpCenter(config: ChatConfig): Promise<void>;
  openTicketList(options?: { primaryColor?: string }): Promise<void>;
  createTicket(): Promise<void>;
  registerPushToken(options: { token: string }): Promise<void>;
  /**
   * Authenticate the current user via Zendesk's JWT identity flow so that
   * tickets are unified across devices and platforms.
   *
   * Pass an opaque `userToken` string that your backend can map to a real
   * user and use to sign a Zendesk JWT. On mobile the Zendesk SDK calls your
   * registered JWT endpoint with this token; on web the plugin calls
   * `jwtEndpointUrl` (set in InitializeOptions) directly.
   *
   * Must be called after `initialize()`. Calling it again with a new token
   * refreshes the identity.
   */
  authenticateUser(options: { userToken: string }): Promise<void>;
  /**
   * Sign out the current user and reset to an anonymous Zendesk identity.
   * Call this when the user logs out of your app so their ticket history is
   * no longer accessible on the device.
   */
  logoutUser(): Promise<void>;
  /**
   * Forward a received push notification payload to the Zendesk SDK.
   *
   * Returns whether the notification originated from Zendesk (`isZendeskNotification`)
   * and whether the native SDK was already initialised and handled the UI itself
   * (`wasHandled`). When `wasHandled` is false the caller should navigate to the
   * Support page so Zendesk can be initialised and the ticket/chat UI can be opened.
   */
  handleNotification(options: { data: Record<string, string> }): Promise<{
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
  getUnreadCount(): Promise<{ count: number }>;
}
