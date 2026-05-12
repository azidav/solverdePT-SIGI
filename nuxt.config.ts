// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: [
    "@nuxt/eslint",
    "@nuxt/ui",
    "@vueuse/nuxt",
    "@pinia/nuxt",
    "@vite-pwa/nuxt",
  ],

  runtimeConfig: {
    // Private config (only available server-side)
    databaseUrl: process.env.DATABASE_URL,
    // Public config if needed (but DB URL usually private)
    public: {},
  },

  devtools: {
    enabled: true,
  },

  css: ["~/assets/css/main.css"],

  routeRules: {
    "/api/**": {
      cors: true,
    },
  },

  app: {
    head: {
      titleTemplate: "%s | SolverdePT",
      htmlAttrs: { lang: "pt" },
      link: [{ rel: "manifest", href: "/manifest.webmanifest" }],
    },
  },

  pwa: {
    strategies: "generateSW",
    registerType: "autoUpdate",
    manifest: {
      name: "Sistema Integrado de Gestão Interna - SolverdePT",
      short_name: "Sigi-SolverdePT",
      description: "Sistema Integrado de Gestão Interna — SolverdePT",
      theme_color: "#00C16A",
      background_color: "#ffffff",
      display: "standalone",
      icons: [
        {
          src: "icons/android/mipmap-xxxhdpi/ic_launcher.png",
          sizes: "192x192",
          type: "image/png",
        },
        {
          src: "icons/playstore.png",
          sizes: "512x512",
          type: "image/png",
        },
      ],
    },
    workbox: {
      navigateFallback: null,
      runtimeCaching: [],
    },
    devOptions: {
      enabled: true,
      suppressWarnings: true,
      type: "module",
    },
  },

  compatibilityDate: "2024-07-11",

  eslint: {
    config: {
      stylistic: {
        commaDangle: "never",
        braceStyle: "1tbs",
      },
    },
  },
});
