# frozen_string_literal: true

require 'fileutils'
require 'json'
require_relative 'vite_integration'

module IslandjsRails
  # Idempotent installer for Islands + Vite integration
  class ViteInstaller
    attr_reader :vite_integration, :root_path
    
    def initialize(root_path = Rails.root)
      @root_path = Pathname.new(root_path)
      @vite_integration = ViteIntegration.new(root_path)
    end
    
    # Main installation method - fully idempotent
    def install!
      puts "🏝️  Initializing IslandJS Rails with Vite..."
      
      # Check current state
      check_prerequisites!
      
      # Install/configure based on current state
      if vite_integration.vite_installed?
        puts "✓ Vite detected, configuring Islands alongside existing setup"
        configure_islands_alongside_vite!
      else
        puts "✓ Installing Vite for Islands"
        install_vite_from_scratch!
      end
      
      # Always run these (idempotent)
      create_islands_structure!
      create_vendor_system!
      inject_islands_helper!
      
      puts "\n🎉 IslandJS Rails initialized successfully!"
      print_next_steps
    end
    
    private
    
    def check_prerequisites!
      unless command_exists?('node')
        raise Error, "Node.js not found. Please install Node.js 16+ first."
      end
      
      unless command_exists?('yarn')
        puts "⚠️  Yarn not found, installing..."
        system('npm install -g yarn')
      end
    end
    
    def configure_islands_alongside_vite!
      # Vite already exists, just add Islands config
      create_islands_vite_config! unless vite_integration.islands_vite_config_exists?
      create_islands_entrypoint!
      update_package_json_for_islands!
      install_vite_dependencies!
    end
    
    def install_vite_from_scratch!
      # No Vite yet, install everything
      create_base_vite_config!
      create_islands_vite_config!
      create_islands_entrypoint!
      setup_package_json!
      install_vite_dependencies!
    end
    
    def create_base_vite_config!
      return if vite_integration.vite_config_exists?
      
      puts "✓ Creating base vite.config.ts"
      
      template = <<~TYPESCRIPT
        import { defineConfig } from 'vite'
        import react from '@vitejs/plugin-react'
        import path from 'path'
        
        export default defineConfig({
          plugins: [
            react(),
          ],
          resolve: {
            alias: {
              '@': path.resolve(__dirname, 'app/javascript')
            },
          },
        })
      TYPESCRIPT
      
      vite_integration.vite_config_path.write(template)
    end
    
    def create_islands_vite_config!
      return if vite_integration.islands_vite_config_exists?
      
      puts "✓ Creating vite.config.islands.ts"
      
      template_path = File.expand_path('../templates/vite.config.islands.ts', __dir__)
      FileUtils.cp(template_path, vite_integration.islands_vite_config_path)
    end
    
    def create_islands_entrypoint!
      entrypoint_path = root_path.join('app/javascript/entrypoints/islands.js')
      return if entrypoint_path.exist?
      
      puts "✓ Creating Islands entrypoint"
      
      FileUtils.mkdir_p(entrypoint_path.dirname)
      template_path = File.expand_path('../templates/app/javascript/entrypoints/islands.js', __dir__)
      FileUtils.cp(template_path, entrypoint_path)
    end
    
    def setup_package_json!
      if vite_integration.package_json_exists?
        update_package_json_for_islands!
      else
        create_package_json!
      end
    end
    
    def create_package_json!
      puts "✓ Creating package.json"
      
      package_json = {
        "private" => true,
        "type" => "module",
        "scripts" => {
          "build" => "vite build --emptyOutDir && yarn build:islands",
          "build:islands" => "vite build --config vite.config.islands.ts",
          "islands:watch" => "vite build --config vite.config.islands.ts --watch",
          "dev" => "vite dev"
        },
        "dependencies" => {},
        "devDependencies" => {}
      }
      
      vite_integration.write_package_json(package_json)
    end
    
    def update_package_json_for_islands!
      puts "✓ Updating package.json scripts"
      vite_integration.update_package_json_scripts!
    end
    
    def install_vite_dependencies!
      puts "📦 Installing Vite dependencies..."
      
      # Check what's already installed
      package_json = vite_integration.read_package_json
      dev_deps = package_json['devDependencies'] || {}
      
      deps_to_install = []
      
      # Required Vite dependencies
      deps_to_install << 'vite@^5.4.19' unless dev_deps.key?('vite')
      deps_to_install << '@vitejs/plugin-react@^5.0.0' unless dev_deps.key?('@vitejs/plugin-react')
      
      if deps_to_install.any?
        puts "  Installing: #{deps_to_install.join(', ')}"
        system("yarn add --dev #{deps_to_install.join(' ')}")
      else
        puts "  ✓ Vite dependencies already installed"
      end
    end
    
    def create_islands_structure!
      islands_dir = root_path.join('app/javascript/islands')
      
      if islands_dir.exist?
        puts "✓ Islands structure already exists"
        return
      end
      
      puts "✓ Creating Islands directory structure"
      
      # Create directories
      FileUtils.mkdir_p(islands_dir.join('components'))
      FileUtils.mkdir_p(islands_dir.join('utils'))
      
      # Copy HelloWorld component template
      hello_world_path = islands_dir.join('components/HelloWorld.jsx')
      unless hello_world_path.exist?
        template_path = File.expand_path('../templates/app/javascript/islands/components/HelloWorld.jsx', __dir__)
        FileUtils.cp(template_path, hello_world_path) if File.exist?(template_path)
      end
      
      # Copy Turbo utilities
      turbo_utils_path = islands_dir.join('utils/turbo.js')
      unless turbo_utils_path.exist?
        template_path = File.expand_path('../templates/app/javascript/islands/utils/turbo.js', __dir__)
        FileUtils.cp(template_path, turbo_utils_path) if File.exist?(template_path)
      end
    end
    
    def create_vendor_system!
      vendor_dir = root_path.join('public/vendor/islands')
      
      if vendor_dir.exist?
        puts "✓ Vendor system already exists"
        return
      end
      
      puts "✓ Creating vendor directory"
      FileUtils.mkdir_p(vendor_dir)
      
      # Create vendor UMD partial
      create_vendor_partial!
    end
    
    def create_vendor_partial!
      partials_dir = root_path.join('app/views/shared/islands')
      FileUtils.mkdir_p(partials_dir)
      
      partial_path = partials_dir.join('_vendor_umd.html.erb')
      return if partial_path.exist?
      
      puts "✓ Creating vendor UMD partial"
      
      # Create empty partial - will be populated when packages are installed
      partial_content = <<~ERB
        <%# IslandJS Rails - UMD Vendor Scripts %>
        <%# This partial is auto-generated. Run: rails islandjs:install[react] %>
      ERB
      
      partial_path.write(partial_content)
    end
    
    def inject_islands_helper!
      layout_path = vite_integration.islands_layout_path
      
      unless layout_path.exist?
        puts "⚠️  application.html.erb not found, skipping helper injection"
        return
      end
      
      if vite_integration.layout_has_islands_helper?
        puts "✓ Islands helper already in layout"
        return
      end
      
      puts "✓ Adding <%= islands %> to application.html.erb"
      
      content = layout_path.read
      
      # Try to inject before </head>
      if content.include?('</head>')
        updated = content.sub('</head>', "    <%= islands %>\n  </head>")
        layout_path.write(updated)
      else
        puts "  ⚠️  Could not find </head> tag, please add <%= islands %> manually"
      end
    end
    
    def print_next_steps
      puts "\n📋 Next steps:"
      puts "1. Install React UMD libraries:"
      puts "   rails \"islandjs:install[react,19.1.0]\""
      puts "   rails \"islandjs:install[react-dom,19.1.0]\""
      puts ""
      puts "2. Build Islands bundle:"
      puts "   yarn build:islands"
      puts ""
      puts "3. Use in ERB templates:"
      puts "   <%= react_component('HelloWorld', { message: 'Hello!' }) %>"
      puts ""
      
      if vite_integration.inertia_installed?
        puts "💡 Inertia detected! You now have both:"
        puts "   - Inertia SPA: yarn vite dev"
        puts "   - Islands: yarn islands:watch"
        puts "   - Build both: yarn build"
      else
        puts "💡 Start development:"
        puts "   yarn islands:watch"
      end
      
      puts ""
      puts "🚀 Ready to build Islands!"
    end
    
    def command_exists?(command)
      system("which #{command} > /dev/null 2>&1")
    end
  end
end
