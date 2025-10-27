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

      def check_message_model
        return unless File.exist?('app/models/message.rb')

        say "Checking Message model...", :cyan
        say "  ✓ Message model found - no modifications needed!", :green
        say "  ℹ React islands work with your existing broadcast_append_chunk method", :cyan
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

      def create_demo_view
        say "Creating island chat demo view...", :cyan
        create_file 'app/views/island_chats/show.html.erb', <<~ERB
          <p style="color: green"><%= notice %></p>

          <%= turbo_stream_from "chat_\#{@chat.id}" %>

          <% content_for :title, "Island Chat Demo" %>

          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; border-radius: 8px; margin-bottom: 20px; color: white;">
            <h1 style="margin: 0 0 10px 0;">🏝️ Island Chat Demo</h1>
            <p style="margin: 0; opacity: 0.9;">Chat <%= @chat.id %> - Using <strong><%= @chat.model.name %></strong></p>
            <p style="margin: 10px 0 0 0; font-size: 0.9em; opacity: 0.8;">
              ✨ React Islands + Streaming • Progressive Enhancement • Smooth Animations
            </p>
          </div>

          <div id="messages">
            <% @chat.messages.where.not(id: nil).each do |message| %>
              <%= render 'messages/message_island', message: message %>
            <% end %>
          </div>

          <div style="margin-top: 30px;">
            <%= render "messages/form", chat: @chat, message: @message %>
          </div>

          <div style="margin-top: 20px; display: flex; gap: 15px;">
            <%= link_to "← Standard Chat UI", chat_path(@chat), style: "padding: 10px 20px; background: #6c757d; color: white; text-decoration: none; border-radius: 5px;" %>
            <%= link_to "Back to chats", chats_path, style: "padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 5px;" %>
          </div>
        ERB
      end

      def add_demo_controller_action
        controller_path = 'app/controllers/islandjs_demo_controller.rb'
        
        # Check if controller exists
        unless File.exist?(controller_path)
          say "Creating IslandjsDemoController...", :cyan
          create_file controller_path, <<~RUBY
            class IslandjsDemoController < ApplicationController
              def index
                # IslandJS Rails demo homepage
              end
              
              def react
                # Demo route for showcasing IslandJS React integration
              end
              
              def react_chat
                # Island-enhanced chat UI demo (compare with /chats/:id)
                @chat = Chat.find(params[:id])
                @message = Message.new
                render 'island_chats/show'
              end
            end
          RUBY
          return
        end

        # Add react_chat action if it doesn't exist
        controller_content = File.read(controller_path)
        return if controller_content.include?('def react_chat')

        say "Adding react_chat action to IslandjsDemoController...", :cyan
        inject_into_file controller_path, before: /^end\s*$/ do
          <<~RUBY
            
              def react_chat
                # Island-enhanced chat UI demo (compare with /chats/:id)
                @chat = Chat.find(params[:id])
                @message = Message.new
                render 'island_chats/show'
              end
          RUBY
        end
      end

      def add_demo_route
        route_content = File.read('config/routes.rb')
        
        # Check if route already exists
        return if route_content.include?('islandjs/react/chats')

        say "Adding demo route for island chat...", :cyan
        
        # Find the islandjs routes section and add after it
        if route_content.include?("get 'islandjs/react'")
          inject_into_file 'config/routes.rb', after: /get 'islandjs\/react'.*\n/ do
            "  get 'islandjs/react/chats/:id', to: 'islandjs_demo#react_chat', as: :islandjs_react_chat\n"
          end
        else
          # Add the whole islandjs routes section
          route <<~RUBY
            # IslandJS demo routes
            get 'islandjs', to: 'islandjs_demo#index'
            get 'islandjs/react', to: 'islandjs_demo#react'
            get 'islandjs/react/chats/:id', to: 'islandjs_demo#react_chat', as: :islandjs_react_chat
          RUBY
        end
      end

      def add_link_to_standard_chat
        chat_show_path = 'app/views/chats/show.html.erb'
        return unless File.exist?(chat_show_path)

        chat_content = File.read(chat_show_path)
        return if chat_content.include?('islandjs_react_chat_path')

        say "Adding link to island version in standard chat view...", :cyan
        
        # Try to find the "Back to chats" link and enhance it
        if chat_content.include?('link_to "Back to chats"')
          gsub_file chat_show_path, 
                    /(<%=\s*link_to "Back to chats".*?%>)/m do |match|
            <<~ERB.strip
              <div style="margin-top: 20px; display: flex; gap: 15px;">
                <%= link_to "🏝️ View Island Version", islandjs_react_chat_path(@chat), style: "padding: 10px 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; border-radius: 5px; font-weight: bold;" %>
                #{match}
              </div>
            ERB
          end
        end
      end

      def check_layout
        layout_path = 'app/views/layouts/application.html.erb'
        return unless File.exist?(layout_path)

        layout_content = File.read(layout_path)
        
        if layout_content.include?('<%= islands %>')
          say "Checking layout...", :cyan
          say "  ✓ Layout has <%= islands %> helper - React components will hydrate!", :green
        else
          say "⚠️  Layout missing <%= islands %> helper", :yellow
          say "   Add <%= islands %> to your layout's <head> section for React islands to work", :yellow
        end
      end

      def display_post_install_message
        say "\n✅ IslandJS Rails chat UI installed!", :green
        say "\nWhat was created:", :cyan
        say "  • React components: ChatMessage, StreamingContent, ChatContainer"
        say "  • Chat island styles"
        say "  • Island-enhanced message partial"
        say "  • Demo controller action and route"
        say "  • Island chat demo view"

        say "\nNext steps:", :cyan
        say "  1. Run: yarn watch (in a separate terminal)", :yellow
        say "  2. Start Rails: bin/rails server", :yellow
        say "  3. Visit /chats to create a chat", :yellow
        say "  4. Compare standard vs island versions:", :yellow
        say "     • Standard: /chats/:id", :yellow
        say "     • Islands:  /islandjs/react/chats/:id", :yellow

        say "\nTo use the island partial in your views:", :cyan
        say "  <%= render 'messages/message_island', message: @message %>", :yellow

        say "\nYour chat messages will now stream with:"
        say "  ✨ Smooth character-by-character animation"
        say "  ✨ Blinking cursor during streaming"
        say "  ✨ Progressive enhancement (fallback without JS)"
        say "  ✨ Side-by-side comparison with standard UI"
        say "\n"
        say "Note: Zero changes to your Message model!", :green
        say "React islands work with your existing Turbo Stream setup.", :green
        say "\n"
      end

      private

      def namespace_option
        options[:namespace] || 'islandjs'
      end
    end
  end
end

