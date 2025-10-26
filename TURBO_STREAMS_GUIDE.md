# IslandJS Rails - Turbo Streams Guide

## 🎯 Overview

IslandJS Rails now supports **Turbo Streams for React islands**, enabling real-time updates to React components without full page reloads. This is perfect for streaming AI responses, live dashboards, real-time notifications, and more.

## 🏗️ Architecture

### How It Works

```
RubyLLM Job → chunk → broadcast_island_chunk → Turbo Stream → 
update data-initial-state → React MutationObserver → re-render
```

**Key Insight:** Unlike Superglue (full SPA), we use React islands IN Rails HTML, so we leverage **actual Turbo Streams** with a thin adapter that updates `data-initial-state` attributes.

### Core Components

1. **Custom Turbo Actions** (`lib/islandjs_rails/turbo_streams/actions.rb`)
   - `island_merge`: Merges delta into existing props
   - `island_replace`: Completely replaces props

2. **Streaming Hooks** (`app/javascript/islands/utils/turbo.js`)
   - `useStreamingProps`: React hook that watches for Turbo Stream updates
   - `useStreamingState`: Alternative imperative API

3. **Rails Helpers** (`lib/islandjs_rails/turbo_streams/helpers.rb`)
   - `streaming_react_component`: Enhanced react_component
   - `broadcast_island_merge`: Broadcast partial props updates
   - `broadcast_island_replace`: Broadcast full props replacement

## 🚀 Quick Start

### 1. Installation

Already included in islandjs-rails! The Turbo Stream actions are automatically injected into your layout.

### 2. Generate Chat UI (with RubyLLM)

```bash
# First install RubyLLM and set up base models
rails generate ruby_llm:install
rails generate ruby_llm:chat_ui

# Then enhance with React islands
rails generate islandjs_rails:chat_ui
```

This creates:
- ✅ React components: `ChatMessage`, `StreamingContent`, `ChatContainer`
- ✅ `IslandStreaming` concern for Message model
- ✅ Helper methods and styles
- ✅ Island-enhanced message partial

### 3. Start Development

```bash
# Terminal 1: Watch and build JavaScript
yarn watch

# Terminal 2: Start Rails server
bin/rails server
```

## 📝 Basic Usage

### React Component with Streaming

```jsx
import React from 'react';
import { useStreamingProps } from '../utils/turbo.js';

function ChatMessage({ containerId }) {
  // Subscribe to Turbo Stream updates
  const props = useStreamingProps(containerId);
  const { content, isStreaming } = props;

  return (
    <div>
      {content}
      {isStreaming && <span className="cursor">▊</span>}
    </div>
  );
}

export default ChatMessage;
```

### Render in ERB View

```erb
<%= streaming_react_component('ChatMessage', {
  content: 'Initial content',
  isStreaming: false
}, {
  container_id: 'message_123_island'
}) do %>
  <!-- Progressive enhancement fallback -->
  <div class="fallback">Loading...</div>
<% end %>
```

### Broadcast Updates from Rails

```ruby
class Message < ApplicationRecord
  include IslandStreaming
  
  def broadcast_streaming_chunk(content)
    broadcast_island_merge(
      "chat_#{chat_id}",
      target: "message_#{id}_island",
      delta: {
        content: accumulated_content,
        isStreaming: true
      }
    )
  end
  
  def broadcast_streaming_complete
    broadcast_island_merge(
      "chat_#{chat_id}",
      target: "message_#{id}_island",
      delta: { isStreaming: false }
    )
  end
end
```

## 🎨 Chat UI Generator Features

### Generated React Components

**ChatMessage.jsx**
- Displays a single message with role, content, timestamp
- Handles tool calls visualization
- Streaming cursor animation

**StreamingContent.jsx**
- Character-by-character streaming animation
- Blinking cursor during streaming
- requestAnimationFrame for smooth 60fps rendering

**ChatContainer.jsx**
- Container for multiple messages
- Auto-scroll to bottom on new messages

### Generated Concern: IslandStreaming

```ruby
module IslandStreaming
  # Broadcast accumulated content with streaming state
  def broadcast_island_chunk(stream_name, target:, content:, final: false)
    # Accumulates content and broadcasts delta
  end
  
  # Broadcast complete replacement
  def broadcast_island_replace(stream_name, target:, props:)
    # Replaces all props
  end
  
  # Mark streaming as complete
  def broadcast_island_complete(stream_name, target:)
    # Sends final update with isStreaming: false
  end
end
```

### Usage with RubyLLM

The generator automatically enhances your Message model:

```ruby
class Message < ApplicationRecord
  include IslandStreaming  # Added by generator
  acts_as_message
  
  def broadcast_append_chunk(content)
    # Original HTML streaming (backwards compatible)
    broadcast_append_to "chat_#{chat_id}",
      target: "message_#{id}_content",
      partial: "messages/content",
      locals: { content: content }
    
    # NEW: Island streaming
    broadcast_island_chunk(
      "chat_#{chat_id}",
      target: "message_#{id}_island",
      content: content
    )
  end
end
```

## 🔧 Advanced Usage

### Custom Streaming Components

```jsx
// Counter that updates in real-time
function LiveCounter({ containerId }) {
  const props = useStreamingProps(containerId, (newProps) => {
    console.log('Count updated!', newProps.count);
  });
  
  return <div>Count: {props.count}</div>;
}
```

```ruby
# Broadcast from anywhere
broadcast_island_merge("counters", 
  target: "counter_widget", 
  delta: { count: current_count })
```

### Imperative API (useStreamingState)

```jsx
function Dashboard({ containerId }) {
  const [state, setState] = useStreamingState(containerId, {
    activeUsers: 0,
    revenue: 0
  });
  
  return (
    <div>
      <p>Active Users: {state.activeUsers}</p>
      <p>Revenue: ${state.revenue}</p>
    </div>
  );
}
```

### Manual Props Update (Testing)

```javascript
import { updateContainerProps } from '../utils/turbo.js';

// Manually update props (useful for testing)
updateContainerProps('message_123_island', {
  content: 'Updated content',
  isStreaming: false
});
```

## 🎯 Use Cases

### 1. AI Chat Streaming
✅ Character-by-character streaming responses  
✅ Blinking cursor during generation  
✅ Tool call visualization  

### 2. Live Dashboards
✅ Real-time metrics updates  
✅ Stock prices, analytics  
✅ User activity feeds  

### 3. Notifications
✅ Toast notifications  
✅ Badge counters  
✅ Live updates  

### 4. Collaborative Editing
✅ Presence indicators  
✅ Live cursors  
✅ Content sync  

## 📊 Performance

- **Zero full page reloads** - Only React components re-render
- **Minimal data transfer** - Only deltas are broadcast
- **60fps animations** - requestAnimationFrame for smooth streaming
- **Progressive enhancement** - HTML fallback if JS fails

## 🐛 Debugging

### Enable Debug Logging

```javascript
// In browser console
localStorage.setItem('islandjs_debug', 'true');
```

### Check Turbo Actions

```javascript
// Verify custom actions are registered
console.log(Turbo.StreamActions.island_merge);
console.log(Turbo.StreamActions.island_replace);
```

### Inspect Container State

```javascript
// Read current props from a container
const container = document.getElementById('message_123_island');
console.log(JSON.parse(container.dataset.initialState));
```

## 🔮 Future Enhancements

- [ ] Markdown rendering (react-markdown)
- [ ] Syntax highlighting (prism-react-renderer)  
- [ ] Code copy buttons
- [ ] Message editing
- [ ] Voice input/output
- [ ] Multi-modal support (images, files)

## 📚 API Reference

### Streaming Hooks

#### `useStreamingProps(containerId, onUpdate?)`

Watches for Turbo Stream updates via MutationObserver.

**Parameters:**
- `containerId` (string): Container element ID
- `onUpdate` (function): Optional callback when props change

**Returns:** Current props object

#### `useStreamingState(containerId, initialState?)`

Listens for `islandjs:props-updated` events.

**Parameters:**
- `containerId` (string): Container element ID  
- `initialState` (object): Initial state

**Returns:** `[state, setState]` tuple

### Rails Helpers

#### `streaming_react_component(name, props, options, &block)`

Enhanced `react_component` with streaming support.

#### `broadcast_island_merge(stream_name, target:, delta:)`

Broadcast partial props update.

#### `broadcast_island_replace(stream_name, target:, props:)`

Broadcast complete props replacement.

## 💡 Tips

1. **Use container_id** - Always set explicit container IDs for streaming targets
2. **Progressive enhancement** - Provide HTML fallback in block
3. **Final flag** - Mark streaming complete with `final: true`
4. **Delta updates** - Use `broadcast_island_merge` for efficiency
5. **Export components** - Add to `app/javascript/islands/index.js`

## 🙏 Credits

Built on top of:
- **Turbo** (Hotwire) - Real-time HTML over WebSockets
- **React** - UI components
- **RubyLLM** - LLM integration for Rails

---

**Questions?** Check the main [README](README.md) or open an issue!

