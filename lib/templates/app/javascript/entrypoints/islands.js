// IslandJS Rails - Islands Entrypoint
// Export React components to window.islandjsRails for ERB template access
// Add your components below and they'll be available via <%= react_component('Name') %>

import React from 'react'
import * as ReactDOM from 'react-dom'
import { createRoot, hydrateRoot } from 'react-dom/client'

// Import your island components
import HelloWorld from '../islands/components/HelloWorld.jsx'

// Expose React and ReactDOM globally for islandjs-rails mount scripts
// Merge react-dom (createPortal, flushSync) + react-dom/client (createRoot, hydrateRoot)
window.React = React
window.ReactDOM = { ...ReactDOM, createRoot, hydrateRoot }

// Register components for ERB template access
window.islandjsRails = {
  HelloWorld,
  // Add more components here:
  // MyComponent,
}

// Optional: Log available components in development
if (import.meta.env.DEV) {
  console.log('🏝️ IslandJS components loaded:', Object.keys(window.islandjsRails))
}
