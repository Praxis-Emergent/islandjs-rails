module IslandjsRails
  class Core
    # Demo route functionality

    def offer_demo_route!
      if demo_route_exists?
        puts "✓ Demo route already exists at /islandjs/react"
        return
      end

      unless STDIN.tty?
        puts "\n💡 To render your HelloWorld component:"
        puts "   In any view: <%= react_component('HelloWorld') %>"
        return
      end

      print "\n❓ Would you like to create a demo route at /islandjs/react to showcase your HelloWorld component? (y/n): "
      answer = STDIN.gets&.chomp&.downcase

      if answer == 'y' || answer == 'yes'
        create_demo_route!
        puts "\n🎉 Demo route created! Visit http://localhost:3000/islandjs/react to see your React component in action."
        puts "💡 You can remove it later by deleting the route, controller, and view manually."
      else
        puts "\n💡 No problem! Here's how to render your HelloWorld component manually:"
        puts "   In any view: <%= react_component('HelloWorld') %>"
      end
    end

    def demo_route_exists?
      routes_file = File.join(root_path, 'config', 'routes.rb')
      return false unless File.exist?(routes_file)

      content = File.read(routes_file)
      content.include?('islandjs_demo') || content.include?('islandjs/react') || content.include?("get 'islandjs'")
    end

    def create_demo_route!
      create_demo_controller!
      create_demo_view!
      add_demo_route!
    end

    def create_demo_controller!
      controller_dir = File.join(root_path, 'app', 'controllers')
      FileUtils.mkdir_p(controller_dir)

      controller_file = File.join(controller_dir, 'islandjs_demo_controller.rb')
      copy_template_file('app/controllers/islandjs_demo_controller.rb', controller_file)
    end

    def create_demo_view!
      view_dir = File.join(root_path, 'app', 'views', 'islandjs_demo')
      FileUtils.mkdir_p(view_dir)

      copy_demo_template('index.html.erb', view_dir)
      copy_demo_template('react.html.erb', view_dir)
    end

    def copy_demo_template(template_name, destination_dir)
      gem_root = File.expand_path('../../..', __FILE__)
      template_path = File.join(gem_root, 'lib', 'templates', 'app', 'views', 'islandjs_demo', template_name)
      destination_path = File.join(destination_dir, template_name)

      if File.exist?(template_path)
        FileUtils.cp(template_path, destination_path)
        puts "  ✓ Created #{template_name} at app/views/islandjs_demo/#{template_name}"
      else
        puts "  ⚠️  Template not found: #{template_path}"
      end
    end

    def copy_template_file(template_name, destination_path)
      gem_root = File.expand_path('../../..', __FILE__)
      template_path = File.join(gem_root, 'lib', 'templates', template_name)

      if File.exist?(template_path)
        FileUtils.cp(template_path, destination_path)
        puts "  ✓ Created #{File.basename(template_name)} from template"
      else
        puts "  ⚠️  Template not found: #{template_path}"
      end
    end

    def get_demo_routes_content(indent, has_root_route)
      gem_root = File.expand_path('../../..', __FILE__)
      template_path = File.join(gem_root, 'lib', 'templates', 'config', 'demo_routes.rb')

      if File.exist?(template_path)
        routes_content = File.read(template_path)
        route_lines = routes_content.lines.map { |line| "#{indent}#{line}" }.join

        unless has_root_route
          root_route = "#{indent}root 'islandjs_demo#index'\n"
          route_lines = root_route + route_lines
        end

        route_lines
      else
        route_lines = "#{indent}# IslandJS demo routes (you can remove these)\n"
        unless has_root_route
          route_lines += "#{indent}root 'islandjs_demo#index'\n"
        end
        route_lines += "#{indent}get 'islandjs', to: 'islandjs_demo#index'\n"
        route_lines += "#{indent}get 'islandjs/react', to: 'islandjs_demo#react'\n"
        route_lines
      end
    end

    def add_demo_route!
      routes_file = File.join(root_path, 'config', 'routes.rb')
      return unless File.exist?(routes_file)

      content = File.read(routes_file)

      has_root_route = content.include?('root ') || content.match(/^\s*root\s/)

      if content.match(/Rails\.application\.routes\.draw do\s*$/)
        indent = content.match(/^(\s*)Rails\.application\.routes\.draw do\s*$/)[1]

        route_lines = get_demo_routes_content(indent, has_root_route)

        updated_content = content.sub(
          /(Rails\.application\.routes\.draw do\s*$)/,
          "\\1\n#{route_lines}"
        )

        File.write(routes_file, updated_content)
        puts "  ✓ Added demo routes to config/routes.rb:"
        unless has_root_route
          puts "     root 'islandjs_demo#index' (set as homepage)"
        end
        puts "     get 'islandjs', to: 'islandjs_demo#index'"
        puts "     get 'islandjs/react', to: 'islandjs_demo#react'"
      end
    end

    private

    def root_path
      defined?(Rails) && Rails.respond_to?(:root) ? Rails.root : Pathname.new(Dir.pwd)
    end
  end
end
