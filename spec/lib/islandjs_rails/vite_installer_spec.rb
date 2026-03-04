require_relative '../../spec_helper'
require 'islandjs_rails/vite_installer'

RSpec.describe IslandjsRails::ViteInstaller do
  let(:temp_dir) { create_temp_dir }
  let(:installer) { described_class.new(temp_dir) }

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

    it 'is idempotent for directory structure' do
      # First run
      expect { installer.install! }.to output(/Creating Islands directory structure/).to_stdout

      # Second run should detect existing structure
      expect { installer.install! }.to output(/already exists/).to_stdout
    end

    it 'is idempotent for entrypoint' do
      # Create entrypoint directory and file manually
      entrypoint_dir = File.join(temp_dir, 'app', 'javascript', 'entrypoints')
      FileUtils.mkdir_p(entrypoint_dir)
      File.write(File.join(entrypoint_dir, 'islands.js'), '// existing')

      # Should not overwrite
      expect { installer.install! }.to output(/Initializing/).to_stdout
      content = File.read(File.join(entrypoint_dir, 'islands.js'))
      expect(content).to eq('// existing')
    end

    it 'injects islands helper into layout' do
      # Create a layout file
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
      # No layout file exists
      expect { installer.install! }.to output(/application\.html\.erb not found/).to_stdout
    end
  end
end
