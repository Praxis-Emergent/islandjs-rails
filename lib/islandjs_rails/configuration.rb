require 'pathname'

module IslandjsRails
  class Configuration
    # IslandJS Rails 2.0 uses convention over configuration.
    # The bundle manifest is expected at public/islands/.vite/manifest.json
    # Components go in app/javascript/islands/components/
    def initialize
    end
  end
end
