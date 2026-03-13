# Upgrading IslandJS Rails

## Upgrading from 1.x to 2.0

Version 2.0 removes the UMD/vendor system entirely. React and all dependencies are now bundled directly into your Islands bundle as regular npm dependencies.

### Breaking Changes

- **UMD/vendor system removed**: No more `rails islandjs:install`, vendor directory, or CDN downloads
- **React bundled directly**: Imported in the entrypoint and exposed on `window`

### Upgrade Steps

1. **Update the gem**:
   ```bash
   bundle update islandjs-rails
   ```

2. **Add React as a direct dependency** (if not already):
   ```bash
   yarn add react react-dom
   ```

3. **Update your entrypoint** (`app/javascript/entrypoints/islands.js`):
   ```javascript
   import React from 'react'
   import * as ReactDOM from 'react-dom'
   import { createRoot, hydrateRoot } from 'react-dom/client'
   import HelloWorld from '../islands/components/HelloWorld.jsx'

   // Expose React and ReactDOM globally for islandjs-rails mount scripts
   window.React = React
   window.ReactDOM = { ...ReactDOM, createRoot, hydrateRoot }

   window.islandjsRails = {
     HelloWorld,
   }
   ```

4. **Update your Vite config** — remove React externals from `vite.config.islands.ts`:
   ```typescript
   // Remove these from rollupOptions:
   //   external: ['react', 'react-dom'],
   //   globals: { react: 'React', 'react-dom': 'ReactDOM' }
   ```

5. **Clean up old vendor files**:
   ```bash
   rm -rf public/vendor/islands/
   rm -rf app/views/shared/islands/
   ```

6. **Rebuild**:
   ```bash
   yarn build:islands
   ```

### What Stays the Same

- All `react_component` calls in ERB templates work exactly the same
- Turbo cache integration works the same
- Placeholder support works the same
- The `<%= islands %>` helper works the same
- Component pattern (`containerId` prop, `useTurboProps`, `useTurboCache`) is unchanged

### Need Help?

- Check the [README](README.md) for full documentation
- Open an issue on [GitHub](https://github.com/praxis-emergent/islandjs-rails)

## Upgrading from 0.x to 1.0

Version 1.0 replaced webpack with Vite. See the [1.0.0 changelog](CHANGELOG.md#100---2025-11-05) for details.
