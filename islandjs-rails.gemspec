require_relative "lib/islandjs_rails/version"

Gem::Specification.new do |spec|
  spec.name          = "islandjs-rails"
  spec.version       = IslandjsRails::VERSION
  spec.authors       = ["Eric Arnold"]
  spec.email         = ["ericarnold00+praxisemergent@gmail.com"]

  spec.summary       = "React components in Rails ERB templates with Turbo support"
  spec.description   = "IslandJS Rails enables Turbo-compatible React islands in Rails apps. Write React components, render them with a simple ERB helper, and get automatic state persistence across Turbo navigation."
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

    📋 Get started:

        rails islandjs:init
        yarn build:islands

  MSG

  # Rails integration
  spec.add_dependency "rails", ">= 7.0", "< 9.0"
  spec.add_dependency "thor", "~> 1.0"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "simplecov", "~> 0.22"

  # Ruby 4.0+ extracted these from stdlib
  spec.add_development_dependency "cgi"
end
