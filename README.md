# IslandJS Rails — React components in Rails ERB templates

**Turbo-compatible React islands for Rails apps.**

[![Rails 8 Ready](https://img.shields.io/badge/Rails%208-Ready-brightgreen.svg)](#)

Write React components in `app/javascript/islands/components/` and render them in ERB templates with the `react_component` helper. State persists across Turbo navigation automatically.

## Quick Start

### Installation

```ruby
# Gemfile
gem 'islandjs-rails'
```

```bash
bundle install
rails islandjs:init    # Sets up everything: directories, Vite config, dependencies
yarn build:islands     # Build the bundle
```

> `rails islandjs:init` creates the directory structure, Vite config, `package.json` build scripts, installs React and Vite dependencies (if Yarn is available), and injects `<%= islands %>` into your layout.

### Write a Component

```jsx
// app/javascript/islands/components/DashboardApp.jsx
import React, { useState, useEffect } from 'react';
import { useTurboProps, useTurboCache } from '../utils/turbo.js';

function DashboardApp({ containerId }) {
  const initialProps = useTurboProps(containerId);
  const [count, setCount] = useState(initialProps.count || 0);

  useEffect(() => {
    const cleanup = useTurboCache(containerId, { count }, true);
    return cleanup;
  }, [containerId, count]);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(c => c + 1)}>Increment</button>
    </div>
  );
}

export default DashboardApp;
```

### Register in Entrypoint

```javascript
// app/javascript/entrypoints/islands.js
import React from 'react'
import * as ReactDOM from 'react-dom'
import { createRoot, hydrateRoot } from 'react-dom/client'
import HelloWorld from '../islands/components/HelloWorld.jsx'
import DashboardApp from '../islands/components/DashboardApp.jsx'

window.React = React
window.ReactDOM = { ...ReactDOM, createRoot, hydrateRoot }

window.islandjsRails = {
  HelloWorld,
  DashboardApp,
}
```

### Render in ERB

```erb
<%= react_component('DashboardApp', { count: 5 }) %>

<!-- With placeholder to prevent layout shift -->
<%= react_component('DashboardApp', { count: 5 }) do %>
  <div class="loading-skeleton">Loading...</div>
<% end %>
```

### Build

```bash
yarn build:islands    # production build
yarn watch:islands    # development (watch mode)
```

## How It Works

1. You write React components in `app/javascript/islands/components/`
2. You register them in `app/javascript/entrypoints/islands.js`
3. Your bundler builds everything into `public/islands/` with a manifest
4. The `react_component` ERB helper renders a container div with props and a mount script
5. On page load, the mount script finds the component and renders it with React
6. On Turbo navigation, components are cleanly unmounted and remounted

React and ReactDOM are bundled directly into your Islands bundle — no separate script tags or CDN dependencies needed.

> The `<%= islands %>` helper is automatically added to your layout by `rails islandjs:init`. It loads your built bundle via a manifest at `public/islands/.vite/manifest.json`.

## Component Pattern

Every component receives a single `containerId` prop and reads its data from the container's `data-initial-state` attribute:

```jsx
import React, { useState, useEffect } from 'react';
import { useTurboProps, useTurboCache } from '../utils/turbo.js';

function MyComponent({ containerId }) {
  const initialProps = useTurboProps(containerId);
  const [value, setValue] = useState(initialProps.value || 'default');

  useEffect(() => {
    const cleanup = useTurboCache(containerId, { value }, true);
    return cleanup;
  }, [containerId, value]);

  return <div>{value}</div>;
}

export default MyComponent;
```

## Rails Helpers

### `<%= islands %>`

Renders the script tag for your Islands bundle. Placed in your layout's `<head>` automatically by `rails islandjs:init`.

### `<%= react_component(name, props, options, &block) %>`

Mounts a React component with Turbo-compatible lifecycle.

```erb
<%= react_component('UserProfile', {
  userId: current_user.id,
  theme: 'dark'
}, {
  container_id: 'profile-widget',
  class: 'my-component'
}) %>
```

**Options:**
- `container_id` — Custom ID for the container element
- `namespace` — JavaScript namespace (default: `window.islandjsRails`)
- `tag` — HTML tag for container (default: `div`)
- `class` — CSS class for container
- `placeholder_class` — CSS class for placeholder content
- `placeholder_style` — Inline styles for placeholder
- `nonce`, `defer`, `async`, `crossorigin`, `integrity` — Script tag attributes

## Turbo Cache Integration

Component state persists across Turbo navigation automatically.

The `react_component` helper stores props as JSON in a `data-initial-state` attribute. Components read this on mount via `useTurboProps` and persist state changes back via `useTurboCache`.

### Turbo Utilities

```javascript
import { useTurboProps, useTurboCache, persistState } from '../utils/turbo.js';

// Read initial props from container
const props = useTurboProps(containerId);

// Persist state for Turbo cache (call in useEffect)
const cleanup = useTurboCache(containerId, currentState, true);

// Manual state persistence
persistState(containerId, stateObject);
```

## Placeholder Support

Prevent layout shift when React components mount:

```erb
<!-- ERB block placeholder -->
<%= react_component("Reactions", { postId: post.id }) do %>
  <div class="reactions-skeleton">Loading...</div>
<% end %>

<!-- CSS class placeholder -->
<%= react_component("Reactions", { postId: post.id }, {
  placeholder_class: "reactions-skeleton"
}) %>

<!-- Inline style placeholder -->
<%= react_component("Reactions", { postId: post.id }, {
  placeholder_style: "height: 40px; background: #f8f9fa;"
}) %>
```

## Requirements

- **Rails** 7+ (tested with Rails 8)
- **React** 18+ (tested with React 19)
- A JavaScript bundler that outputs to `public/islands/` with a `.vite/manifest.json`

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run the tests (`bundle exec rspec`)
4. Commit your changes
5. Push to the branch
6. Open a Pull Request

## License

MIT License — see LICENSE file for details.
