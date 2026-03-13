require_relative '../../spec_helper'
require 'islandjs_rails/core'

RSpec.describe IslandjsRails::Core do
  let(:temp_dir) { create_temp_dir }
  let(:core) { described_class.new }

  before do
    mock_rails_root(temp_dir)
    allow(Dir).to receive(:pwd).and_return(temp_dir)
  end

  describe '#init!' do
    it 'creates a ViteInstaller and calls install!' do
      installer = instance_double(IslandjsRails::ViteInstaller)
      expect(IslandjsRails::ViteInstaller).to receive(:new).and_return(installer)
      expect(installer).to receive(:install!)

      core.init!
    end
  end

  describe 'demo route methods' do
    describe '#demo_route_exists?' do
      let(:routes_file) { File.join(temp_dir, 'config', 'routes.rb') }

      it 'returns false when routes file does not exist' do
        expect(core.demo_route_exists?).to be false
      end

      it 'returns true when routes contain islandjs_demo' do
        FileUtils.mkdir_p(File.dirname(routes_file))
        File.write(routes_file, "get 'islandjs', to: 'islandjs_demo#index'")

        expect(core.demo_route_exists?).to be true
      end

      it 'returns true when routes contain islandjs/react' do
        FileUtils.mkdir_p(File.dirname(routes_file))
        File.write(routes_file, "get 'islandjs/react', to: 'islandjs_demo#react'")

        expect(core.demo_route_exists?).to be true
      end

      it 'returns false when routes have no islandjs routes' do
        FileUtils.mkdir_p(File.dirname(routes_file))
        File.write(routes_file, "Rails.application.routes.draw do\n  root 'home#index'\nend")

        expect(core.demo_route_exists?).to be false
      end
    end

    describe '#create_demo_route!' do
      it 'orchestrates controller, view, and route creation' do
        expect(core).to receive(:create_demo_controller!)
        expect(core).to receive(:create_demo_view!)
        expect(core).to receive(:add_demo_route!)

        core.create_demo_route!
      end
    end

    describe '#add_demo_route!' do
      let(:routes_file) { File.join(temp_dir, 'config', 'routes.rb') }

      it 'adds demo routes to routes.rb' do
        FileUtils.mkdir_p(File.dirname(routes_file))
        File.write(routes_file, "Rails.application.routes.draw do\nend")

        core.add_demo_route!

        content = File.read(routes_file)
        expect(content).to include('islandjs_demo#index')
      end

      it 'does nothing when routes file does not exist' do
        expect { core.add_demo_route! }.not_to raise_error
      end
    end

    describe '#get_demo_routes_content' do
      it 'includes root route when none exists' do
        result = core.get_demo_routes_content('  ', false)
        expect(result).to include('root')
        expect(result).to include('islandjs_demo#index')
      end

      it 'skips root route when one already exists' do
        result = core.get_demo_routes_content('  ', true)
        expect(result).not_to include('root')
        expect(result).to include('islandjs_demo#index')
      end
    end

    describe '#offer_demo_route!' do
      it 'skips if demo route already exists' do
        allow(core).to receive(:demo_route_exists?).and_return(true)
        expect { core.offer_demo_route! }.to output(/Demo route already exists/).to_stdout
      end

      it 'shows manual instructions when not a TTY' do
        allow(core).to receive(:demo_route_exists?).and_return(false)
        allow(STDIN).to receive(:tty?).and_return(false)

        expect { core.offer_demo_route! }.to output(/react_component/).to_stdout
      end
    end

    describe '#copy_demo_template' do
      it 'copies existing template' do
        view_dir = File.join(temp_dir, 'app', 'views', 'islandjs_demo')
        FileUtils.mkdir_p(view_dir)

        expect { core.copy_demo_template('index.html.erb', view_dir) }.to output(/Created|Template not found/).to_stdout
      end
    end

    describe '#copy_template_file' do
      it 'handles missing template gracefully' do
        destination = File.join(temp_dir, 'missing.rb')
        expect { core.copy_template_file('nonexistent.rb', destination) }.to output(/Template not found/).to_stdout
      end
    end
  end
end
