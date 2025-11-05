# Upgrading IslandJS Rails

## Upgrading from 0.x to 1.0

Version 1.0 replaces webpack with Vite for a faster, more modern build system.

### Breaking Changes

- **Build system**: webpack → Vite
- **Config file**: `webpack.config.js` → `vite.config.islands.ts`
- **Build command**: `yarn build` → `yarn build:islands`
- **Watch command**: `yarn watch` → `yarn islands:watch`
- **Manifest location**: `public/islands_manifest.json` → `public/islands/.vite/manifest.json`

### Upgrade Steps

1. **Update the gem**:
   ```bash
   bundle update islandjs-rails
   ```

2. **Remove webpack setup**:
   ```bash
   # Remove webpack config
   rm webpack.config.js
   
   # Remove webpack dependencies from package.json
   yarn remove webpack webpack-cli webpack-manifest-plugin
   ```

3. **Reinitialize with Vite**:
   ```bash
   rails islandjs:init
   ```
   
   This will:
   - Create `vite.config.islands.ts`
   - Install Vite dependencies
   - Update your `package.json` scripts
   - Set up the new build structure

4. **Update your build/deploy scripts** (if any):
   - Change `yarn build` to `yarn build:islands`
   - Change `yarn watch` to `yarn islands:watch`

5. **Rebuild your islands**:
   ```bash
   yarn build:islands
   ```

### What Stays the Same

✅ **No code changes needed!**
- All Rails helpers work identically (`react_component`, `island_partials`, etc.)
- Your island components don't need any changes
- Your ERB templates don't need any changes
- The UMD vendor system works the same way
- All `rails islandjs:*` commands work the same way

### Benefits of Vite

- ⚡ **Much faster builds** (2-10x faster than webpack)
- 🔥 **Instant HMR** during development
- 📦 **Smaller bundle sizes** with better tree-shaking
- 🎯 **Simpler configuration** - no complex webpack config needed
- 🚀 **Modern tooling** - built for ES modules and modern JavaScript

### Troubleshooting

**Build fails with "vite not found"**:
```bash
yarn install
```

**Old webpack files still present**:
```bash
rm webpack.config.js
rm -rf node_modules/.cache/webpack
```

**Manifest not found errors**:
```bash
yarn build:islands
```

### Need Help?

- Check the [README](README.md) for full documentation
- Open an issue on [GitHub](https://github.com/yourusername/islandjs-rails)
