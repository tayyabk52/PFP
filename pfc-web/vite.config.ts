import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'prompt',
      workbox: {
        // Precaches all static shell assets automatically — no runtime rule needed for these
        globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],
        runtimeCaching: [
          {
            // Supabase REST API — network first, 5s timeout, fallback to cache
            urlPattern: /^https:\/\/[a-z0-9]+\.supabase\.co\/rest\//,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'supabase-api',
              networkTimeoutSeconds: 5,
              expiration: { maxEntries: 100, maxAgeSeconds: 60 * 5 },
            },
          },
          {
            // Supabase Storage CDN images — cache first, long-lived
            urlPattern: /^https:\/\/[a-z0-9]+\.supabase\.co\/storage\//,
            handler: 'CacheFirst',
            options: {
              cacheName: 'listing-images',
              expiration: { maxEntries: 200, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
        ],
      },
      manifest: {
        name: 'PFC — The Olfactory Archive',
        short_name: 'PFC',
        description: "Pakistan's premier fragrance marketplace — buy, sell, and discover perfumes",
        theme_color: '#003527',
        background_color: '#ffffff',
        display: 'standalone',
        start_url: '/',
        scope: '/',
        icons: [
          { src: '/pwa-192x192.png', sizes: '192x192', type: 'image/png' },
          { src: '/pwa-512x512.png', sizes: '512x512', type: 'image/png' },
          {
            src: '/pwa-maskable-512x512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'maskable',
          },
        ],
        screenshots: [
          {
            src: '/screenshots/marketplace.png',
            sizes: '390x844',
            type: 'image/png',
            // @ts-ignore – 'form_factor' is valid per spec but not yet in typings
            form_factor: 'narrow',
          },
          {
            src: '/screenshots/listing.png',
            sizes: '390x844',
            type: 'image/png',
            // @ts-ignore
            form_factor: 'narrow',
          },
        ],
      },
    }),
  ],
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
})
