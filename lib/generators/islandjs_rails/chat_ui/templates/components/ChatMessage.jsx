import React from 'react';
import { useStreamingProps } from '../utils/turbo.js';
import StreamingContent from './StreamingContent.jsx';

/**
 * ChatMessage - A React island that displays a chat message with streaming support
 * Receives real-time updates via Turbo Streams without page reloads
 * 
 * @param {Object} props
 * @param {string} props.containerId - Container element ID
 */
function ChatMessage({ containerId }) {
  // Subscribe to streaming updates from Turbo Streams
  const props = useStreamingProps(containerId);
  
  const { 
    id,
    role = 'assistant', 
    content = '', 
    createdAt, 
    isStreaming = false,
    toolCalls = []
  } = props;

  const isUser = role === 'user';
  const roleLabel = isUser ? '👤 You' : '🤖 Assistant';
  const borderColor = isUser ? '#007bff' : '#28a745';

  return (
    <div 
      className={`chat-message chat-message--${role}`}
      style={{ borderLeftColor: borderColor }}
    >
      <div className="chat-message__header">
        <span className="chat-message__role">{roleLabel}</span>
        {createdAt && (
          <span className="chat-message__time">{createdAt}</span>
        )}
      </div>
      
      <div className="chat-message__content">
        <StreamingContent 
          content={content} 
          isStreaming={isStreaming}
        />
      </div>

      {toolCalls && toolCalls.length > 0 && (
        <div className="chat-message__tool-calls">
          <div className="tool-calls-header">🛠️ Tool Calls</div>
          {toolCalls.map((toolCall, idx) => (
            <div key={idx} className="tool-call">
              <strong>{toolCall.name}</strong>
              <pre className="tool-call-args">
                {JSON.stringify(toolCall.args, null, 2)}
              </pre>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default ChatMessage;

