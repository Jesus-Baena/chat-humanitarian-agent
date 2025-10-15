# Humanitarian Chat Agent

A Nuxt 4 application for humanitarian assistance with AI-powered chat functionality.

## Features

- **AI-Powered Conversations**: Integrated with Flowise for intelligent responses
- **User Authentication**: Supabase-based authentication and user management  
- **Real-time Chat**: Dynamic chat sessions with message history
- **Modern UI**: Built with Nuxt UI 3 and Nuxt UI Pro
- **Humanitarian Focus**: Designed specifically for humanitarian assistance workflows

## Tech Stack

- **Framework**: Nuxt 4.0.3
- **UI**: Nuxt UI 3 + Nuxt UI Pro
- **Database**: Supabase
- **AI**: Flowise integration
- **Deployment**: Docker + Docker Swarm

## Setup

1. **Install dependencies**:
   ```bash
   pnpm install
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   ```

3. **Run development server**:
   ```bash
   pnpm dev
   ```

## Docker Build

```bash
docker build -t chat-app .
```

## Environment Variables

See `.env.example` for required configuration.

## License

[Your License Here]
