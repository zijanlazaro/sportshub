import { defineConfig } from 'vite'

export default defineConfig({
  server: {
    port: 3000,
    open: true
  },
  build: {
    outDir: 'dist',
    minify: 'terser'
  },
  cacheDir: 'C:\\Users\\ACER\\AppData\\Local\\vite-cache',
  optimizeDeps: {
    include: ['@supabase/supabase-js']
  }
})
