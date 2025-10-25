# Debug Instructions for Chat App

## Steps to Debug

1. Open browser to `http://localhost:3000`
2. Open DevTools Console (F12)
3. Create or open a chat
4. Send a test message like "Hello"
5. Check console output. You should see logs such as:

```
[useChat] sendMessage called with: Hello
[useChat] Adding user message: {...}
[useChat] Persisting user message...
[useChat] Persist result: ...
[useChat] Starting stream completion...
[useAssistants] getCompletion called
[useAssistants] flowiseUrl: ...
[useAssistants] flowiseApiKey: ***SET***
[useAssistants] Fetching from: ...
[useAssistants] Response status: ...
```

## What to Look For

If you see no logs at all:
- The `sendMessage` handler isn't firing. Check `ChatInput` emit and `ChatWindow` binding.

If logs stop at "Persisting user message":
- The persist API call failed. Check Network tab for `/api/chats/[id]/messages` errors.

If logs stop at "Starting stream completion":
- `getCompletion` threw. Inspect the error and runtime config.

If you see "No flowiseUrl configured":
- Runtime config missing. Confirm `NUXT_PUBLIC_FLOWISE_URL` or `public.flowiseUrl`.

If you see 401/403:
- Flowise authentication issue. Confirm API key header is sent.

If you see 404 on Flowise:
- URL wrong or chatflow id invalid.

If 200 OK but no message appears:
- Streaming/parsing issue. Check `useChat.handleStreamCompletion` logic.

## Quick Fixes

Restart dev server:
```bash
# Stop the dev server (Ctrl+C in its terminal), then
pnpm dev
```

Test Flowise directly (replace placeholders):
```bash
curl -X POST "${FLOWISE_URL}/api/v1/prediction/<chatflow-id>" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FLOWISE_API_KEY" \
  -d '{"question": "Hello", "streaming": false}'
```

## Report Back

Share:
1) Console logs
2) Network failures (screenshots)
3) What happens when you click Send?
