require 'rake'

namespace :islandjs do
  desc "Initialize IslandJS in this Rails project"
  task :init => :environment do
    IslandjsRails.init!
  end

  desc "Show IslandJS version"
  task :version do
    puts "IslandjsRails #{IslandjsRails::VERSION}"
  end
end
