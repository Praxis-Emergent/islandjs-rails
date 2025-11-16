import React, { useState, useEffect, useRef } from 'react';

/**
 * StreamingContent - Displays content with smooth character-by-character streaming
 * Shows a blinking cursor while streaming is active
 * 
 * @param {Object} props
 * @param {string} props.content - The content to display
 * @param {boolean} props.isStreaming - Whether content is currently streaming
 */
function StreamingContent({ content = '', isStreaming = false }) {
  const [displayedContent, setDisplayedContent] = useState('');
  const [cursorVisible, setCursorVisible] = useState(true);
  const contentRef = useRef(content);
  const displayedRef = useRef('');
  const animationFrameRef = useRef(null);

  // Smooth character-by-character reveal when streaming
  useEffect(() => {
    contentRef.current = content;
    
    if (!isStreaming) {
      // When streaming stops, show all content immediately
      setDisplayedContent(content);
      displayedRef.current = content;
      return;
    }

    // Only animate new characters
    if (content.length <= displayedRef.current.length) return;

    const newChars = content.slice(displayedRef.current.length);
    let charIndex = 0;
    let lastTimestamp = performance.now();
    const charsPerSecond = 60; // Adjust speed here (higher = faster)
    const msPerChar = 1000 / charsPerSecond;
    
    const animate = (timestamp) => {
      const elapsed = timestamp - lastTimestamp;
      
      if (elapsed >= msPerChar && charIndex < newChars.length) {
        displayedRef.current += newChars[charIndex];
        setDisplayedContent(displayedRef.current);
        charIndex++;
        lastTimestamp = timestamp;
      }
      
      if (charIndex < newChars.length) {
        animationFrameRef.current = requestAnimationFrame(animate);
      }
    };
    
    animationFrameRef.current = requestAnimationFrame(animate);

    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
      }
    };
  }, [content, isStreaming]);

  // Blinking cursor during streaming
  useEffect(() => {
    if (!isStreaming) {
      setCursorVisible(false);
      return;
    }
    
    const interval = setInterval(() => {
      setCursorVisible(v => !v);
    }, 530); // Cursor blink rate (530ms is terminal-like)
    
    return () => clearInterval(interval);
  }, [isStreaming]);

  return (
    <div className="streaming-content">
      <div className="streaming-content__text" style={{ whiteSpace: 'pre-wrap' }}>
        {displayedContent}
        {isStreaming && (
          <span 
            className={`streaming-cursor ${cursorVisible ? 'visible' : 'hidden'}`}
            aria-hidden="true"
          >
            ▊
          </span>
        )}
      </div>
    </div>
  );
}

export default StreamingContent;

