import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { getUserRoomsPermissions } from '~~/server/utils/rooms'
import { getAccessToken, getMsGraphConfig, createGraphEvent } from '~~/server/utils/msgraph'

export default defineEventHandler(async (event) => {
  // Reservas de convidados (sem sessão) desativadas por agora
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const { room_id, meeting_title, description, start_time, end_time, add_to_outlook } = await readBody(event)

  if (!room_id || !meeting_title?.trim() || !start_time || !end_time) {
    throw createError({ statusCode: 400, message: 'Campos obrigatórios em falta' })
  }

  const perms = await getUserRoomsPermissions(currentUser.id)
  if (!perms.includes('ROOMS:RESERVE')) {
    throw createError({ statusCode: 403, message: 'Sem permissão para fazer reservas' })
  }

  const startDt = new Date(start_time)
  const endDt = new Date(end_time)

  if (isNaN(startDt.getTime()) || isNaN(endDt.getTime())) {
    throw createError({ statusCode: 400, message: 'Datas inválidas' })
  }
  if (startDt >= endDt) {
    throw createError({ statusCode: 400, message: 'Hora de fim deve ser após a hora de início' })
  }
  if (startDt < new Date()) {
    throw createError({ statusCode: 400, message: 'Não é possível reservar no passado' })
  }

  const rooms = await sql`SELECT id FROM meeting_rooms WHERE id = ${room_id} AND status = 'active' LIMIT 1`
  if (rooms.length === 0) throw createError({ statusCode: 404, message: 'Sala não encontrada' })

  // Wrap conflict check + insert in a transaction to eliminate race conditions
  let reservation: Record<string, unknown>
  try {
    reservation = await sql.begin(async (tx) => {
      // Advisory lock scoped to this room prevents concurrent double-bookings
      await tx`SELECT pg_advisory_xact_lock(${room_id}::bigint)`

      const conflicts = await tx`
        SELECT id FROM room_reservations
        WHERE room_id = ${room_id}
          AND start_time < ${endDt}
          AND end_time   > ${startDt}
        LIMIT 1
      `
      if (conflicts.length > 0) {
        throw createError({ statusCode: 409, message: 'Sala já reservada para este horário' })
      }

      const rows = await tx`
        INSERT INTO room_reservations (room_id, user_id, meeting_title, description, start_time, end_time, source)
        VALUES (${room_id}, ${currentUser.id}, ${meeting_title.trim()}, ${description || null}, ${startDt}, ${endDt}, 'platform')
        RETURNING id, room_id, user_id, meeting_title, description, start_time, end_time, created_at
      `
      return rows[0]!
    })
  } catch (err: any) {
    // Re-throw H3 errors (conflict, etc.) transparently
    if (err?.statusCode) throw err
    throw createError({ statusCode: 500, message: 'Erro ao criar reserva' })
  }

  // Optionally push the reservation to the room's Outlook calendar
  if (add_to_outlook && currentUser) {
    try {
      const config = await getMsGraphConfig()
      if (config.msgraph_enabled === 'true') {
        const mappings = await sql<{ resource_email: string }[]>`
          SELECT resource_email FROM room_graph_mappings WHERE room_id = ${room_id} LIMIT 1
        `
        if (mappings.length > 0) {
          const roomEmail = mappings[0]!.resource_email
          const token = await getAccessToken()
          const graphEvent = await createGraphEvent(roomEmail, {
            subject: meeting_title.trim(),
            body: description || undefined,
            start: { dateTime: startDt.toISOString(), timeZone: 'UTC' },
            end: { dateTime: endDt.toISOString(), timeZone: 'UTC' },
            attendees: currentUser.email
              ? [{ emailAddress: { address: currentUser.email, name: currentUser.name || currentUser.username }, type: 'required' }]
              : undefined
          }, token)

          // Store Graph event IDs back on the reservation for future sync
          await sql`
            UPDATE room_reservations
            SET graph_event_id = ${graphEvent.id},
                ical_uid       = ${graphEvent.iCalUId},
                change_key     = ${graphEvent.changeKey}
            WHERE id = ${reservation.id as number}
          `
          reservation = { ...reservation, graph_event_id: graphEvent.id }
        }
      }
    } catch (err) {
      // Graph push is best-effort; the local reservation is already created
      console.error('[room-reservations] Graph push failed:', err)
    }
  }

  return reservation
})
