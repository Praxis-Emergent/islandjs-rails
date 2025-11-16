require_relative "lib/islandjs_rails/version"

Gem::Specification.new do |spec|
  spec.name          = "islandjs-rails"
  spec.version       = IslandjsRails::VERSION
  spec.authors       = ["Eric Arnold"]
  spec.email         = ["ericarnold00+praxisemergent@gmail.com"]

  spec.summary       = "Simple, modern JavaScript islands for Rails"
  spec.description   = "IslandJS Rails enables React and other JavaScript islands in Rails apps with zero build configuration. Load UMD libraries from CDNs, integrate with ERB partials, and render components with Turbo-compatible lifecycle management."
  spec.homepage      = "https://github.com/praxis-emergent/islandjs-rails"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/praxis-emergent/islandjs-rails"
  spec.metadata["changelog_uri"] = "https://github.com/praxis-emergent/islandjs-rails/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://github.com/praxis-emergent/islandjs-rails/blob/main/README.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    Dir.glob("{lib,exe,templates}/**/*", File::FNM_DOTMATCH).reject do |f|
      File.directory?(f) ||
        (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github .claude appveyor Gemfile]) ||
        f.match?(%r{\A(\.rspec|Rakefile)\z}) ||
        f.end_with?(".gem")
    end + %w[README.md LICENSE.md CHANGELOG.md]
  end
  
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Post-install message
  spec.post_install_message = <<~MSG
    
    🏝️ IslandJS Rails installed successfully!
    
    📋 Next step: Initialize IslandJS in your Rails app

        rails islandjs:init
    
    This will set up Vite for Islands architecture alongside your existing setup.
    
  MSG

  # Rails integration
  spec.add_dependency "rails", ">= 7.0", "< 9.0"
  spec.add_dependency "thor", "~> 1.0"
  
  # Note: Vite is installed via npm/yarn, not as a Ruby gem
  # IslandJS uses Vite directly through CLI commands
  
  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
end 
