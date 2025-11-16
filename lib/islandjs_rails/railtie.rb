require 'rails/railtie'

module IslandjsRails
  class Railtie < Rails::Railtie
    railtie_name :islandjs_rails

    rake_tasks do
      load File.expand_path('tasks.rb', __dir__)
    end

    initializer 'islandjs_rails.helpers' do
      ActiveSupport.on_load(:action_view) do
        include IslandjsRails::RailsHelpers
        include IslandjsRails::TurboStreams::Helpers
      end
    end

    # Development-only warnings and checks
    initializer 'islandjs_rails.development_warnings', after: :load_config_initializers do
      if Rails.env.development?
        # Check for common setup issues
        Rails.application.config.after_initialize do
          check_development_setup
        end
      end
    end

    private

    def check_development_setup
      # Check if package.json exists
      unless File.exist?(Rails.root.join('package.json'))
        Rails.logger.warn "IslandJS: package.json not found. Run 'rails islandjs:init' to set up."
        return
      end

      # Check if Vite Islands config exists
      unless File.exist?(Rails.root.join('vite.config.islands.ts'))
        Rails.logger.warn "IslandJS: vite.config.islands.ts not found. Run 'rails islandjs:init' to set up."
        return
      end

      # Check if yarn is available
      unless system('which yarn > /dev/null 2>&1')
        Rails.logger.warn "IslandJS: yarn not found. Please install yarn for package management."
        return
      end

      # Check if essential Vite dependencies are installed
      essential_deps = ['vite', '@vitejs/plugin-react']
      missing_deps = essential_deps.select do |dep|
        !system("yarn list #{dep} > /dev/null 2>&1")
      end

      unless missing_deps.empty?
        Rails.logger.warn "IslandJS: Missing dependencies: #{missing_deps.join(', ')}. Run 'yarn install'."
      end
    end
  end
end
