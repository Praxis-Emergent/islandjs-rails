import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'
import fs from 'fs'

// IslandJS Rails - Islands Architecture Build Configuration
// This config builds React components as IIFE bundles for use in ERB templates
// Separate from your main Vite build (Inertia, etc.)

export default defineConfig({
  plugins: [react()],
  
  // CRITICAL: Disable copying public/ directory into build output
  // Prevents Vite from copying public/vendor/islands → public/islands/vendor/islands
  // We want vendor files to stay ONLY in public/vendor/islands (single source of truth)
  publicDir: false,
  
  // Define global constants for browser (replace Node.js process.env)
  // CRITICAL: These must be string replacements, not JSON objects
  define: {
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'production'),
  },
  
  build: {
    // Library mode for IIFE output
    lib: {
      entry: path.resolve(__dirname, 'app/javascript/entrypoints/islands.js'),
      name: 'islandjsRails',
      formats: ['iife'],
      // Don't specify fileName here - let rollupOptions handle it
      fileName: 'islands_bundle'
    },
    
    // Externalize React - loaded via UMD from CDN
    rollupOptions: {
      external: ['react', 'react-dom'],
      output: {
        globals: {
          react: 'React',
          'react-dom': 'ReactDOM'
        },
        // Use [hash] for content-based fingerprinting (auto cache-busting)
        // This ensures every build change gets a new filename
        entryFileNames: 'islands_bundle.[hash].js',
        chunkFileNames: 'chunks/[name].[hash].js',
        assetFileNames: 'assets/[name].[hash][extname]'
      }
    },
    
    // Output to public/islands directory
    outDir: 'public/islands',
    // Clean output directory (vendor files are in public/vendor/islands, separate)
    emptyOutDir: true,
    
    // Generate manifest for Rails helpers (critical for fingerprinting!)
    manifest: true,
    
    // Source maps for development
    sourcemap: process.env.NODE_ENV !== 'production'
  },
  
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'app/javascript')
    }
  }
})
