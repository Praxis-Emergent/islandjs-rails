# frozen_string_literal: true

# IslandStreaming - Concern for streaming content to React islands via Turbo Streams
# Include this in models that need to broadcast updates to React components
#
# @example
#   class Message < ApplicationRecord
#     include IslandStreaming
#     
#     def broadcast_append_chunk(content)
#       broadcast_island_chunk(
#         "chat_#{chat_id}",
#         target: "message_#{id}_island",
#         content: content
#       )
#     end
#   end
module IslandStreaming
  extend ActiveSupport::Concern

  included do
    # Initialize streaming accumulator as a class-level hash
    # This tracks partial content for each target during streaming
    class_attribute :streaming_accumulators, default: {}
  end

  # Broadcast accumulated content to a React island
  # Merges the content into the island's props via Turbo Stream
  #
  # @param stream_name [String] Turbo stream channel name
  # @param target [String] Container ID to update
  # @param content [String] Content chunk to append
  # @param final [Boolean] Whether this is the final chunk
  #
  # @example
  #   message.broadcast_island_chunk(
  #     "chat_123",
  #     target: "message_456_island",
  #     content: "Hello ",
  #     final: false
  #   )
  def broadcast_island_chunk(stream_name, target:, content:, final: false)
    # Use instance variable to track content per target
    @island_streaming_content ||= {}
    @island_streaming_content[target] ||= ""
    
    # Append new content (avoid frozen string issues)
    unless final
      @island_streaming_content[target] = @island_streaming_content[target] + content.to_s
    end
    
    # Get current accumulated content
    current_content = @island_streaming_content[target]
    
    # Broadcast the update via Turbo Stream
    # This will trigger the island_merge Turbo action
    IslandjsRails::TurboStreams::Helpers.broadcast_island_merge(
      stream_name,
      target: target,
      delta: {
        content: current_content,
        isStreaming: !final,
        updatedAt: Time.current.iso8601
      }
    )
    
    # Clear accumulator when streaming is complete
    @island_streaming_content.delete(target) if final
  end

  # Broadcast a complete message replacement to an island
  # Use this when you want to replace all props at once
  #
  # @param stream_name [String] Turbo stream channel name
  # @param target [String] Container ID to update
  # @param props [Hash] Complete props object
  #
  # @example
  #   message.broadcast_island_replace(
  #     "chat_123",
  #     target: "message_456_island",
  #     props: { content: "Final message", isStreaming: false }
  #   )
  def broadcast_island_replace(stream_name, target:, props:)
    IslandjsRails::TurboStreams::Helpers.broadcast_island_replace(
      stream_name,
      target: target,
      props: props
    )
  end

  # Mark streaming as complete for a target
  # Sends a final update with isStreaming: false
  #
  # @param stream_name [String] Turbo stream channel name
  # @param target [String] Container ID to update
  #
  # @example
  #   message.broadcast_island_complete("chat_123", target: "message_456_island")
  def broadcast_island_complete(stream_name, target:)
    broadcast_island_chunk(stream_name, target: target, content: "", final: true)
  end
end

