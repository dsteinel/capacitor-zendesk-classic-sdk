import { registerPlugin } from '@capacitor/core';
const ZendeskChat = registerPlugin('ZendeskChat', {
    web: () => import('./web').then(m => new m.ZendeskChatWeb()),
});
export * from './definitions';
export { ZendeskChat };
//# sourceMappingURL=index.js.map