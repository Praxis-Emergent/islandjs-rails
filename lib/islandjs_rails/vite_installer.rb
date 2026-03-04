# frozen_string_literal: true

require 'fileutils'
require 'json'

module IslandjsRails
  # Scaffolds the Islands directory structure, build config, and templates
  class ViteInstaller
    attr_reader :root_path

    def initialize(root_path = Rails.root)
      @root_path = Pathname.new(root_path)
    end

    # Main installation method - fully idempotent
    def install!
      puts "🏝️  Initializing IslandJS Rails..."

      create_islands_structure!
      create_entrypoint!
      create_vite_config!
      ensure_package_json!
      inject_islands_helper!
      install_dependencies!

      puts "\n🎉 IslandJS Rails initialized successfully!"
      print_next_steps
    end

    private

    def create_islands_structure!
      islands_dir = root_path.join('app/javascript/islands')

      if islands_dir.exist?
        puts "✓ Islands structure already exists"
        return
      end

      puts "✓ Creating Islands directory structure"

      FileUtils.mkdir_p(islands_dir.join('components'))
      FileUtils.mkdir_p(islands_dir.join('utils'))

      # Copy HelloWorld component template
      copy_template('app/javascript/islands/components/HelloWorld.jsx')

      # Copy Turbo utilities
      copy_template('app/javascript/islands/utils/turbo.js')
    end

    def create_entrypoint!
      entrypoint_path = root_path.join('app/javascript/entrypoints/islands.js')
      return if entrypoint_path.exist?

      puts "✓ Creating Islands entrypoint"
      FileUtils.mkdir_p(entrypoint_path.dirname)
      copy_template('app/javascript/entrypoints/islands.js')
    end

    def create_vite_config!
      vite_config_path = root_path.join('vite.config.islands.ts')

      if vite_config_path.exist?
        puts "✓ Vite config already exists"
        return
      end

      puts "✓ Creating vite.config.islands.ts"
      copy_template('vite.config.islands.ts', destination: vite_config_path)
    end

    def ensure_package_json!
      package_json_path = root_path.join('package.json')

      if package_json_path.exist?
        add_build_scripts!(package_json_path)
      else
        create_package_json!(package_json_path)
      end
    end

    def inject_islands_helper!
      layout_path = root_path.join('app/views/layouts/application.html.erb')

      unless layout_path.exist?
        puts "⚠️  application.html.erb not found, skipping helper injection"
        return
      end

      content = layout_path.read

      if content.include?('<%= islands %>') || content.include?('islands %>')
        puts "✓ Islands helper already in layout"
        return
      end

      puts "✓ Adding <%= islands %> to application.html.erb"

      if content.include?('</head>')
        updated = content.sub('</head>', "    <%= islands %>\n  </head>")
        layout_path.write(updated)
      else
        puts "  ⚠️  Could not find </head> tag, please add <%= islands %> manually"
      end
    end

    def install_dependencies!
      return unless yarn_available?

      deps = %w[react react-dom]
      dev_deps = %w[vite @vitejs/plugin-react]

      missing_deps = deps.reject { |d| package_has_dependency?(d) }
      missing_dev_deps = dev_deps.reject { |d| package_has_dependency?(d) }

      if missing_deps.empty? && missing_dev_deps.empty?
        puts "✓ All dependencies already installed"
        return
      end

      puts "✓ Installing dependencies..."

      if missing_deps.any?
        system("yarn add #{missing_deps.join(' ')}", chdir: root_path.to_s)
      end

      if missing_dev_deps.any?
        system("yarn add --dev #{missing_dev_deps.join(' ')}", chdir: root_path.to_s)
      end
    end

    def print_next_steps
      steps = []

      unless yarn_available?
        steps << "1. Install Node.js and Yarn, then run:\n   yarn add react react-dom\n   yarn add --dev vite @vitejs/plugin-react"
      end

      steps << "#{steps.length + 1}. Build your Islands bundle:\n   yarn build:islands"
      steps << "#{steps.length + 1}. Use in ERB templates:\n   <%= react_component('HelloWorld', { message: 'Hello!' }) %>"

      puts "\n📋 Next steps:"
      steps.each { |s| puts s; puts "" }
    end

    def copy_template(relative_path, destination: nil)
      template_path = File.expand_path("../templates/#{relative_path}", __dir__)
      destination_path = destination || root_path.join(relative_path)

      return unless File.exist?(template_path)

      FileUtils.mkdir_p(File.dirname(destination_path))
      FileUtils.cp(template_path, destination_path)
    end

    def yarn_available?
      @yarn_available = system('which yarn > /dev/null 2>&1') if @yarn_available.nil?
      @yarn_available
    end

    def package_has_dependency?(name)
      package_json_path = root_path.join('package.json')
      return false unless package_json_path.exist?

      data = JSON.parse(package_json_path.read)
      (data['dependencies'] || {}).key?(name) || (data['devDependencies'] || {}).key?(name)
    rescue JSON::ParserError
      false
    end

    def create_package_json!(path)
      puts "✓ Creating package.json"

      data = {
        'name' => root_path.basename.to_s.downcase.gsub(/[^a-z0-9_-]/, '-'),
        'private' => true,
        'scripts' => build_scripts
      }

      File.write(path, JSON.pretty_generate(data) + "\n")
    end

    def add_build_scripts!(path)
      data = JSON.parse(File.read(path))
      data['scripts'] ||= {}

      added = false
      build_scripts.each do |key, value|
        unless data['scripts'].key?(key)
          data['scripts'][key] = value
          added = true
        end
      end

      if added
        puts "✓ Adding build scripts to package.json"
        File.write(path, JSON.pretty_generate(data) + "\n")
      else
        puts "✓ Build scripts already in package.json"
      end
    rescue JSON::ParserError
      puts "⚠️  Could not parse package.json, please add build scripts manually"
    end

    def build_scripts
      {
        'build:islands' => 'vite build --config vite.config.islands.ts',
        'watch:islands' => 'vite build --config vite.config.islands.ts --watch'
      }
    end
  end
end
