# frozen_string_literal: true

require 'rails/generators'

module IslandjsRails
  module Generators
    # Generates a React-enhanced chat UI that works with RubyLLM
    # Adds streaming support via Turbo Streams + React islands
    class ChatUIGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      namespace 'islandjs_rails:chat_ui'

      desc 'Creates a streaming chat UI with React islands for RubyLLM'

      class_option :namespace,
                   type: :string,
                   default: 'islandjs',
                   desc: 'Namespace for routes and models (e.g., islandjs, admin)'

      def check_dependencies
        # Check for RubyLLM
        unless defined?(RubyLLM)
          say "⚠️  RubyLLM not found. Installing basic chat scaffolding.", :yellow
          say "   Add 'gem \"ruby_llm\"' to your Gemfile for full functionality.", :yellow
        end

        # Check if Message model exists (from ruby_llm:install or ruby_llm:chat_ui)
        if !File.exist?('app/models/message.rb') && namespace_option.empty?
          raise Thor::Error, <<~ERROR
            Message model not found. Please run one of:
              1. rails generate ruby_llm:install
              2. rails generate ruby_llm:chat_ui
            
            Then run this generator to enhance it with React islands.
          ERROR
        end
      end

      def check_islandjs_setup
        unless File.exist?('public/islands/vendor/react.production.min.js') ||
               File.exist?('public/islands/vendor/react.js')
          say "\n⚠️  React not installed. Installing React...", :yellow
          run 'rails "islandjs:install[react]"'
          run 'rails "islandjs:install[react-dom]"'
        end
      end

      def create_components
        say "Creating React components for streaming chat...", :cyan
        
        # Copy React components to app/javascript/islands/components/
        template 'components/ChatMessage.jsx',
                 'app/javascript/islands/components/ChatMessage.jsx'
        template 'components/StreamingContent.jsx',
                 'app/javascript/islands/components/StreamingContent.jsx'
        template 'components/ChatContainer.jsx',
                 'app/javascript/islands/components/ChatContainer.jsx'
      end

      def create_island_streaming_concern
        say "Adding IslandStreaming concern...", :cyan
        template 'concerns/island_streaming.rb',
                 'app/models/concerns/island_streaming.rb'
      end

      def enhance_message_model
        return unless File.exist?('app/models/message.rb')

        say "Enhancing Message model with island streaming...", :cyan

        # Add the concern
        inject_into_file 'app/models/message.rb', after: "class Message < ApplicationRecord\n" do
          "  include IslandStreaming\n"
        end

        # Enhance broadcast_append_chunk if it exists
        if File.read('app/models/message.rb').include?('def broadcast_append_chunk')
          # Add island streaming to existing method
          inject_into_file 'app/models/message.rb',
                           after: /def broadcast_append_chunk\(content\)\n.*?partial:.*?\n/m do
            <<~RUBY
              
                  # IslandJS Rails: Stream to React component
                  broadcast_island_chunk(
                    "chat_\#{chat_id}",
                    target: "message_\#{id}_island",
                    content: content
                  )
            RUBY
          end
        else
          # Add the method
          inject_into_file 'app/models/message.rb', before: "end\n" do
            <<~RUBY
              
                def broadcast_append_chunk(content)
                  # HTML fallback
                  broadcast_append_to "chat_\#{chat_id}",
                    target: "message_\#{id}_content",
                    partial: "messages/content",
                    locals: { content: content }
                  
                  # IslandJS Rails: Stream to React component
                  broadcast_island_chunk(
                    "chat_\#{chat_id}",
                    target: "message_\#{id}_island",
                    content: content
                  )
                end
            RUBY
          end
        end
      rescue StandardError => e
        say "Could not automatically enhance Message model: #{e.message}", :yellow
        say "Add this to your Message model:", :yellow
        say "  include IslandStreaming", :yellow
      end

      def create_helper
        say "Creating chat islands helper...", :cyan
        copy_file 'helpers/chat_islands_helper.rb',
                  'app/helpers/chat_islands_helper.rb'
      end

      def add_stylesheets
        say "Adding chat island styles...", :cyan
        template 'stylesheets/chat_islands.css',
                 'app/assets/stylesheets/chat_islands.css'
      end

      def create_message_island_partial
        return unless File.exist?('app/views/messages')

        say "Creating message island partial...", :cyan
        create_file 'app/views/messages/_message_island.html.erb', <<~ERB
          <%# IslandJS Rails: React-enhanced message with streaming support %>
          <%= streaming_react_component('ChatMessage', {
            id: message.id,
            role: message.role,
            content: message.content || '',
            createdAt: message.created_at&.strftime("%I:%M %p"),
            isStreaming: false,
            toolCalls: message.tool_calls.map { |tc| { name: tc.name, args: tc.arguments } }
          }, {
            container_id: "message_\#{message.id}_island",
            class: "message-island-container"
          }) do %>
            <%# Progressive enhancement fallback %>
            <div class="message-fallback" 
                 style="padding: 12px; border-left: 3px solid <%= message.role == 'user' ? '#007bff' : '#28a745' %>; margin-bottom: 1rem;">
              <div style="font-weight: 600; margin-bottom: 8px; text-transform: capitalize;">
                <%= message.role == 'user' ? '👤 You' : '🤖 Assistant' %>
              </div>
              <div style="white-space: pre-wrap; line-height: 1.6;">
                <%= message.content %>
              </div>
              <div style="font-size: 0.85em; color: #666; margin-top: 8px;">
                <%= message.created_at&.strftime("%I:%M %p") %>
              </div>
            </div>
          <% end %>
        ERB
      end

      def update_layout
        layout_path = 'app/views/layouts/application.html.erb'
        return unless File.exist?(layout_path)

        # Check if turbo_stream_island_actions is already included
        layout_content = File.read(layout_path)
        return if layout_content.include?('turbo_stream_island_actions')

        say "Adding Turbo Stream island actions to layout...", :cyan

        # Try to inject before </head>
        if layout_content.include?('</head>')
          inject_into_file layout_path, before: /\s*<\/head>/ do
            "\n    <%= turbo_stream_island_actions %>\n"
          end
        else
          say "Could not find </head> in layout. Add <%= turbo_stream_island_actions %> manually.", :yellow
        end
      end

      def display_post_install_message
        say "\n✅ IslandJS Rails chat UI installed!", :green
        say "\nWhat was created:", :cyan
        say "  • React components: ChatMessage, StreamingContent, ChatContainer"
        say "  • IslandStreaming concern for Message model"
        say "  • Chat islands helper and styles"
        say "  • Island-enhanced message partial"

        say "\nNext steps:", :cyan
        say "  1. Run: yarn watch (in a separate terminal)", :yellow
        say "  2. Start Rails: bin/rails server", :yellow
        say "  3. Visit your chat UI and see streaming in action!", :yellow

        say "\nTo use the island partial in your views:", :cyan
        say "  <%= render 'messages/message_island', message: @message %>", :yellow

        say "\nYour chat messages will now stream with:"
        say "  ✨ Smooth character-by-character animation"
        say "  ✨ Blinking cursor during streaming"
        say "  ✨ Progressive enhancement (fallback without JS)"
        say "\n"
      end

      private

      def namespace_option
        options[:namespace] || 'islandjs'
      end
    end
  end
end

