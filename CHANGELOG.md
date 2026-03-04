# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-03-03

### ⚠️ BREAKING CHANGES

**React is now bundled directly** into your Islands bundle. The entrypoint template imports React and ReactDOM as regular npm dependencies and exposes them on `window`. No more separate UMD script tags or CDN downloads.

**Removed the entire UMD/vendor system:**
- `rails islandjs:install` — Use `yarn add` instead
- `rails islandjs:update` — Use `yarn upgrade` instead
- `rails islandjs:remove` — Use `yarn remove` instead
- `rails islandjs:sync` — No longer applicable
- `rails islandjs:clean` — No longer applicable
- `rails islandjs:config` — No longer applicable
- `rails islandjs:vendor:*` — Vendor system removed

**Gem no longer manages build configuration.** Bring your own `vite.config.islands.ts` (or use any bundler). The gem scaffolds directory structure, templates, and provides Rails helpers — that's it.

### Changed
- **`rails islandjs:init`**: Now only creates directory structure, entrypoint, Turbo utilities, and injects layout helper
- **`islands` helper**: Just renders the bundle script tag (no more vendor UMD partial)
- **Mount script warnings**: No longer reference `islandjs:install` commands
- **Entrypoint template**: Imports React/ReactDOM directly and exposes on `window`
- **Gemspec**: Updated description to reflect React-focused approach
- **README**: Complete rewrite — focused on React + Turbo, no UMD/vendor documentation

### Removed
- `VendorManager` class and all vendor file management
- `ViteIntegration` class and Vite configuration management
- `vite.config.islands.ts` template (bring your own)
- `package.json` template (bring your own)
- `UMD_PATH_PATTERNS`, `CDN_BASES`, `BUILT_IN_GLOBAL_NAME_OVERRIDES` constants
- All CDN download and UMD resolution functionality
- All Vite externals management
- `island_partials`, `umd_versions_debug`, `umd_partial_for`, `react_partials`, `extra_vendor_tag` helpers
- Vendor configuration options (`vendor_script_mode`, `vendor_order`, `vendor_dir`, etc.)
- Package management methods (`install!`, `update!`, `remove!`, `sync!`, `status!`, `clean!`)

### Migration from 1.x

1. Update your Gemfile: `gem 'islandjs-rails', '~> 2.0'`
2. Add React as a direct dependency: `yarn add react react-dom`
3. Update your entrypoint (`app/javascript/entrypoints/islands.js`) to import React directly — see the README for the pattern
4. Remove `public/vendor/islands/` directory (no longer used)
5. Remove `app/views/shared/islands/` directory (no longer used)
6. Your `react_component` calls in ERB templates work exactly the same — no view changes needed

## [1.1.0] - 2026-01-16

### Removed
- **Vue Support**: Removed untested Vue framework support to keep the gem focused on battle-tested React integration
  - Removed `vue_component` helper method
  - Removed `generate_vue_mount_script` private method
  - Removed Vue global name mapping from `BUILT_IN_GLOBAL_NAME_OVERRIDES`
  - Updated `island_component` helper to only support React
  - Updated documentation to reflect React-only focus

### Changed
- Updated gem description to reflect React-only focus
- Simplified framework support messaging in error messages

### Fixed
- **Ruby 4.0 Compatibility**: Added explicit `cgi` gem dependency for test suite compatibility
  - Ruby 4.0+ extracted `cgi` from stdlib, causing VCR gem to fail
  - Added `cgi` as development dependency to ensure test suite works on Ruby 4.0+
- **Critical: YarnError namespace prefix**: Fixed missing `IslandjsRails::` namespace prefix in YarnError raises
  - Would cause `NameError: uninitialized constant YarnError` at runtime when yarn commands failed
  - Fixed in `core_methods.rb` for add, update, and remove package operations
- **Consistent Rails.root handling**: Added `root_path` helper method for uniform Rails.root access
  - Prevents crashes when gem used outside Rails context (e.g., in standalone scripts)
  - All file operations now use consistent path resolution
- **JSON parsing error visibility**: Added debug logging for JSON parse failures
  - Silent failures made debugging difficult
  - Now logs warnings
  - Affects package.json, manifest.json, and Vite config parsing

## [1.0.0] - 2025-11-05

### 🎉 Major Release: Webpack → Vite Migration

This release replaces webpack with Vite for a dramatically faster, more modern build system.

### ⚠️ BREAKING CHANGES

**Build System**:
- Replaced webpack with Vite as the build tool
- Config file changed: `webpack.config.js` → `vite.config.islands.ts`
- Build command changed: `yarn build` → `yarn build:islands`
- Watch command changed: `yarn watch` → `yarn watch:islands`
- Manifest location changed: `public/islands_manifest.json` → `public/islands/.vite/manifest.json`

**Dependencies**:
- Removed: `webpack`, `webpack-cli`, `webpack-manifest-plugin`
- Added: `vite`, `@vitejs/plugin-react`
- Note: Uses Vite directly via npm/yarn, not the `vite_rails` Ruby gem

**Files**:
- `app/javascript/islands/index.js` is no longer created (Vite uses entrypoints directly)
- New file: `vite.config.islands.ts` for Islands-specific Vite configuration

### ✅ What Stays the Same

**No code changes needed!** All runtime APIs remain identical:
- All Rails helpers work the same (`react_component`, `island_partials`, etc.)
- Island components don't need any changes
- ERB templates don't need any changes
- UMD vendor system works identically
- All `rails islandjs:*` commands work the same way

### 🚀 Benefits

- ⚡ **2-10x faster builds** compared to webpack
- 🔥 **Instant Hot Module Replacement (HMR)** during development
- 📦 **Smaller bundle sizes** with superior tree-shaking
- 🎯 **Simpler configuration** - no complex webpack setup needed
- 🌐 **Modern tooling** - built for ES modules and modern JavaScript
- 🔧 **Lightweight integration** - uses Vite directly without additional Ruby dependencies

### 📚 Upgrade Guide

See [UPGRADING.md](UPGRADING.md) for detailed migration instructions. Summary:

1. Update gem: `bundle update islandjs-rails`
2. Remove webpack files: `rm webpack.config.js`
3. Reinitialize: `rails islandjs:init`
4. Rebuild: `yarn build:islands`

### Changed

- Updated all documentation to reference Vite instead of webpack
- CLI and Rake task descriptions now mention "Vite externals" instead of "webpack externals"
- Build output messages updated for Vite workflow
- Error messages and hints updated to reference Vite commands

### Removed

- Webpack configuration template
- Webpack-related dependencies from package.json template
- `ESSENTIAL_DEPENDENCIES` constant (replaced with inline Vite deps)
- References to webpack in README, gemspec, and all documentation

## [0.7.0] - 2025-10-27

### Added
- **CleanIslandsPlugin**: Build plugin that automatically removes old island bundle files from the public directory after new builds, preventing stale file accumulation
- Simplified build scripts by removing manual cleanup commands

## [0.6.0] - 2025-10-24

- **React 19 Support Added**
- **Enhanced version parsing** in `cdn_package_name` with nil/empty string handling and exception safety
- **SSL certificate issues** with improved fallback mechanism for CDN downloads

## [0.5.0] - 2025-09-29

### Added
- **CSP support for script tags**: All IslandJS-generated `<script>` tags now automatically include a CSP nonce when one is present in the Rails request.
- **Flexible script attributes**: Helpers (`react_component`, etc.) now support passing standard script attributes (`nonce`, `defer`, `async`, `crossorigin`, `integrity`).

## [0.4.0] - 2025-08-10

### Added
- Add ENV flag to control the dev UMD bundle info footer. The floating footer is disabled by default and only shows in development when `ISLANDJS_RAILS_SHOW_UMD_DEBUG` is truthy.

## [0.3.0] - 2025-08-09

### Added
- **Vendor Script Helper**: New `extra_vendor_tag` helper method for including third-party JavaScript libraries from the vendor directory
- **Enhanced Package Template**: Updated `lib/templates/package.json` with improved webpack configuration and dependencies

### Enhanced
- Simplified vendor asset integration with automatic Turbo tracking
- Better support for third-party library inclusion in Rails applications

## [0.2.1] - 2025-08-06

### Fixed
- Push correct branch — feature branch was released on 0.2.0

## [0.2.0] - 2025-01-04

### Added
- **Placeholder Support**: New placeholder functionality for `react_component` helper to prevent layout shift during component mounting
- **Three Placeholder Patterns**: ERB block, CSS class, and inline style options for maximum flexibility
- **Turbo Stream Optimization**: Perfect integration with Turbo Stream updates to eliminate "jumpy" content behavior
- **Automatic Cleanup**: Leverages React's natural DOM replacement for reliable placeholder removal
- **Error Handling**: Graceful fallback that keeps placeholder visible if React fails to mount

### Enhanced
- `react_component` helper now accepts optional block for custom placeholder content
- Added `placeholder_class` and `placeholder_style` options for quick placeholder styling
- Improved error resilience in React mounting process

### Documentation
- Comprehensive placeholder documentation with real-world examples
- Turbo Stream integration patterns and best practices
- Updated helper method signatures and available options

## [0.1.0] - 2025-08-04

### Added
- Initial release of IslandJS Rails
- JavaScript islands for Rails with little webpack complexity
- UMD library loading from CDNs
- ERB partial integration
- Turbo-compatible lifecycle management
- Support for React added — other frameworks possible
