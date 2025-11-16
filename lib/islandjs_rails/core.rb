require 'json'
require 'open3'
require 'net/http'
require 'uri'
require 'fileutils'

module IslandjsRails
  class Core
    attr_reader :configuration

    def initialize
      @configuration = IslandjsRails.configuration
    end

    # No longer needed - Vite handles bundling

    # Initialize IslandJS in a Rails project
    def init!
      # Use new Vite-based installer
      require_relative 'vite_installer'
      installer = ViteInstaller.new
      installer.install!
    end

    # Install a new island package
    def install!(package_name, version = nil)
      puts "📦 Installing UMD package: #{package_name}"
      
      # Check if React ecosystem was incomplete before this install
      was_react_ecosystem_incomplete = !react_ecosystem_complete?
      
      # Add to package.json via yarn if not present
      add_package_via_yarn(package_name, version) unless package_installed?(package_name)
      
      # Install to vendor directory
      vendor_manager = IslandjsRails.vendor_manager
      success = vendor_manager.install_package!(package_name, version)
      
      return false unless success
      
      global_name = detect_global_name(package_name)
      update_vite_externals(package_name, global_name)
      
      puts "✅ Successfully installed #{package_name}!"
      
      # Auto-scaffold React if ecosystem just became complete
      if was_react_ecosystem_incomplete && react_ecosystem_complete? && 
         (package_name == 'react' || package_name == 'react-dom')
        activate_react_scaffolding!
      end
    end

    # Update an existing package
    def update!(package_name, version = nil)
      puts "🔄 Updating UMD package: #{package_name}"
      
      unless package_installed?(package_name)
        raise IslandjsRails::PackageNotFoundError, "#{package_name} is not installed. Use 'install' instead."
      end
      
      # Update package.json via yarn
      yarn_update!(package_name, version)
      
      # Re-install to vendor directory
      vendor_manager = IslandjsRails.vendor_manager
      vendor_manager.install_package!(package_name, version)
      
      # Update Vite externals
      global_name = detect_global_name(package_name)
      update_vite_externals(package_name, global_name)
      
      puts "✅ Successfully updated #{package_name}!"
    end

    # Remove a specific package
    def remove!(package_name)
      puts "🗑️  Removing island package: #{package_name}"
      
      unless package_installed?(package_name)
        raise IslandjsRails::PackageNotFoundError, "Package #{package_name} is not installed"
      end
      
      remove_package_via_yarn(package_name)
      
      # Remove from vendor directory
      vendor_manager = IslandjsRails.vendor_manager
      vendor_manager.remove_package!(package_name)
      
      update_vite_externals
      puts "✅ Successfully removed #{package_name}!"
    end

    # Sync all packages
    def sync!
      puts "🔄 Syncing all UMD packages..."
      
      packages = installed_packages
      if packages.empty?
        puts "📦 No packages found in package.json"
        return
      end
      
      vendor_manager = IslandjsRails.vendor_manager
      
      packages.each do |package_name|
        next unless supported_package?(package_name)
        puts "  📦 Processing #{package_name}..."
        
        # Get version from package.json
        version = version_for(package_name)
        
        # Install to vendor system
        vendor_manager.install_package!(package_name, version)
        
        # Update Vite externals
        global_name = detect_global_name(package_name)
        update_vite_externals(package_name, global_name)
      end
      
      puts "✅ Sync completed!"
    end

    # Show status of all packages
    def status!
              puts "📊 IslandjsRails Status"
      puts "=" * 40
      
      packages = installed_packages
      if packages.empty?
        puts "📦 No packages found in package.json"
        return
      end
      
      # Check vendor system instead of partials
      vendor_manager = IslandjsRails.vendor_manager
      manifest = vendor_manager.send(:read_manifest)
      vendor_packages = manifest['libs'].map { |lib| lib['name'] }
      
      packages.each do |package_name|
        version = version_for(package_name)
        has_vendor = vendor_packages.include?(package_name)
        status_icon = has_vendor ? "✅" : "❌"
        puts "#{status_icon} #{package_name}@#{version} #{has_vendor ? '(vendor ready)' : '(missing vendor)'}"
      end
    end

    # Clean vendor files and rebuild
  def clean!
    puts "🧹 Cleaning vendor files..."
    
    vendor_manager = IslandjsRails.vendor_manager
    
    # Clean vendor files
    if Dir.exist?(configuration.vendor_dir)
      Dir.glob(File.join(configuration.vendor_dir, '*.js')).each do |file|
        File.delete(file)
        puts "  ✓ Removed #{File.basename(file)}"
      end
    end
    
    # Reset vendor manifest by writing empty manifest
    empty_manifest = { 'libs' => [] }
    vendor_manager.send(:write_manifest, empty_manifest)
    puts "  ✓ Reset vendor manifest"
    
    # Regenerate vendor partial
    vendor_manager.send(:regenerate_vendor_partial!)
    puts "  ✓ Regenerated vendor partial"
    
    # Vite externals will be updated as packages are reinstalled
    puts "  ✓ Vite externals will be updated as packages are reinstalled"
    
    # Reinstall all packages from package.json
    installed_packages.each do |package_name, version|
      puts "  📦 Reinstalling #{package_name}@#{version}..."
      vendor_manager.install_package!(package_name, version)
      global_name = detect_global_name(package_name)
      update_vite_externals(package_name, global_name)
    end
    
    puts "✅ Clean completed!"
  end

    # Public methods for external access
    def package_installed?(package_name)
      return false unless File.exist?(configuration.package_json_path)
      
      begin
        package_data = JSON.parse(File.read(configuration.package_json_path))
        dependencies = package_data.dig('dependencies') || {}
        dev_dependencies = package_data.dig('devDependencies') || {}
        
        dependencies.key?(package_name) || dev_dependencies.key?(package_name)
      rescue JSON::ParserError, Errno::ENOENT
        false
      end
    end

    def detect_global_name(package_name, url = nil)
      # Check built-in overrides first
      override = IslandjsRails::BUILT_IN_GLOBAL_NAME_OVERRIDES[package_name]
      return override if override
      
      # For scoped packages, use the package name part
      clean_name = package_name.include?('/') ? package_name.split('/').last : package_name
      
      # Convert kebab-case to camelCase
      clean_name.split('-').map.with_index { |part, i| i == 0 ? part : part.capitalize }.join
    end

    def version_for(library_name)
      package_data = package_json
      return nil unless package_data
      
      dependencies = package_data.dig('dependencies') || {}
      dev_dependencies = package_data.dig('devDependencies') || {}
      
      version = dependencies[library_name] || dev_dependencies[library_name]
      return nil unless version
      
      version.gsub(/[\^~>=<]/, '')
    end

    def find_working_island_url(package_name, version)
      puts "🔍 Searching for island build..."
      
      version ||= version_for(package_name)
      return nil unless version
      
      # Use cdn_package_name to handle React 19+ mapping to umd-react
      cdn_package = configuration.cdn_package_name(package_name, version)
      
      # Use original package name for URL, but get clean name for {name} substitution
      clean_name = (Configuration::SCOPED_PACKAGE_MAPPINGS[package_name] || package_name).split('/').last
      
      configuration.supported_cdns.each do |cdn_base|
        IslandjsRails::UMD_PATH_PATTERNS.each do |pattern|
          # Handle both {name} substitution patterns and fixed filename patterns
          path = if pattern.include?('{name}')
                   pattern.gsub('{name}', clean_name)
                 else
                   pattern  # Use pattern as-is for fixed filenames like IIFE
                 end
          url = "#{cdn_base}/#{cdn_package}@#{version}/#{path}"
          
          if url_accessible?(url)
            puts "✓ Found island: #{url}"
            return url
          end
        end
      end
      
      puts "❌ No island build found for #{package_name}@#{version}"
      nil
    end

    def find_working_umd_url(package_name, version)
      puts "  🔍 Searching for UMD build..."
      
      # Get package name without scope for path patterns
      clean_name = package_name.split('/').last
      
      IslandjsRails::CDN_BASES.each do |cdn_base|
        IslandjsRails::UMD_PATH_PATTERNS.each do |pattern|
          # Replace placeholders in pattern only if they exist
          path = if pattern.include?('{name}')
                   pattern.gsub('{name}', clean_name)
                 else
                   pattern  # Use pattern as-is for fixed filenames like IIFE
                 end
          url = "#{cdn_base}/#{configuration.cdn_package_name(package_name, version)}@#{version}/#{path}"

          
          if url_accessible?(url)
            puts "  ✓ Found UMD: #{url}"
            
            # Try to detect global name from the UMD content
            global_name = detect_global_name(package_name, url)
            
            return [url, global_name]
          end
        end
      end
      
      puts "  ❌ No UMD build found for #{package_name}@#{version}"
      [nil, nil]
    end

    private
    
    # Check if a package has a partial file
    def has_partial?(package_name)
      File.exist?(partial_path_for(package_name))
    end
    
    # Get global name for a package (used by Vite externals)
    def get_global_name_for_package(package_name)
      detect_global_name(package_name)
    end

    def react_ecosystem_complete?
      package_installed?('react') && package_installed?('react-dom')
    end

    def activate_react_scaffolding!
      puts "\n🎉 React ecosystem is now complete (React + React-DOM)!"
      
      uncomment_react_imports!
      create_hello_world_component!
      build_bundle!
      offer_demo_route!
    end

    def uncomment_react_imports!
      index_js_path = File.join(Dir.pwd, 'app', 'javascript', 'islands', 'index.js')
      return unless File.exist?(index_js_path)
      
      content = File.read(index_js_path)
      
      # Check if this looks like our commented template
      if content.include?('// import HelloWorld from') && content.include?('// HelloWorld')
        # Uncomment the import
        updated_content = content.gsub('// import HelloWorld from', 'import HelloWorld from')
        # Uncomment the export within the window.islandjsRails object
        updated_content = updated_content.gsub(/(\s+)\/\/ HelloWorld/, '\1HelloWorld')
        
        File.write(index_js_path, updated_content)
        puts "✓ Activated React imports in index.js"
      else
        puts "⚠️  index.js has been modified - please add HelloWorld manually"
      end
    end

    def create_hello_world_component!
      components_dir = File.join(Dir.pwd, 'app', 'javascript', 'islands', 'components')
      FileUtils.mkdir_p(components_dir)
      
      # Create turbo.js utility first
      create_turbo_utility!
      
      hello_world_path = File.join(components_dir, 'HelloWorld.jsx')
      
      if File.exist?(hello_world_path)
        puts "✓ HelloWorld.jsx already exists"
        return
      end

      # Copy from gem's template file instead of hardcoded string
      gem_template_path = File.join(__dir__, '..', 'templates', 'app', 'javascript', 'islands', 'components', 'HelloWorld.jsx')
      
      if File.exist?(gem_template_path)
        FileUtils.cp(gem_template_path, hello_world_path)
        puts "✓ Created HelloWorld.jsx component"
      else
        puts "⚠️  Template file not found: #{gem_template_path}"
      end
    end

    def create_turbo_utility!
      utils_dir = File.join(Dir.pwd, 'app', 'javascript', 'islands', 'utils')
      FileUtils.mkdir_p(utils_dir)
      
      turbo_path = File.join(utils_dir, 'turbo.js')
      
      if File.exist?(turbo_path)
        puts "✓ turbo.js utility already exists"
        return
      end
      
      # Copy from gem's template file instead of hardcoded string
      gem_template_path = File.join(__dir__, '..', 'templates', 'app', 'javascript', 'islands', 'utils', 'turbo.js')
      
      if File.exist?(gem_template_path)
        FileUtils.cp(gem_template_path, turbo_path)
        puts "✓ Created turbo.js utility"
      else
        puts "⚠️  Template file not found: #{gem_template_path}"
      end
    end
  end
end

# Load additional core methods
require_relative 'core_methods'
