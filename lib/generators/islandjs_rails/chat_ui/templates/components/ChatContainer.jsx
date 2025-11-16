import React, { useEffect, useRef } from 'react';
import { useStreamingProps } from '../utils/turbo.js';
import ChatMessage from './ChatMessage.jsx';

/**
 * ChatContainer - Container for multiple chat messages
 * Auto-scrolls to bottom when new messages arrive or content updates
 * 
 * @param {Object} props
 * @param {string} props.containerId - Container element ID
 */
function ChatContainer({ containerId }) {
  const props = useStreamingProps(containerId);
  const { messages = [], autoScroll = true } = props;
  const containerRef = useRef(null);
  const prevMessageCountRef = useRef(messages.length);

  // Auto-scroll to bottom when messages change
  useEffect(() => {
    if (!autoScroll || !containerRef.current) return;
    
    // Scroll when new messages are added
    if (messages.length > prevMessageCountRef.current) {
      containerRef.current.scrollTop = containerRef.current.scrollHeight;
      prevMessageCountRef.current = messages.length;
    }
  }, [messages, autoScroll]);

  return (
    <div 
      ref={containerRef}
      className="chat-container"
    >
      {messages.length === 0 ? (
        <div className="chat-container__empty">
          <p>No messages yet. Start a conversation!</p>
        </div>
      ) : (
        messages.map((message) => (
          <div key={message.id} id={`message_${message.id}_wrapper`}>
            {/* Each message is its own island for independent updates */}
            <ChatMessage containerId={`message_${message.id}_island`} />
          </div>
        ))
      )}
    </div>
  );
}

export default ChatContainer;

