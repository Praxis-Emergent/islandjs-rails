#!/usr/bin/env node

/**
 * IslandJS Rails - Atomic Vite Build Script
 * 
 * Builds both Inertia (if present) and Islands bundles atomically.
 * If either build fails, the entire operation fails.
 * 
 * Usage: node script/build-vite-atomic.js
 * Or via package.json: yarn build
 */

import { execSync } from 'child_process'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const rootDir = path.join(__dirname, '..')

// Check if a file exists
function fileExists(filepath) {
  try {
    return fs.existsSync(path.join(rootDir, filepath))
  } catch {
    return false
  }
}

// Execute command and handle errors
function exec(command, description) {
  console.log(`\n📦 ${description}...`)
  try {
    execSync(command, {
      cwd: rootDir,
      stdio: 'inherit',
      env: process.env
    })
    console.log(`✅ ${description} succeeded`)
    return true
  } catch (error) {
    console.error(`❌ ${description} failed`)
    throw error
  }
}

async function buildAtomic() {
  console.log('🏗️  Building Vite assets atomically...\n')
  
  const hasInertia = fileExists('vite.config.ts')
  const hasIslands = fileExists('vite.config.islands.ts')
  
  if (!hasInertia && !hasIslands) {
    console.error('❌ No Vite configs found!')
    console.error('   Expected: vite.config.ts or vite.config.islands.ts')
    process.exit(1)
  }
  
  try {
    // Build Inertia if config exists
    if (hasInertia) {
      exec('vite build --emptyOutDir', 'Building Inertia assets')
    }
    
    // Build Islands if config exists
    if (hasIslands) {
      exec('vite build --config vite.config.islands.ts', 'Building Islands bundle')
    }
    
    console.log('\n🎉 All builds succeeded!')
    console.log('\n📦 Built assets:')
    
    if (hasInertia) {
      console.log('   ✓ Inertia: public/vite-dev/')
    }
    if (hasIslands) {
      console.log('   ✓ Islands: public/islands/')
    }
    
    process.exit(0)
    
  } catch (error) {
    console.error('\n❌ Build failed!')
    console.error('   No changes were deployed (atomic guarantee)')
    process.exit(1)
  }
}

buildAtomic()
