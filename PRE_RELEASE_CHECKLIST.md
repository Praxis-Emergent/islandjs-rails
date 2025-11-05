# Pre-Release Checklist for v1.0.0

## ✅ Code Changes Complete

### Production Code
- [x] All webpack references removed from lib/
- [x] All webpack references removed from README.md
- [x] All webpack references removed from gemspec
- [x] webpack.config.js template deleted
- [x] vite.config.islands.ts template created
- [x] ViteInstaller class implemented
- [x] ViteIntegration module implemented
- [x] Babel dependencies removed from package.json template
- [x] Build commands updated (yarn build:islands)
- [x] Manifest path updated (public/islands/.vite/manifest.json)
- [x] All Rails helpers updated for Vite
- [x] All Rake tasks updated for Vite
- [x] CLI commands updated for Vite

### Test Suite
- [x] All 364 specs passing (0 failures)
- [x] All webpack references removed from specs
- [x] Manifest path tests updated
- [x] Build command stubs updated
- [x] Error message expectations updated
- [x] 84.32% code coverage

### Documentation
- [x] CHANGELOG.md updated with v1.0.0 entry
- [x] UPGRADING.md created with migration guide
- [x] Version bumped to 1.0.0 in lib/islandjs_rails/version.rb
- [x] Gemspec post-install message mentions Vite
- [x] README updated (already done in vite branch)

## 📋 Files Changed in This Commit

```
CHANGELOG.md                  | 64 insertions
lib/islandjs_rails/version.rb |  2 changes (0.7.0 → 1.0.0)
lib/templates/package.json    |  4 deletions (babel deps removed)
UPGRADING.md                  | new file
```

## 🔍 Final Verification Steps

### Before Commit
- [x] Run full test suite: `bundle exec rspec`
- [x] Check for webpack references: `grep -ri webpack lib/` (none found)
- [x] Check for babel in production code: `grep -ri babel lib/` (only CDN mappings)
- [x] Verify version number: `cat lib/islandjs_rails/version.rb`
- [x] Verify CHANGELOG date: `head -10 CHANGELOG.md`
- [x] Check git status: `git status`

### After Commit to GitHub
1. [ ] Push to GitHub: `git push origin vite`
2. [ ] Verify GitHub Actions pass (if any)
3. [ ] Test installation from GitHub:
   ```ruby
   gem 'islandjs-rails', github: 'praxis-emergent/islandjs-rails', branch: 'vite'
   ```
4. [ ] Run `rails islandjs:init` in a fresh Rails 8 app
5. [ ] Verify Vite config is created
6. [ ] Verify build works: `yarn build:islands`
7. [ ] Verify watch works: `yarn islands:watch`

### Before Publishing to RubyGems
1. [ ] Merge vite branch to main
2. [ ] Create git tag: `git tag v1.0.0`
3. [ ] Push tag: `git push origin v1.0.0`
4. [ ] Build gem: `gem build islandjs-rails.gemspec`
5. [ ] Test gem locally: `gem install ./islandjs-rails-1.0.0.gem`
6. [ ] Publish: `gem push islandjs-rails-1.0.0.gem`

## 🎯 Breaking Changes Summary

**What Breaks:**
- Build system (webpack → Vite)
- Config file (webpack.config.js → vite.config.islands.ts)
- Build commands (yarn build → yarn build:islands)
- Manifest location (public/islands_manifest.json → public/islands/.vite/manifest.json)

**What Doesn't Break:**
- All Rails helpers (react_component, island_partials, etc.)
- Island components (no code changes needed)
- ERB templates (no changes needed)
- UMD vendor system (works identically)
- Rake tasks (same commands, different internals)

## 🚀 Benefits

- 2-10x faster builds
- Instant HMR during development
- Smaller bundle sizes
- Simpler configuration
- Modern tooling
- Better Rails integration via vite_rails

## 📝 Commit Message Template

```
Release v1.0.0: Webpack → Vite Migration

Major release replacing webpack with Vite for dramatically faster builds
and modern tooling.

BREAKING CHANGES:
- Build system changed from webpack to Vite
- Config file: webpack.config.js → vite.config.islands.ts
- Build command: yarn build → yarn build:islands
- Manifest path: public/islands_manifest.json → public/islands/.vite/manifest.json

All runtime APIs remain unchanged - no code changes needed for existing islands.

See UPGRADING.md for migration instructions.
See CHANGELOG.md for full details.

- 364 specs passing
- 84.32% code coverage
- Zero webpack references remaining
```

## ✅ Ready to Commit!

All checks passed. Safe to commit and push to GitHub for final testing.
