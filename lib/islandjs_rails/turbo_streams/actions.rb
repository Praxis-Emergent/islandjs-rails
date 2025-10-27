# frozen_string_literal: true

module IslandjsRails
  module TurboStreams
    module Actions
      # JavaScript code to register custom Turbo Stream actions
      # These actions allow updating React islands via Turbo Streams
      TURBO_ACTION_SCRIPT = <<~JS.freeze
        // IslandJS Rails: Custom Turbo Stream Actions
        // Registers island_merge and island_replace actions
        (function() {
          function registerIslandActions() {
            if (typeof Turbo === 'undefined') {
              console.warn('IslandJS: Turbo not loaded - island streaming disabled');
              return;
            }

            // Action: island_merge
            // Merges delta into existing data-initial-state
            Turbo.StreamActions.island_merge = function() {
              const target = this.getAttribute('target');
              const deltaAttr = this.getAttribute('delta') || this.textContent.trim();
              
              try {
                const delta = JSON.parse(deltaAttr);
                  const container = document.getElementById(target);
                
                if (container) {
                  const currentState = JSON.parse(container.dataset.initialState || '{}');
                  const newState = { ...currentState, ...delta };
                  container.dataset.initialState = JSON.stringify(newState);
                  
                  // Dispatch event for React hooks
                  container.dispatchEvent(new CustomEvent('islandjs:props-updated', {
                    bubbles: true,
                    detail: { containerId: target, props: newState, delta: delta }
                  }));
                } else {
                  console.warn('IslandJS: Target container not found:', target);
                }
              } catch (e) {
                console.error('IslandJS: island_merge failed:', e);
              }
            };

            // Action: island_replace
            // Completely replaces data-initial-state
            Turbo.StreamActions.island_replace = function() {
              const target = this.getAttribute('target');
              const propsAttr = this.getAttribute('props') || this.textContent.trim();
              
              try {
                const props = JSON.parse(propsAttr);
                const container = document.getElementById(target);
                
                if (container) {
                  container.dataset.initialState = JSON.stringify(props);
                  
                  container.dispatchEvent(new CustomEvent('islandjs:props-updated', {
                    bubbles: true,
                    detail: { containerId: target, props: props }
                  }));
                } else {
                  console.warn('IslandJS: Target container not found:', target);
                }
              } catch (e) {
                console.error('IslandJS: island_replace failed:', e);
              }
            };

            console.log('IslandJS: Turbo Stream actions registered');
          }

          // Try to register immediately
          if (typeof Turbo !== 'undefined') {
            registerIslandActions();
          }
          
          // Also register when DOM is ready
          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', registerIslandActions);
          } else {
            registerIslandActions();
          }
          
          // And when Turbo loads
          document.addEventListener('turbo:load', function() {
            if (typeof Turbo !== 'undefined' && !Turbo.StreamActions.island_merge) {
              registerIslandActions();
            }
          });
        })();
      JS

      def self.inject_script
        TURBO_ACTION_SCRIPT
      end
    end
  end
end

