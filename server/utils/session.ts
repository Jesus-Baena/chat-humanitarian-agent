import { getHeader, setCookie, getCookie } from 'h3'
import type { H3Event } from 'h3'

const COOKIE_NAME = 'chat_session_id'

function computeCookieDomain(event: H3Event): string | undefined {
  const host = getHeader(event, 'host') || ''
  const isLocalhost = /localhost(:\d+)?$/i.test(host) || /^127\.0\.0\.1(:\d+)?$/.test(host)
  if (isLocalhost) return undefined
  const hostname = host.split(':')[0] ?? ''
  const parts = hostname.split('.')
  if (parts.length >= 2) {
    const parent = parts.slice(-2).join('.')
    return `.${parent}`
  }
  return undefined
}

function generateId(): string {
  try {
    if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
      return crypto.randomUUID()
    }
  } catch {
    // ignore
  }
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`
}

export function getOrCreateSessionId(event: H3Event): string {
  const existing = getCookie(event, COOKIE_NAME)
  if (existing) return existing
  const id = generateId()
  setCookie(event, COOKIE_NAME, id, {
    httpOnly: true,
    sameSite: 'lax',
    secure: (getHeader(event, 'x-forwarded-proto') || '').includes('https') || (getHeader(event, 'host') || '').startsWith('localhost') === false,
    path: '/',
    domain: computeCookieDomain(event),
    // ~180 days
    maxAge: 60 * 60 * 24 * 180
  })
  return id
}

export function getSessionId(event: H3Event): string | undefined {
  return getCookie(event, COOKIE_NAME) || undefined
}
