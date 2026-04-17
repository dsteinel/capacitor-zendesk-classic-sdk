import { registerPlugin } from '@capacitor/core';
import type { ZendeskChatPlugin } from './definitions';

const ZendeskChat = registerPlugin<ZendeskChatPlugin>('ZendeskChat', {
  web: () => import('./web').then(m => new m.ZendeskChatWeb()),
});

export * from './definitions';
export { ZendeskChat };
