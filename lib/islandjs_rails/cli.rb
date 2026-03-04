require 'thor'

module IslandjsRails
  class CLI < Thor
    desc "init", "Initialize IslandJS in this Rails project"
    def init
      IslandjsRails.init!
    end

    desc "version", "Show IslandJS Rails version"
    def version
      puts "IslandjsRails #{IslandjsRails::VERSION}"
    end
  end
end
