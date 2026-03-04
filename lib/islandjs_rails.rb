require_relative "islandjs_rails/version"
require_relative "islandjs_rails/configuration"
require_relative "islandjs_rails/core"
require_relative "islandjs_rails/cli"

if defined?(Rails)
  require_relative "islandjs_rails/railtie"
  require_relative "islandjs_rails/rails_helpers"
end

module IslandjsRails
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def core
      @core ||= Core.new
    end

    def init!
      core.init!
    end
  end
end
