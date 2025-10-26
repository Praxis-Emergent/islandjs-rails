# frozen_string_literal: true

# ChatIslandsHelper - View helpers for rendering chat islands
module ChatIslandsHelper
  # Render a message as a React island with streaming support
  #
  # @param message [Message] The message to render
  # @param options [Hash] Additional options
  # @option options [Boolean] :show_fallback Show HTML fallback (default: true)
  # @option options [String] :class Additional CSS classes
  #
  # @example
  #   <%= render_message_island(@message) %>
  #   <%= render_message_island(@message, class: 'highlight') %>
  def render_message_island(message, options = {})
    streaming_react_component('ChatMessage', {
      id: message.id,
      role: message.role,
      content: message.content || '',
      createdAt: message.created_at&.strftime("%I:%M %p"),
      isStreaming: false,
      toolCalls: extract_tool_calls(message)
    }, {
      container_id: "message_#{message.id}_island",
      class: ["message-island-container", options[:class]].compact.join(' ')
    }) do
      if options.fetch(:show_fallback, true)
        render_message_fallback(message)
      end
    end
  end

  # Render a chat container island
  #
  # @param chat [Chat] The chat object
  # @param options [Hash] Additional options
  #
  # @example
  #   <%= render_chat_container_island(@chat) %>
  def render_chat_container_island(chat, options = {})
    messages_data = chat.messages.order(:created_at).map do |msg|
      {
        id: msg.id,
        role: msg.role,
        content: msg.content || '',
        createdAt: msg.created_at&.strftime("%I:%M %p")
      }
    end

    streaming_react_component('ChatContainer', {
      messages: messages_data,
      autoScroll: options.fetch(:auto_scroll, true)
    }, {
      container_id: "chat_#{chat.id}_container",
      class: "chat-container-island"
    })
  end

  private

  # Extract tool calls from message if they exist
  def extract_tool_calls(message)
    return [] unless message.respond_to?(:tool_calls)
    
    message.tool_calls.map do |tc|
      {
        name: tc.name,
        args: tc.arguments
      }
    end
  rescue
    []
  end

  # Render HTML fallback for progressive enhancement
  def render_message_fallback(message)
    content_tag(:div, class: 'message-fallback', 
                style: "padding: 12px; border-left: 3px solid #{message_border_color(message)}; margin-bottom: 1rem;") do
      concat(content_tag(:div, message_role_label(message), 
                         style: 'font-weight: 600; margin-bottom: 8px;'))
      concat(content_tag(:div, message.content, 
                         style: 'white-space: pre-wrap; line-height: 1.6;'))
      concat(content_tag(:div, message.created_at&.strftime("%I:%M %p"), 
                         style: 'font-size: 0.85em; color: #666; margin-top: 8px;'))
    end
  end

  def message_border_color(message)
    message.role == 'user' ? '#007bff' : '#28a745'
  end

  def message_role_label(message)
    message.role == 'user' ? '👤 You' : '🤖 Assistant'
  end
end

