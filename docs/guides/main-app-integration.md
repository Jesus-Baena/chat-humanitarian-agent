# Main App Integration Guide

## Navigation Integration

### Add Chat Link to Portfolio Navigation

The main app's `AppHeader.vue` should include a link to the chat app:

```vue
// In 010-baena.ai-professional-portfolio/app/components/AppHeader.vue
const items = computed(() => [{
  label: 'Projects',
  to: '/projects'
}, {
  label: 'Demos',
  to: '/demos'
}, {
  label: 'AI Chat', // ADD THIS
  to: 'https://chat.baena.ai',
  target: '_blank',
  class: 'bg-primary-100 dark:bg-primary-900 text-primary-600 dark:text-primary-400'
}, {
  label: 'Articles',
  to: '/articles'
}, {
  label: 'About',
  to: '/about'
}, {
  label: 'Contact',
  to: '/contact'
}, {
  label: 'Blog',
  to: 'https://baena.blog',
  target: '_blank',
  class: 'bg-gray-100 dark:bg-gray-800'
}]);
```

## Authentication Flow

### Current Setup ✅
- Both apps share the same Supabase instance
- Cookie domain is set to `.baena.ai` for cross-subdomain sharing
- Authentication state is automatically shared

### Verification Steps
1. User logs in on `baena.ai` 
2. User navigates to `chat.baena.ai`
3. Chat app detects existing authentication
4. User can immediately start chatting without re-login

## Content Updates

### Project Page Enhancement
Update the existing AI Chatbot project page to link to the live chat:

```markdown
// In 010-baena.ai-professional-portfolio/content/1.projects/1.ai-chatbot-project.md

## Live Demo
Experience the AI humanitarian agent: [Launch Chat →](https://chat.baena.ai)

## Features
- Real-time streaming responses via Flowise
- Persistent chat history with Supabase
- Anonymous and authenticated sessions
- MDC markdown rendering
- Mobile-responsive design
```

## Deployment Coordination

### Environment Alignment
Both apps should share these environment variables:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (client-side)
- `SUPABASE_SERVICE_ROLE_KEY` (server-side)

### Docker Swarm Network
Ensure both services are on the same Docker network for potential inter-service communication.

## Analytics Integration

### Shared User Journey
Track user flow from portfolio to chat:
- Add UTM parameters: `chat.baena.ai?utm_source=portfolio&utm_medium=navigation`
- Monitor conversion from portfolio visits to chat usage

## Future Enhancements

### Single Sign-On Optimization
- Add "Continue as [name]" when navigating from main app
- Share user profile data between apps
- Unified logout across subdomains

### Cross-App Notifications
- Notify portfolio users of new chat features
- Show chat activity in portfolio dashboard (if user has an account)

### Content Synchronization
- Auto-update project page when chat app is updated
- Generate portfolio content from chat conversation insights