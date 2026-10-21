// @ts-check
import { defineConfig, fontProviders } from "astro/config";

import tailwindcss from "@tailwindcss/vite";

import sitemap from "@astrojs/sitemap";

// https://astro.build/config
export default defineConfig({
  output: "static",
  site: "https://tryphp.dev",
  integrations: [sitemap()],
  // Downloaded at build time and served from tryphp.dev.
  fonts: [
    {
      provider: fontProviders.google(),
      name: "Geist",
      cssVariable: "--font-geist",
      weights: [400, 500, 600, 700],
      subsets: ["latin"],
      fallbacks: ["ui-sans-serif", "system-ui", "sans-serif"],
    },
    {
      provider: fontProviders.google(),
      name: "Geist Mono",
      cssVariable: "--font-geist-mono",
      weights: [400, 500],
      subsets: ["latin"],
      fallbacks: ["ui-monospace", "SFMono-Regular", "Menlo", "monospace"],
    },
  ],
  vite: {
    plugins: [tailwindcss()],
  },
});
