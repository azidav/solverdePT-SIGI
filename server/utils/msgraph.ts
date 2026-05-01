import { ofetch } from 'ofetch'
import sql from '~~/server/utils/db'

interface TokenCache {
  accessToken: string
  expiresAt: number
}

// Module-level token cache — reused across requests until 1 min before expiry
let tokenCache: TokenCache | null = null

export async function getMsGraphConfig(): Promise<Record<string, string>> {
  const rows = await sql<{ key: string; value: string }[]>`
    SELECT key, value FROM config_variables
    WHERE key IN (
      'msgraph_enabled', 'msgraph_tenant_id', 'msgraph_client_id',
      'msgraph_client_secret', 'msgraph_webhook_secret'
    )
  `
  return Object.fromEntries(rows.map(r => [r.key, r.value]))
}

export async function getAccessToken(): Promise<string> {
  if (tokenCache && tokenCache.expiresAt > Date.now() + 60_000) {
    return tokenCache.accessToken
  }

  const config = await getMsGraphConfig()
  const { msgraph_tenant_id: tenantId, msgraph_client_id: clientId, msgraph_client_secret: clientSecret } = config

  if (!tenantId || !clientId || !clientSecret) {
    throw createError({ statusCode: 503, message: 'Microsoft Graph não está configurado (tenant_id, client_id ou client_secret em falta)' })
  }

  const response = await ofetch<{ access_token: string; expires_in: number }>(
    `https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/token`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        scope: 'https://graph.microsoft.com/.default',
        grant_type: 'client_credentials'
      }).toString()
    }
  )

  tokenCache = {
    accessToken: response.access_token,
    expiresAt: Date.now() + response.expires_in * 1000
  }

  return tokenCache.accessToken
}

export interface GraphEvent {
  id: string
  iCalUId: string
  changeKey: string
  subject: string
  body?: { content: string; contentType: string }
  start: { dateTime: string; timeZone: string }
  end: { dateTime: string; timeZone: string }
  organizer?: { emailAddress: { address: string; name: string } }
}

export async function getGraphEvent(roomEmail: string, eventId: string, token: string): Promise<GraphEvent> {
  return ofetch<GraphEvent>(
    `https://graph.microsoft.com/v1.0/users/${encodeURIComponent(roomEmail)}/events/${encodeURIComponent(eventId)}`,
    { headers: { Authorization: `Bearer ${token}` } }
  )
}

export interface CreateEventInput {
  subject: string
  body?: string
  start: { dateTime: string; timeZone: string }
  end: { dateTime: string; timeZone: string }
  attendees?: Array<{ emailAddress: { address: string; name?: string }; type: 'required' | 'optional' }>
}

export async function createGraphEvent(roomEmail: string, input: CreateEventInput, token: string): Promise<GraphEvent> {
  const payload: Record<string, unknown> = {
    subject: input.subject,
    start: input.start,
    end: input.end
  }
  if (input.body) {
    payload.body = { contentType: 'text', content: input.body }
  }
  if (input.attendees?.length) {
    payload.attendees = input.attendees
  }

  return ofetch<GraphEvent>(
    `https://graph.microsoft.com/v1.0/users/${encodeURIComponent(roomEmail)}/events`,
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    }
  )
}

export async function deleteGraphEvent(roomEmail: string, eventId: string, token: string): Promise<void> {
  await ofetch(
    `https://graph.microsoft.com/v1.0/users/${encodeURIComponent(roomEmail)}/events/${encodeURIComponent(eventId)}`,
    { method: 'DELETE', headers: { Authorization: `Bearer ${token}` } }
  )
}

export interface GraphSubscription {
  id: string
  expirationDateTime: string
}

// Graph calendar subscriptions expire after at most 3 days (4320 min); subtract 5 min as buffer
function nextExpirationISO(): string {
  return new Date(Date.now() + 3 * 24 * 60 * 60 * 1000 - 5 * 60 * 1000).toISOString()
}

export async function createGraphSubscription(
  roomEmail: string,
  notificationUrl: string,
  clientState: string,
  token: string
): Promise<GraphSubscription> {
  return ofetch<GraphSubscription>(
    'https://graph.microsoft.com/v1.0/subscriptions',
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        changeType: 'created,updated,deleted',
        notificationUrl,
        resource: `users/${roomEmail}/events`,
        expirationDateTime: nextExpirationISO(),
        clientState
      })
    }
  )
}

export async function renewGraphSubscription(subscriptionId: string, token: string): Promise<GraphSubscription> {
  return ofetch<GraphSubscription>(
    `https://graph.microsoft.com/v1.0/subscriptions/${subscriptionId}`,
    {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ expirationDateTime: nextExpirationISO() })
    }
  )
}

export async function deleteGraphSubscription(subscriptionId: string, token: string): Promise<void> {
  await ofetch(
    `https://graph.microsoft.com/v1.0/subscriptions/${subscriptionId}`,
    { method: 'DELETE', headers: { Authorization: `Bearer ${token}` } }
  )
}
