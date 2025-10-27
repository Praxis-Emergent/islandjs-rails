# frozen_string_literal: true

module IslandjsRails
  module TurboStreams
    module Helpers
      # Enhanced react_component that's stream-aware
      # Renders a React component that can receive real-time updates via Turbo Streams
      #
      # @param name [String] Component name
      # @param props [Hash] Initial props
      # @param options [Hash] Options (container_id, class, etc.)
      # @param block [Block] Optional placeholder content
      #
      # @example
      #   <%= streaming_react_component('ChatMessage', { content: 'Hello' }, 
      #         container_id: 'message_123') do %>
      #     <div class="loading">Loading...</div>
      #   <% end %>
      def streaming_react_component(name, props = {}, options = {}, &block)
        container_id = options[:container_id] || "#{name.underscore}_#{SecureRandom.hex(4)}"
        
        # Mark as streamable in data attributes
        enhanced_options = options.merge(
          container_id: container_id,
          data: (options[:data] || {}).merge(streamable: true)
        )
        
        react_component(name, props, enhanced_options, &block)
      end
      
      # Broadcast a full props replacement to a React island via Turbo Stream
      #
      # @param stream_name [String] Turbo stream name (e.g., "chat_123")
      # @param target [String] Container ID to update
      # @param props [Hash] New props object
      #
      # @example
      #   broadcast_island_replace("chat_123", target: "message_456", 
      #     props: { content: "Updated content", isStreaming: false })
      def broadcast_island_replace(stream_name, target:, props:)
        Turbo::StreamsChannel.broadcast_action_to(
          stream_name,
          action: :island_replace,
          target: target,
          props: props.to_json
        )
      end
      
      # Broadcast a partial props merge to a React island via Turbo Stream
      # Only updates the specified keys, leaving others unchanged
      #
      # @param stream_name [String] Turbo stream name (e.g., "chat_123")
      # @param target [String] Container ID to update
      # @param delta [Hash] Partial props to merge
      #
      # @example
      #   broadcast_island_merge("chat_123", target: "message_456", 
      #     delta: { content: message.content, isStreaming: false })
      def broadcast_island_merge(stream_name, target:, delta:)
        Turbo::StreamsChannel.broadcast_action_to(
          stream_name,
          action: :island_merge,
          target: target,
          delta: delta.to_json
        )
      end
    end
  end
end

