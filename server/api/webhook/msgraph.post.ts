import sql from '~~/server/utils/db'
import { getAccessToken, getGraphEvent, deleteGraphEvent } from '~~/server/utils/msgraph'

interface GraphNotification {
  subscriptionId: string
  changeType: 'created' | 'updated' | 'deleted'
  resource: string
  resourceData: {
    '@odata.type': string
    '@odata.id': string
    '@odata.etag': string
    id: string
  }
  clientState: string
}

export default defineEventHandler(async (event) => {
  // Microsoft Graph subscription validation handshake
  const query = getQuery(event)
  if (query.validationToken) {
    setHeader(event, 'Content-Type', 'text/plain')
    return query.validationToken as string
  }

  const body = await readBody<{ value: GraphNotification[] }>(event)
  if (!body?.value?.length) return { status: 'ok' }

  const configs = await sql<{ key: string; value: string }[]>`
    SELECT key, value FROM config_variables
    WHERE key IN ('msgraph_webhook_secret', 'msgraph_enabled')
  `
  const cfg = Object.fromEntries(configs.map(c => [c.key, c.value]))

  if (cfg.msgraph_enabled !== 'true') {
    setResponseStatus(event, 202)
    return { status: 'disabled' }
  }

  const webhookSecret = cfg.msgraph_webhook_secret || ''

  // Acknowledge quickly — Graph retries if we don't respond within a few seconds
  setResponseStatus(event, 202)

  for (const notification of body.value) {
    if (webhookSecret && notification.clientState !== webhookSecret) continue
    try {
      await processNotification(notification)
    } catch (err) {
      console.error('[msgraph webhook] processing error:', err)
    }
  }

  return { status: 'ok' }
})

async function processNotification(notification: GraphNotification) {
  const eventId = notification.resourceData?.id
  if (!eventId) return

  // Extract room resource email from resource path: users/{email}/events/{id}
  const match = notification.resource.match(/users\/([^/]+)\/events/)
  const roomEmail = match ? decodeURIComponent(match[1]!) : null
  if (!roomEmail) return

  const mappings = await sql<{ room_id: number }[]>`
    SELECT room_id FROM room_graph_mappings WHERE resource_email = ${roomEmail} LIMIT 1
  `
  if (!mappings.length) return
  const roomId = mappings[0]!.room_id

  if (notification.changeType === 'deleted') {
    await sql`
      DELETE FROM room_reservations
      WHERE graph_event_id = ${eventId} AND source = 'outlook'
    `
    return
  }

  let graphEvent
  try {
    const token = await getAccessToken()
    graphEvent = await getGraphEvent(roomEmail, eventId, token)
  } catch {
    return
  }

  const { iCalUId, changeKey } = graphEvent
  const startTime = new Date(graphEvent.start.dateTime)
  const endTime = new Date(graphEvent.end.dateTime)
  const meetingTitle = graphEvent.subject || 'Reunião'

  // Idempotency: if we already have this exact version, skip
  const existing = await sql<{ id: number; change_key: string }[]>`
    SELECT id, change_key FROM room_reservations WHERE ical_uid = ${iCalUId} LIMIT 1
  `

  if (existing.length > 0) {
    if (existing[0]!.change_key === changeKey) return
    await sql`
      UPDATE room_reservations
      SET meeting_title = ${meetingTitle},
          start_time    = ${startTime},
          end_time      = ${endTime},
          change_key    = ${changeKey}
      WHERE id = ${existing[0]!.id}
    `
    return
  }

  // New event from Outlook — check for conflicts with existing platform bookings.
  // Race condition protection: if a conflict exists, cancel the Outlook booking.
  const conflicts = await sql<{ id: number }[]>`
    SELECT id FROM room_reservations
    WHERE room_id   = ${roomId}
      AND start_time < ${endTime}
      AND end_time   > ${startTime}
    LIMIT 1
  `

  if (conflicts.length > 0) {
    try {
      const token = await getAccessToken()
      await deleteGraphEvent(roomEmail, eventId, token)
    } catch (err) {
      console.error('[msgraph webhook] failed to cancel conflicting Outlook event:', err)
    }
    return
  }

  const organizerName = graphEvent.organizer?.emailAddress?.name || null
  const organizerEmail = graphEvent.organizer?.emailAddress?.address || null
  const guestLabel = organizerName || organizerEmail || 'Via Outlook'

  await sql`
    INSERT INTO room_reservations
      (room_id, guest_name, meeting_title, start_time, end_time,
       ical_uid, change_key, graph_event_id, source)
    VALUES
      (${roomId}, ${guestLabel}, ${meetingTitle}, ${startTime}, ${endTime},
       ${iCalUId}, ${changeKey}, ${eventId}, 'outlook')
  `
}
