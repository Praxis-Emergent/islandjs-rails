require_relative '../../spec_helper'
require 'islandjs_rails/rails_helpers'

RSpec.describe IslandjsRails::RailsHelpers do
  let(:temp_dir) { create_temp_dir }
  let(:view_context) {
    Class.new do
      include IslandjsRails::RailsHelpers
      include ActionView::Helpers::TagHelper

      def asset_path(path)
        "/assets/#{path}"
      end

      private

      def html_escape(value)
        ERB::Util.html_escape(value.to_s)
      end
    end.new
  }

  before do
    mock_rails_root(temp_dir)
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
  end

  describe '#islands' do
    it 'delegates to island_bundle_script' do
      expect(view_context).to receive(:island_bundle_script).and_return('script tag')
      view_context.islands
    end
  end

  describe '#island_bundle_script' do
    let(:manifest_path) { File.join(temp_dir, 'public', 'islands', '.vite', 'manifest.json') }

    context 'when manifest exists with valid entry' do
      before do
        FileUtils.mkdir_p(File.dirname(manifest_path))
        manifest = {
          'app/javascript/entrypoints/islands.js' => {
            'file' => 'islands_bundle.abc123.js'
          }
        }
        File.write(manifest_path, JSON.generate(manifest))
      end

      it 'returns script tag with hashed filename' do
        result = view_context.island_bundle_script
        expect(result).to include('<script src="/islands/islands_bundle.abc123.js"')
        expect(result).to include('defer')
      end

      it 'returns html safe string' do
        result = view_context.island_bundle_script
        expect(result).to be_html_safe
      end
    end

    context 'when manifest does not exist' do
      it 'returns build hint in development' do
        result = view_context.island_bundle_script
        expect(result).to include('Islands bundle not built')
        expect(result).to include('yarn build:islands')
      end

      it 'returns generic comment in production' do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        result = view_context.island_bundle_script
        expect(result).to include('Islands bundle missing')
        expect(result).not_to include('yarn')
      end
    end

    context 'when manifest is malformed JSON' do
      before do
        FileUtils.mkdir_p(File.dirname(manifest_path))
        File.write(manifest_path, 'invalid json{')
      end

      it 'returns parse error comment' do
        result = view_context.island_bundle_script
        expect(result).to include('Islands manifest parse error')
      end
    end

    context 'when manifest lacks islands entry' do
      before do
        FileUtils.mkdir_p(File.dirname(manifest_path))
        manifest = { 'other_bundle.js' => { 'file' => 'other.hash.js' } }
        File.write(manifest_path, JSON.generate(manifest))
      end

      it 'returns entry not found comment' do
        result = view_context.island_bundle_script
        expect(result).to include('Islands entry not found in manifest')
      end
    end
  end

  describe '#react_component' do
    it 'generates container div and mount script' do
      result = view_context.react_component('MyComponent', { userId: 123 })

      expect(result).to match(/id="react-my-component-[a-f0-9]{8}"/)
      expect(result).to include('data-user-id="123"')
      expect(result).to include('data-initial-state=')
      expect(result).to include('window.islandjsRails.MyComponent')
      expect(result).to include('function mountMyComponent()')
      expect(result).to include('function cleanupMyComponent()')
    end

    it 'includes Turbo event listeners' do
      result = view_context.react_component('MyComponent', {})

      expect(result).to include("addEventListener('turbo:load'")
      expect(result).to include("addEventListener('turbo:before-cache'")
    end

    it 'supports React 18 createRoot and React 17 fallback' do
      result = view_context.react_component('MyComponent', {})

      expect(result).to include('window.ReactDOM.createRoot')
      expect(result).to include('container._reactRoot')
      expect(result).to include('window.ReactDOM.render')
    end

    it 'allows custom container ID' do
      result = view_context.react_component('Widget', {}, { container_id: 'custom-id' })
      expect(result).to include('id="custom-id"')
    end

    it 'supports custom namespace' do
      result = view_context.react_component('Widget', {}, { namespace: 'window.MyApp' })
      expect(result).to include('window.MyApp?.Widget')
    end

    it 'uses default islandjsRails namespace' do
      result = view_context.react_component('Widget', {})
      expect(result).to include('window.islandjsRails.Widget')
    end

    it 'generates unique container IDs' do
      result1 = view_context.react_component('Component1', {})
      result2 = view_context.react_component('Component2', {})

      id1 = result1.match(/id="(react-component1-[a-f0-9]{8})"/)[1]
      id2 = result2.match(/id="(react-component2-[a-f0-9]{8})"/)[1]
      expect(id1).not_to eq(id2)
    end

    it 'handles empty props' do
      result = view_context.react_component('EmptyComponent', {})
      expect(result).to include('data-initial-state="{}"')
    end

    it 'includes containerId in mount props' do
      result = view_context.react_component('MyComponent', {})
      expect(result).to include("const props = { containerId:")
    end
  end

  describe '#react_component HTML escaping' do
    it 'escapes special characters in props' do
      result = view_context.react_component('TestComponent', {
        message: '<script>alert("xss")</script>',
        quote: 'He said "hello"'
      })

      expect(result).to include('&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;')
      expect(result).to include('He said &quot;hello&quot;')
    end

    it 'handles nil props' do
      result = view_context.react_component('TestComponent', {
        value: nil,
        name: 'test'
      })

      expect(result).to include('data-value=""')
      expect(result).to include('data-name="test"')
    end

    it 'converts camelCase and snake_case prop names to data attributes' do
      result = view_context.react_component('TestComponent', {
        userName: 'john',
        user_email: 'john@example.com'
      })

      expect(result).to include('data-user-name="john"')
      expect(result).to include('data-user-email="john@example.com"')
    end
  end

  describe '#react_component placeholder support' do
    it 'supports placeholder class' do
      result = view_context.react_component('MyComponent', {}, {
        placeholder_class: 'loading-spinner'
      })

      expect(result).to include('data-island-placeholder="true"')
      expect(result).to include('class="loading-spinner"')
    end

    it 'supports placeholder style' do
      result = view_context.react_component('MyComponent', {}, {
        placeholder_style: 'height: 200px'
      })

      expect(result).to include('data-island-placeholder="true"')
      expect(result).to include('style="height: 200px"')
    end
  end

  describe '#island_component' do
    it 'delegates to react_component for react framework' do
      result = view_context.island_component('react', 'MyComponent', { id: 1 })
      expect(result).to include('MyComponent')
      expect(result).to include('data-id="1"')
    end

    it 'returns error comment for unsupported frameworks' do
      result = view_context.island_component('vue', 'MyComponent', {})
      expect(result).to include('Unsupported framework: vue')
    end
  end

  describe '#island_debug' do
    it 'returns debug info in development' do
      result = view_context.island_debug
      expect(result).to include('IslandJS Debug Info')
      expect(result).to include('Bundle manifest:')
      expect(result).to include('Components:')
    end

    it 'returns empty string in production' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      result = view_context.island_debug
      expect(result).to eq('')
    end
  end

  describe 'CSP nonce support' do
    let(:nonce_view_context) {
      Class.new do
        include IslandjsRails::RailsHelpers
        include ActionView::Helpers::TagHelper

        def content_security_policy_nonce
          'test-nonce-123'
        end

        private

        def html_escape(value)
          ERB::Util.html_escape(value.to_s)
        end
      end.new
    }

    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
    end

    it 'auto-includes nonce in bundle script tag' do
      manifest_path = File.join(temp_dir, 'public', 'islands', '.vite', 'manifest.json')
      FileUtils.mkdir_p(File.dirname(manifest_path))
      manifest = { 'app/javascript/entrypoints/islands.js' => { 'file' => 'bundle.js' } }
      File.write(manifest_path, JSON.generate(manifest))

      result = nonce_view_context.island_bundle_script
      expect(result).to include('nonce="test-nonce-123"')
    end

    it 'auto-includes nonce in component mount scripts' do
      result = nonce_view_context.react_component('MyComponent', {})
      expect(result).to include('nonce="test-nonce-123"')
    end
  end
end
