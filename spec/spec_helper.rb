require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'

  add_group 'Core', ['lib/islandjs_rails/core.rb', 'lib/islandjs_rails/core_methods.rb']
  add_group 'Installer', 'lib/islandjs_rails/vite_installer.rb'
  add_group 'Rails Integration', ['lib/islandjs_rails/rails_helpers.rb', 'lib/islandjs_rails/railtie.rb']
  add_group 'CLI', 'lib/islandjs_rails/cli.rb'

  minimum_coverage 80
  minimum_coverage_by_file 30
end

require 'bundler/setup'
require 'islandjs_rails'
require 'rails'
require 'action_view'
require 'tempfile'
require 'fileutils'

# Rails test environment setup
ENV['RAILS_ENV'] = 'test'

# Create a minimal Rails application for testing
class TestApp < Rails::Application
  config.eager_load = false
  config.active_support.deprecation = :log
  config.log_level = :fatal
  config.root = File.expand_path('../../tmp', __FILE__)
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    @temp_dirs = []
    @original_rails_root = Rails.root if defined?(Rails)
  end

  config.after(:each) do
    @temp_dirs.each do |dir|
      FileUtils.rm_rf(dir) if Dir.exist?(dir)
    end

    # Reset IslandjsRails singletons
    IslandjsRails.instance_variable_set(:@configuration, nil)
    IslandjsRails.instance_variable_set(:@core, nil)
  end

  config.after(:suite) do
    # Clean up any accidentally created app/ directory in project root
    project_root = File.expand_path('../..', __FILE__)
    app_dir = File.join(project_root, 'app')
    FileUtils.rm_rf(app_dir) if Dir.exist?(app_dir)
  end

  config.include Module.new {
    def create_temp_dir
      dir = Dir.mktmpdir
      @temp_dirs << dir
      dir
    end

    def create_temp_package_json(dir, dependencies = {})
      package_json = {
        'name' => 'test-app',
        'version' => '1.0.0',
        'dependencies' => dependencies
      }
      File.write(File.join(dir, 'package.json'), JSON.pretty_generate(package_json))
    end

    def mock_rails_root(path)
      allow(Rails).to receive(:root).and_return(Pathname.new(path))
    end
  }
end
