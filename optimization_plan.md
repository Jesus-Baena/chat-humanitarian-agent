Optimization and Cleanup Plan

Overview
Concise, prioritized actions to improve performance, robustness, and maintainability of this Nuxt 4 chat app (Nuxt UI Pro + Supabase + Flowise). Findings are grounded in a code audit and current docs for Nuxt performance, Supabase SSR, and Flowise streaming.

Key Observations (current code)
- Streaming/UI
	- `useChat` streams SSE manually, flushes on nearly every line and calls `pinToBottom()` per chunk, causing frequent re-renders and scroll thrash.
	- Echo/cleanup logic relies on regex and string heuristics; risk of jitter and unnecessary work.
- Context/payload
	- Full history is serialized into a single prompt each call; latency scales with history length.
- Persistence
	- Supabase endpoints exist and are wired: chats list/create, messages list/create, delete chat. Good foundation; add guards and indexes.
- Auth/SSR
	- `@supabase/ssr` integration uses H3 cookies correctly; middleware refreshes session. Cookies are set with parent domain in prod (good).
- UI/Accessibility
	- `ChatInput` lacks aria-labels/titles; streaming controls exist (cancel/retry/typing) – nice.
- Config/Build
	- Nitro vite.server.rollupOptions.output.preserveModules: true – likely harms cold start without a specific reason.
	- `nuxt.config.ts` registers `@nuxt/ui` but `package.json` does not include it (potential missing dep at runtime).
- Dependencies
	- Likely unused: `flowise-sdk`, `ai`, `@ai-sdk/vue`, `marked`, `@types/marked`, `@nuxtjs/supabase`, `wrangler`.
	- MDC already renders Markdown; `marked` can be removed if truly unused.
- Types/State
	- `ChatMessage.createdAt` is `Date` in UI; API returns ISO strings – conversion is done, OK. Consider `readonly` semantics to avoid accidental mutation.
- Security
	- MDC content should be handled safely (MDC escapes by default, but verify any custom components). Rate limiting not present.

Prioritized Actions (P0 → P2)

P0 – Quick Wins (high impact, low risk)
1) Batch streaming UI updates
	 - Introduce a minimal batching mechanism (e.g., accumulate tokens, flush at ~40ms via requestAnimationFrame). Update scroll only after flush.
2) Throttle/guard scroll
	 - Move `pinToBottom()` behind a trailing throttle. Skip when user scrolled up.
3) Limit input context
	 - Send only the last N pairs (start with 8–12). Keep a simple helper to window messages before calling `getCompletion`.
4) Remove `preserveModules`
	 - Delete `vite.$server.build.rollupOptions.output.preserveModules`. Let Nitro bundle for better cold start.
5) Dependency hygiene
	 - Add missing `@nuxt/ui` to deps.
	 - Remove `flowise-sdk`, `ai`, `@ai-sdk/vue`, `marked`, `@types/marked`, `@nuxtjs/supabase`, `wrangler` if unused.
6) A11y polish
	 - Add aria-label to textarea and title/aria-label to send button.

P1 – Structural Cleanups & Reliability
7) Extract a small SSE parser
	 - New composable `useSseStream()` that: reads `ReadableStream<Uint8Array>`, yields only `data:` payloads, filters `DONE`, handles chunk boundaries.
	 - Keep `useChat` focused on state management.
8) Abort/cancel hardening
	 - Ensure abort closes reader cleanly; surface “canceled” state distinctly from error.
9) Retry strategy
	 - On network failure, debounce a one-click retry that reuses the same message window without duplicating the user message.
10) Observability
	 - Wrap `getCompletion` with timing and lightweight console metrics in dev; add hooks for future telemetry.
11) Types & immutability
	 - Use `shallowRef` for `messages` and treat existing entries as `Readonly<ChatMessage>` where feasible; avoid deep watchers.

P2 – Scalability & DX
12) Virtualize long lists
	 - Integrate virtualization (only when messages > 200). Defer to later if not needed now.
13) Tests
	 - Add Vitest and unit tests for: SSE parsing (normal, boundary splits, malformed JSON), context windowing, and cancel behavior.
14) Supabase indexes & policies
	 - Ensure DB indexes on `messages(chat_id, created_at)` and `chats(updated_at)`.
	 - Confirm RLS rules (if enabled) align with `session_id` or `user_id` ownership logic used in handlers.
15) Docs & envs
	 - Document env vars: `NUXT_PUBLIC_FLOWISE_URL`, optional `NUXT_PUBLIC_FLOWISE_API_KEY`, Supabase url/key. Clarify CORS/auth for Flowise (Authorization header).

Concrete Changes Proposed (by area)
- Streaming/UI (files: `app/composables/useChat.ts`, new `app/composables/useSseStream.ts`)
	- Add batched flushing (40ms). Update scroll after each flush, not each chunk.
	- Use a fixed index ref for the assistant message; avoid repeated `findIndex`.
	- Simplify echo suppression – drop heavy regex; only trim exact leading echo once, with a safety cutoff.

- Context/windowing
	- Helper that returns the last N messages with roles preserved; later evolve to token-aware windowing if needed.

- Supabase API (already present)
	- Add 429-style simple rate limiting per IP/session (Lightweight: in-memory token bucket in Nitro runtime or use an edge provider later).
	- Add basic input validation shape and size limits on `messages.post`.

- Build/config (file: `nuxt.config.ts`)
	- Remove server `preserveModules` output.
	- Consider adding `routeRules` for static pages (e.g., `/` prerender) per Nuxt performance guide.

- Dependencies (file: `package.json`)
	- Add `@nuxt/ui` if missing at runtime.
	- Remove unused packages listed above.
	- Add `vitest`, `@vitest/ui`, `@vue/test-utils` for unit tests.

- A11y (files: `app/components/ChatInput.vue`)
	- Add `aria-label` to `UTextarea`, `title` and `aria-label` to send button.

References (current guidance)
- Nuxt performance best practices (Nuxt 4): lazy loading/hydration, route rules, data fetching.
- Flowise streaming: data-only SSE with `event: token` and `data: ...`; supports Authorization when secured.
- Supabase SSR: `@supabase/ssr` with cookie adapters for SSR – align with current implementation.

Success Criteria & Metrics
- Perceived performance: smooth typing/scrolling during streams; no visible jank.
- Payload size: prompt payload no longer grows unbounded; stable network time with large histories.
- Cold start: serverless start-up faster after removing `preserveModules`.
- Bundle: reduced by pruning unused dependencies.
- Reliability: cancel/retry works deterministically; no duplicated user messages.

Suggested Execution Order (incremental PRs)
1) P0 quick wins (batching + scroll throttle + context window + config cleanup + deps + a11y).
2) Extract SSE parser composable and refactor `useChat`.
3) Add tests (parser, context, cancel).
4) Optional: virtualization, rate limiting, DB indexes, docs polish.

Notes
- MDC rendering is kept; avoid adding `marked` to prevent duplicate Markdown stacks.
- Flowise Authorization headers are supported; do not use `EventSource` when auth is needed – continue using `fetch` streaming.

Owner Checklist (to track work)
- [ ] P0: Batch stream UI updates and throttle scroll
- [ ] P0: Limit context to last N pairs
- [ ] P0: Remove preserveModules from server build
- [ ] P0: Dependency cleanup (+ add @nuxt/ui)
- [ ] P0: A11y attributes on input/button
- [ ] P1: Extract `useSseStream` and slim `useChat`
- [ ] P1: Harden cancel/retry and error states
- [ ] P1: Add lightweight observability around `getCompletion`
- [ ] P1: Adopt shallowRef/readonly patterns for messages
- [ ] P2: Add virtualization for long histories
- [ ] P2: Add Vitest and unit tests for parser/context/cancel
- [ ] P2: Ensure DB indexes + validate RLS policies
- [ ] P2: Update README with envs and deployment notes
