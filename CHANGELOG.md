# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- **Flexible script attributes**: Helpers (`react_component`, `vue_component`, etc.) now support passing standard script attributes (`nonce`, `defer`, `async`, `crossorigin`, `integrity`).

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
