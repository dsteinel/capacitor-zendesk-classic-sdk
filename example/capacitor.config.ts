import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.bsdex.capacitor-zendesk-classic-sdk.example',
  appName: 'example-app',
  webDir: 'dist',
  server: {
    androidScheme: 'https'
  }
};

export default config;
