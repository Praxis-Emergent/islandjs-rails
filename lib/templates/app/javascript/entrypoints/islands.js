// IslandJS Rails - Islands Entrypoint
// This file exports all your Island components to window.islandjsRails
// Components exported here can be used in ERB templates via <%= react_component('ComponentName') %>

// Import your island components
import HelloWorld from '../islands/components/HelloWorld.jsx'

// Export to global namespace for ERB template access
window.islandjsRails = {
  HelloWorld,
  // Add more components here as you create them:
  // ChatWidget,
  // UserProfile,
  // etc.
}

// Optional: Log available components in development
if (import.meta.env.DEV) {
  console.log('🏝️ IslandJS components loaded:', Object.keys(window.islandjsRails))
}
