require_relative '../../spec_helper'
require 'islandjs_rails/vite_installer'

RSpec.describe IslandjsRails::ViteInstaller do
  let(:temp_dir) { create_temp_dir }
  let(:installer) { described_class.new(temp_dir) }

  before do
    # Suppress yarn commands in tests
    allow_any_instance_of(described_class).to receive(:yarn_available?).and_return(false)
  end

  describe '#install!' do
    it 'creates islands directory structure' do
      expect { installer.install! }.to output(/Initializing IslandJS Rails/).to_stdout

      islands_dir = File.join(temp_dir, 'app', 'javascript', 'islands')
      expect(Dir.exist?(File.join(islands_dir, 'components'))).to be true
      expect(Dir.exist?(File.join(islands_dir, 'utils'))).to be true
    end

    it 'creates the entrypoint file' do
      expect { installer.install! }.to output(/Initializing/).to_stdout

      entrypoint = File.join(temp_dir, 'app', 'javascript', 'entrypoints', 'islands.js')
      expect(File.exist?(entrypoint)).to be true
    end

    it 'creates vite.config.islands.ts' do
      expect { installer.install! }.to output(/Creating vite\.config\.islands\.ts/).to_stdout

      vite_config = File.join(temp_dir, 'vite.config.islands.ts')
      expect(File.exist?(vite_config)).to be true

      content = File.read(vite_config)
      expect(content).to include('defineConfig')
      expect(content).to include('islands.js')
      expect(content).to include("formats: ['iife']")
    end

    it 'creates package.json with build scripts when none exists' do
      expect { installer.install! }.to output(/Creating package\.json/).to_stdout

      package_json = JSON.parse(File.read(File.join(temp_dir, 'package.json')))
      expect(package_json['scripts']['build:islands']).to include('vite build')
      expect(package_json['scripts']['watch:islands']).to include('--watch')
    end

    it 'adds build scripts to existing package.json' do
      File.write(File.join(temp_dir, 'package.json'), JSON.generate({
        'name' => 'test-app',
        'dependencies' => {}
      }))

      expect { installer.install! }.to output(/Adding build scripts/).to_stdout

      package_json = JSON.parse(File.read(File.join(temp_dir, 'package.json')))
      expect(package_json['scripts']['build:islands']).to include('vite build')
    end

    it 'is idempotent for directory structure' do
      expect { installer.install! }.to output(/Creating Islands directory structure/).to_stdout
      expect { installer.install! }.to output(/already exists/).to_stdout
    end

    it 'is idempotent for entrypoint' do
      entrypoint_dir = File.join(temp_dir, 'app', 'javascript', 'entrypoints')
      FileUtils.mkdir_p(entrypoint_dir)
      File.write(File.join(entrypoint_dir, 'islands.js'), '// existing')

      expect { installer.install! }.to output(/Initializing/).to_stdout
      content = File.read(File.join(entrypoint_dir, 'islands.js'))
      expect(content).to eq('// existing')
    end

    it 'is idempotent for vite config' do
      vite_path = File.join(temp_dir, 'vite.config.islands.ts')
      File.write(vite_path, '// custom config')

      expect { installer.install! }.to output(/Vite config already exists/).to_stdout
      expect(File.read(vite_path)).to eq('// custom config')
    end

    it 'injects islands helper into layout' do
      layout_dir = File.join(temp_dir, 'app', 'views', 'layouts')
      FileUtils.mkdir_p(layout_dir)
      File.write(File.join(layout_dir, 'application.html.erb'), <<~HTML)
        <html>
        <head>
          <title>Test</title>
        </head>
        <body></body>
        </html>
      HTML

      expect { installer.install! }.to output(/Adding.*islands.*to application/).to_stdout

      content = File.read(File.join(layout_dir, 'application.html.erb'))
      expect(content).to include('<%= islands %>')
    end

    it 'skips layout injection when helper already present' do
      layout_dir = File.join(temp_dir, 'app', 'views', 'layouts')
      FileUtils.mkdir_p(layout_dir)
      File.write(File.join(layout_dir, 'application.html.erb'), <<~HTML)
        <html>
        <head>
          <%= islands %>
        </head>
        <body></body>
        </html>
      HTML

      expect { installer.install! }.to output(/Islands helper already in layout/).to_stdout
    end

    it 'warns when no layout file found' do
      expect { installer.install! }.to output(/application\.html\.erb not found/).to_stdout
    end
  end

  describe 'dependency installation' do
    it 'installs dependencies when yarn is available' do
      allow_any_instance_of(described_class).to receive(:yarn_available?).and_return(true)
      allow_any_instance_of(described_class).to receive(:package_has_dependency?).and_return(false)
      expect_any_instance_of(described_class).to receive(:system).with(/yarn add react react-dom/, anything).and_return(true)
      expect_any_instance_of(described_class).to receive(:system).with(/yarn add --dev vite/, anything).and_return(true)

      expect { installer.install! }.to output(/Installing dependencies/).to_stdout
    end

    it 'skips installation when all dependencies present' do
      allow_any_instance_of(described_class).to receive(:yarn_available?).and_return(true)
      allow_any_instance_of(described_class).to receive(:package_has_dependency?).and_return(true)

      expect { installer.install! }.to output(/All dependencies already installed/).to_stdout
    end

    it 'shows manual instructions when yarn is not available' do
      expect { installer.install! }.to output(/Install Node\.js and Yarn/).to_stdout
    end
  end
end
