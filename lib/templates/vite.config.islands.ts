import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// IslandJS Rails - Build Configuration
// Builds React components as IIFE bundles for use in Rails ERB templates

export default defineConfig({
  plugins: [react()],

  publicDir: false,

  define: {
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'production'),
  },

  build: {
    lib: {
      entry: path.resolve(__dirname, 'app/javascript/entrypoints/islands.js'),
      name: 'islandjsRails',
      formats: ['iife'],
      fileName: 'islands_bundle'
    },

    rollupOptions: {
      output: {
        entryFileNames: 'islands_bundle.[hash].js',
        chunkFileNames: 'chunks/[name].[hash].js',
        assetFileNames: 'assets/[name].[hash][extname]'
      }
    },

    outDir: 'public/islands',
    emptyOutDir: true,
    manifest: true,
    sourcemap: process.env.NODE_ENV !== 'production'
  },

  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'app/javascript')
    }
  }
})
