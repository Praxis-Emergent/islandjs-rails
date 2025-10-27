// Turbo-compatible state management utilities for React components

/**
 * Get initial state from a container's data-initial-state attribute
 * @param {string} containerId - The ID of the container element
 * @returns {Object} - Parsed initial state object
 */
export function useTurboProps(containerId) {
  const container = document.getElementById(containerId);
  if (!container) {
    console.warn(`IslandJS Turbo: Container ${containerId} not found`);
    return {};
  }

  const initialStateJson = container.dataset.initialState;
  if (!initialStateJson) {
    return {};
  }

  try {
    return JSON.parse(initialStateJson);
  } catch (e) {
    console.warn('IslandJS Turbo: Failed to parse initial state', e);
    return {};
  }
}

/**
 * Set up Turbo cache persistence for React component state
 * @param {string} containerId - The ID of the container element
 * @param {Object} currentState - Current component state to persist
 * @param {boolean} autoRestore - Whether to automatically restore state on turbo:load
 * @returns {Function} - Cleanup function to remove event listeners
 */
export function useTurboCache(containerId, currentState, autoRestore = true) {
  const container = document.getElementById(containerId);
  if (!container) {
    console.warn(`IslandJS Turbo: Container ${containerId} not found for caching`);
    return () => {};
  }

  // Immediately persist the current state to the div (don't wait for turbo:before-cache)
  try {
    const stateJson = JSON.stringify(currentState);
    container.dataset.initialState = stateJson;
  } catch (e) {
    console.warn('IslandJS Turbo: Failed to immediately serialize state', e);
  }
}

/**
 * Hook for React components to automatically manage Turbo cache persistence
 * This is a React hook that should be called from within a React component
 * @param {string} containerId - The ID of the container element
 * @param {Object} state - Current component state to persist
 * @param {Array} dependencies - Dependencies array for useEffect
 */
export function useTurboCacheEffect(containerId, state, dependencies = []) {
  // This assumes React is available globally
  if (typeof React !== 'undefined' && React.useEffect) {
    React.useEffect(() => {
      return useTurboCache(containerId, state, false);
    }, [containerId, ...dependencies]);
  } else {
    console.warn('IslandJS Turbo: React.useEffect not available for useTurboCacheEffect');
  }
}

/**
 * Manually persist state to container for components that don't use the hook
 * @param {string} containerId - The ID of the container element  
 * @param {Object} state - State object to persist
 */
export function persistState(containerId, state) {
  const container = document.getElementById(containerId);
  if (!container) {
    console.warn(`IslandJS Turbo: Container ${containerId} not found for state persistence`);
    return;
  }

  try {
    const stateJson = JSON.stringify(state);
    container.dataset.initialState = stateJson;
  } catch (e) {
    console.warn('IslandJS Turbo: Failed to serialize state', e);
  }
}

// ============================================================================
// TURBO STREAMS SUPPORT FOR REACT ISLANDS
// ============================================================================
// Note: Turbo Stream actions are registered in the layout via turbo_stream_island_actions helper

/**
 * Hook that watches for Turbo Stream updates to data-initial-state
 * This enables real-time updates to React components without full page reloads
 * 
 * @param {string} containerId - The ID of the container element
 * @param {function} onUpdate - Optional callback when props update
 * @returns {Object} Current props from data-initial-state
 * 
 * @example
 * function ChatMessage({ containerId }) {
 *   const props = useStreamingProps(containerId, (newProps) => {
 *     console.log('Props updated!', newProps);
 *   });
 *   return <div>{props.content}</div>;
 * }
 */
export function useStreamingProps(containerId, onUpdate) {
  // This assumes React is available globally
  if (typeof React === 'undefined' || !React.useState || !React.useEffect) {
    console.warn('IslandJS Turbo: React hooks not available for useStreamingProps');
    // Fallback to reading props once
    return readPropsFromContainer(containerId);
  }

  const [props, setProps] = React.useState(() => {
    return readPropsFromContainer(containerId);
  });

  React.useEffect(() => {
    const container = document.getElementById(containerId);
    if (!container) return;

    // Watch for data-initial-state changes from Turbo Streams
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.attributeName === 'data-initial-state') {
          try {
            const newProps = JSON.parse(container.dataset.initialState || '{}');
            setProps(newProps);
            if (onUpdate) {
              onUpdate(newProps);
            }
          } catch (e) {
            console.error('IslandJS: Failed to parse updated state:', e);
          }
        }
      });
    });

    observer.observe(container, { 
      attributes: true, 
      attributeFilter: ['data-initial-state'] 
    });

    return () => observer.disconnect();
  }, [containerId, onUpdate]);

  return props;
}

/**
 * Alternative: Imperative streaming with delta updates
 * Listens for custom islandjs:props-updated events
 * 
 * @param {string} containerId - The ID of the container element
 * @param {Object} initialState - Initial state object
 * @returns {Array} [state, setState] tuple
 * 
 * @example
 * function Counter({ containerId }) {
 *   const [state, setState] = useStreamingState(containerId, { count: 0 });
 *   return <div>Count: {state.count}</div>;
 * }
 */
export function useStreamingState(containerId, initialState = {}) {
  if (typeof React === 'undefined' || !React.useState || !React.useEffect) {
    console.warn('IslandJS Turbo: React hooks not available for useStreamingState');
    return [initialState, () => {}];
  }

  const [state, setState] = React.useState(initialState);
  
  React.useEffect(() => {
    const handler = (e) => {
      if (e.detail.containerId === containerId) {
        if (e.detail.delta) {
          // Merge delta update
          setState(prev => ({
            ...prev,
            ...e.detail.delta
          }));
        } else if (e.detail.props) {
          // Full replacement
          setState(e.detail.props);
        }
      }
    };
    
    document.addEventListener('islandjs:props-updated', handler);
    return () => document.removeEventListener('islandjs:props-updated', handler);
  }, [containerId]);
  
  return [state, setState];
}

/**
 * Utility to read props from container
 * 
 * @param {string} containerId - The ID of the container element
 * @returns {Object} Parsed props object
 */
export function readPropsFromContainer(containerId) {
  const container = document.getElementById(containerId);
  if (!container) {
    console.warn(`IslandJS: Container ${containerId} not found`);
    return {};
  }
  
  try {
    return JSON.parse(container.dataset.initialState || '{}');
  } catch (e) {
    console.error('IslandJS: Failed to read props from container:', e);
    return {};
  }
}

/**
 * Utility to manually update props (for testing or imperative updates)
 * 
 * @param {string} containerId - The ID of the container element
 * @param {Object} props - New props object
 */
export function updateContainerProps(containerId, props) {
  const container = document.getElementById(containerId);
  if (!container) {
    console.warn(`IslandJS: Container ${containerId} not found for update`);
    return;
  }
  
  container.dataset.initialState = JSON.stringify(props);
  
  // Dispatch event for imperative listeners
  container.dispatchEvent(new CustomEvent('islandjs:props-updated', {
    bubbles: true,
    detail: { containerId, props }
  }));
} 