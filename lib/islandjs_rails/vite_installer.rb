# frozen_string_literal: true

require 'fileutils'
require 'json'

module IslandjsRails
  # Scaffolds the Islands directory structure and templates
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
      inject_islands_helper!

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

    def print_next_steps
      puts "\n📋 Next steps:"
      puts "1. Add React to your project:"
      puts "   yarn add react react-dom"
      puts ""
      puts "2. Build your Islands bundle:"
      puts "   yarn build:islands"
      puts ""
      puts "3. Use in ERB templates:"
      puts "   <%= react_component('HelloWorld', { message: 'Hello!' }) %>"
    end

    def copy_template(relative_path)
      template_path = File.expand_path("../templates/#{relative_path}", __dir__)
      destination_path = root_path.join(relative_path)

      return unless File.exist?(template_path)

      FileUtils.mkdir_p(File.dirname(destination_path))
      FileUtils.cp(template_path, destination_path)
    end
  end
end
