module IslandjsRails
  module RailsHelpers
    # Script attributes that can be passed through options
    SCRIPT_ATTRIBUTES = %i[nonce defer async crossorigin integrity].freeze

    # Main helper method - includes the Islands bundle script
    def islands(**attributes)
      island_bundle_script(**attributes)
    end

    # Render the main IslandJS bundle script tag
    # Reads from manifest at public/islands/.vite/manifest.json
    #
    # IMPORTANT: Manifest is read on EVERY request (no caching) to ensure
    # content-hashed filenames are always fresh after rebuilds.
    def island_bundle_script(**attributes)
      manifest_path = Rails.root.join('public/islands/.vite/manifest.json')

      # Get formatted HTML attributes with defaults (including auto-nonce and defer)
      html_attributes = script_html_attributes(defer: true, **attributes)

      unless File.exist?(manifest_path)
        if Rails.env.development?
          return html_safe_string("<!-- Islands bundle not built. Run: yarn build:islands -->")
        else
          return html_safe_string("<!-- Islands bundle missing -->")
        end
      end

      begin
        manifest = JSON.parse(File.read(manifest_path))

        # Look for islands entrypoint in manifest
        entry = manifest['app/javascript/entrypoints/islands.js']

        if entry && entry['file']
          bundle_path = "/islands/#{entry['file']}"
          html_safe_string("<script src=\"#{bundle_path}\"#{html_attributes}></script>")
        else
          if Rails.env.development?
            html_safe_string("<!-- Islands entry not found in manifest. Available keys: #{manifest.keys.join(', ')} -->")
          else
            html_safe_string("<!-- Islands entry not found in manifest -->")
          end
        end
      rescue JSON::ParserError => e
        if Rails.env.development?
          html_safe_string("<!-- Islands manifest parse error: #{e.message} -->")
        else
          html_safe_string("<!-- Islands manifest parse error -->")
        end
      end
    end

    # Mount a React component with props and Turbo-compatible lifecycle
    # Supports optional placeholder content via block or options
    def react_component(component_name, props = {}, options = {}, &block)
      # Generate component ID - use custom container_id if provided
      if options[:container_id]
        component_id = options[:container_id]
      else
        component_id = "react-#{component_name.gsub(/([A-Z])/, '-\1').downcase.gsub(/^-/, '')}-#{SecureRandom.hex(4)}"
      end

      # Extract options
      tag_name = options[:tag] || 'div'
      css_class = options[:class] || ''
      namespace = options[:namespace] || 'window.islandjsRails'

      # Handle placeholder options
      placeholder_class = options[:placeholder_class]
      placeholder_style = options[:placeholder_style]

      # Extract script attributes from options
      script_attributes = options.slice(*SCRIPT_ATTRIBUTES)
      script_attributes.compact!

      # For turbo-cache compatibility, store initial state as JSON in data attribute
      initial_state_json = props.to_json

      # Generate data attributes from props with proper HTML escaping
      data_attrs = props.map do |key, value|
        attr_name = key.to_s.gsub(/([A-Z])/, '-\1').gsub('_', '-').downcase.gsub(/^-/, '')
        attr_value = if value.nil?
          ''
        else
          value.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
        end
        "data-#{attr_name}=\"#{attr_value}\""
      end.join(' ')

      # Generate optional chaining syntax for custom namespaces
      namespace_with_optional = if namespace != 'window.islandjsRails' && !namespace.include?('?')
        namespace + '?'
      else
        namespace
      end

      # Generate the mounting script
      mount_script = generate_react_mount_script(component_name, component_id, namespace, namespace_with_optional, **script_attributes)

      # Return the container div with data-initial-state and script
      data_part = data_attrs.empty? ? '' : " #{data_attrs}"
      class_part = css_class.empty? ? '' : " class=\"#{css_class}\""

      # Add data-initial-state for turbo-cache compatibility
      initial_state_attr = " data-initial-state=\"#{initial_state_json.gsub('"', '&quot;')}\""

      # Generate placeholder content
      placeholder_content = if block_given?
        placeholder_html = capture(&block)
        "<div data-island-placeholder=\"true\">#{placeholder_html}</div>"
      elsif placeholder_class || placeholder_style
        class_attr = placeholder_class ? " class=\"#{placeholder_class}\"" : ""
        style_attr = placeholder_style ? " style=\"#{placeholder_style}\"" : ""
        "<div data-island-placeholder=\"true\"#{class_attr}#{style_attr}></div>"
      else
        ""
      end

      # Build container HTML with optional placeholder
      if placeholder_content.empty?
        container_html = "<#{tag_name} id=\"#{component_id}\"#{class_part}#{data_part}#{initial_state_attr}></#{tag_name}>"
      else
        container_html = "<#{tag_name} id=\"#{component_id}\"#{class_part}#{data_part}#{initial_state_attr}>#{placeholder_content}</#{tag_name}>"
      end

      html_safe_string("#{container_html}\n#{mount_script}")
    end

    # Generic island component helper (currently only supports React)
    def island_component(framework, component_name, props = {}, options = {})
      case framework.to_s.downcase
      when 'react'
        react_component(component_name, props, options)
      else
        html_safe_string("<!-- Unsupported framework: #{framework}. Only React is currently supported. -->")
      end
    end

    # Debug helper to show available components
    def island_debug
      return '' unless Rails.env.development?

      manifest_path = Rails.root.join('public/islands/.vite/manifest.json')
      bundle_exists = File.exist?(manifest_path)
      islands_dir = Rails.root.join('app/javascript/islands/components')
      component_count = islands_dir.exist? ? Dir.glob(File.join(islands_dir, '*.{jsx,tsx}')).count : 0

      debug_html = <<~HTML
        <div style="background: #f0f0f0; padding: 10px; margin: 10px 0; border: 1px solid #ccc; font-family: monospace; font-size: 12px;">
          <strong>🏝️ IslandJS Debug Info:</strong><br>
          Bundle manifest: #{bundle_exists ? '✓' : '✗ (run yarn build:islands)'}<br>
          Components: #{component_count} found
        </div>
      HTML

      html_safe_string(debug_html)
    end

    private

    # Format HTML attributes into a string
    def format_html_attributes(**attributes)
      return '' if attributes.empty?

      attributes.filter_map do |key, value|
        next if value.nil? || value == false
        key_str = key.to_s.tr('_', '-')
        value == true ? " #{key_str}" : " #{key_str}=\"#{value}\""
      end.join
    end

    # Get default script attributes with auto-nonce detection
    def default_script_attributes(**user_attributes)
      attributes = {}

      # Auto-add nonce if CSP is enabled and not explicitly provided
      if !user_attributes.key?(:nonce) && respond_to?(:content_security_policy_nonce)
        nonce = content_security_policy_nonce
        attributes[:nonce] = nonce if nonce
      end

      attributes.merge(user_attributes)
    end

    # Get formatted HTML attributes string for script tags
    def script_html_attributes(**attributes)
      script_attributes = default_script_attributes(**attributes)
      format_html_attributes(**script_attributes)
    end

    # Generate React component mounting script with Turbo compatibility
    def generate_react_mount_script(component_name, component_id, namespace, namespace_with_optional, **attributes)
      html_attributes = script_html_attributes(**attributes)

      <<~JAVASCRIPT
        <script#{html_attributes}>
          (function() {
            function mount#{component_name}() {
              const container = document.getElementById('#{component_id}');
              if (!container) return;

              // Check for component availability
              if (typeof #{namespace_with_optional} === 'undefined' || !#{namespace_with_optional}.#{component_name}) {
                console.warn('IslandJS: #{component_name} component not found. Make sure it\\'s exported in your Islands bundle.');
                // Restore placeholder visibility if component fails to load
                const placeholder = container.querySelector('[data-island-placeholder="true"]');
                if (placeholder) {
                  placeholder.style.display = '';
                }
                return;
              }

              if (typeof React === 'undefined' || typeof window.ReactDOM === 'undefined') {
                console.warn('IslandJS: React or ReactDOM not loaded. Make sure your Islands bundle is built and includes React.');
                // Restore placeholder visibility if React fails to load
                const placeholder = container.querySelector('[data-island-placeholder="true"]');
                if (placeholder) {
                  placeholder.style.display = '';
                }
                return;
              }

              const props = { containerId: '#{component_id}' };
              const element = React.createElement(#{namespace_with_optional}.#{component_name}, props);

              try {
                // Use React 18+ createRoot if available, fallback to React 17 render
                if (window.ReactDOM.createRoot) {
                  if (!container._reactRoot) {
                    container._reactRoot = window.ReactDOM.createRoot(container);
                  }
                  // Use flushSync to force synchronous rendering, preventing flash
                  if (window.ReactDOM.flushSync) {
                    window.ReactDOM.flushSync(() => {
                      container._reactRoot.render(element);
                    });
                  } else {
                    container._reactRoot.render(element);
                  }
                } else {
                  // React 17 fallback
                  window.ReactDOM.render(element, container);
                }
              } catch (error) {
                console.error('IslandJS: Failed to mount #{component_name}:', error);
              }
            }

            function cleanup#{component_name}() {
              const container = document.getElementById('#{component_id}');
              if (!container) return;

              if (container._reactRoot) {
                container._reactRoot.unmount();
                container._reactRoot = null;
              } else if (typeof window.ReactDOM !== 'undefined' && window.ReactDOM.unmountComponentAtNode) {
                window.ReactDOM.unmountComponentAtNode(container);
              }
            }

            // Mount on page load and Turbo navigation
            if (document.readyState === 'loading') {
              document.addEventListener('DOMContentLoaded', mount#{component_name});
            } else {
              mount#{component_name}();
            }

            // Turbo compatibility
            document.addEventListener('turbo:load', mount#{component_name});
            document.addEventListener('turbo:before-cache', cleanup#{component_name});
          })();
        </script>
      JAVASCRIPT
    end

    # Cross-Rails version html_safe compatibility
    def html_safe_string(string)
      if string.respond_to?(:html_safe)
        string.html_safe
      else
        string
      end
    end
  end
end

# Auto-include in ActionView if Rails is present
if defined?(ActionView::Base)
  ActionView::Base.include IslandjsRails::RailsHelpers
end
