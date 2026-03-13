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
      end
    end

    initializer 'islandjs_rails.development_warnings', after: :load_config_initializers do
      if Rails.env.development?
        Rails.application.config.after_initialize do
          check_development_setup
        end
      end
    end

    private

    def check_development_setup
      manifest = Rails.root.join('public/islands/.vite/manifest.json')
      unless File.exist?(manifest)
        Rails.logger.warn "IslandJS: Bundle manifest not found. Build your Islands bundle to enable React components."
      end
    end
  end
end
