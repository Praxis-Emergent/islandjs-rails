# frozen_string_literal: true

module IslandjsRails
  # Handles Vite integration for Islands architecture
  class ViteIntegration
    attr_reader :root_path
    
    def initialize(root_path = Rails.root)
      @root_path = Pathname.new(root_path)
    end
    
    # Check if Vite is already installed in the project
    def vite_installed?
      vite_config_exists? || vite_json_exists? || vite_rails_gem_installed?
    end
    
    # Check if Inertia is installed
    def inertia_installed?
      inertia_gem_installed? || inertia_layout_exists?
    end
    
    # Check if Islands is already configured
    def islands_configured?
      islands_vite_config_exists? && islands_structure_exists?
    end
    
    # Get the path to the Islands Vite config
    def islands_vite_config_path
      root_path.join('vite.config.islands.ts')
    end
    
    # Get the path to the Islands manifest
    def islands_manifest_path
      root_path.join('public/islands/.vite/manifest.json')
    end
    
    # Get the path to the main Vite config
    def vite_config_path
      root_path.join('vite.config.ts')
    end
    
    # Get the path to vite.json
    def vite_json_path
      root_path.join('vite.json')
    end
    
    # Check if Islands Vite config exists
    def islands_vite_config_exists?
      islands_vite_config_path.exist?
    end
    
    # Check if Islands structure exists
    def islands_structure_exists?
      root_path.join('app/javascript/islands').directory?
    end
    
    # Check if vite.config.ts exists
    def vite_config_exists?
      vite_config_path.exist?
    end
    
    # Check if vite.json exists
    def vite_json_exists?
      vite_json_path.exist?
    end
    
    # Check if vite_rails gem is installed
    def vite_rails_gem_installed?
      defined?(ViteRuby) || Gem.loaded_specs.key?('vite_rails')
    end
    
    # Check if inertia_rails gem is installed
    def inertia_gem_installed?
      Gem.loaded_specs.key?('inertia_rails')
    end
    
    # Check if Inertia layout exists
    def inertia_layout_exists?
      root_path.join('app/views/layouts/inertia.html.erb').exist?
    end
    
    # Read Islands manifest
    def read_islands_manifest
      return {} unless islands_manifest_path.exist?
      
      JSON.parse(islands_manifest_path.read)
    rescue JSON::ParserError
      {}
    end
    
    # Get Islands bundle path from manifest
    def islands_bundle_path
      manifest = read_islands_manifest
      entry = manifest['app/javascript/entrypoints/islands.js']
      
      return nil unless entry
      
      "/islands/#{entry['file']}"
    end
    
    # Check if package.json exists
    def package_json_exists?
      root_path.join('package.json').exist?
    end
    
    # Read package.json
    def read_package_json
      return {} unless package_json_exists?
      
      JSON.parse(root_path.join('package.json').read)
    rescue JSON::ParserError
      {}
    end
    
    # Write package.json
    def write_package_json(data)
      root_path.join('package.json').write(JSON.pretty_generate(data) + "\n")
    end
    
    # Update package.json scripts for Islands
    def update_package_json_scripts!
      package_json = read_package_json
      scripts = package_json['scripts'] || {}
      
      # Add Islands-specific scripts
      scripts['build:islands'] = 'vite build --config vite.config.islands.ts'
      scripts['islands:watch'] = 'vite build --config vite.config.islands.ts --watch'
      
      # Update main build script to include Islands
      if scripts['build']
        # If build script exists and includes vite, make it build both
        unless scripts['build'].include?('build:islands')
          if scripts['build'].include?('vite build')
            # Replace single vite build with both builds
            scripts['build'] = 'vite build --emptyOutDir && yarn build:islands'
          else
            # Append Islands build
            scripts['build'] = "#{scripts['build']} && yarn build:islands"
          end
        end
      else
        # No build script yet, create one
        scripts['build'] = 'vite build --emptyOutDir && yarn build:islands'
      end
      
      package_json['scripts'] = scripts
      write_package_json(package_json)
    end
    
    # Detect which layout to use for Islands
    def islands_layout_path
      # Always use application.html.erb for Islands (ERB pages)
      # Never touch inertia.html.erb (that's for SPA)
      root_path.join('app/views/layouts/application.html.erb')
    end
    
    # Check if Islands helper is already in layout
    def layout_has_islands_helper?
      return false unless islands_layout_path.exist?
      
      content = islands_layout_path.read
      content.include?('<%= islands %>') || content.include?('islands %>')
    end
  end
end
