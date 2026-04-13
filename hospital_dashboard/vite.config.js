import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',   // New version installs silently on next visit
      includeAssets: ['favicon.ico'],
      manifest: {
        name: 'SalamaRecover — Hospital Dashboard',
        short_name: 'SalamaRecover',
        description: 'Clinical dashboard for monitoring post-surgical patients in Kenya',
        theme_color: '#2563eb',       // Blue — matches the dashboard header
        background_color: '#f9fafb',  // Gray-50 — matches page background
        display: 'standalone',        // Opens in its own window, no browser chrome
        orientation: 'any',
        scope: '/',
        start_url: '/',
        icons: [
          {
            src: 'icon-192.png',
            sizes: '192x192',
            type: 'image/png',
            purpose: 'any maskable',
          },
          {
            src: 'icon-512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'any maskable',
          },
        ],
      },
      workbox: {
        // Cache the app shell and static assets for fast loading
        globPatterns: ['**/*.{js,css,html,ico,png,svg}'],
        // Don't cache API calls — always fetch fresh clinical data
        navigateFallback: '/index.html',
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/.*\/api\//,
            handler: 'NetworkOnly',   // API = always live, never cached
          },
        ],
      },
    }),
  ],
  server: {
    port: 3000,
  },
});
