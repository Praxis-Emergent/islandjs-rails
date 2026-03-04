require 'json'
require 'fileutils'

module IslandjsRails
  class Core
    def init!
      require_relative 'vite_installer'

      installer = ViteInstaller.new
      installer.install!
    end

    private

    def root_path
      defined?(Rails) && Rails.respond_to?(:root) ? Rails.root : Pathname.new(Dir.pwd)
    end
  end
end

require_relative 'core_methods'
