import { randomBytes } from 'crypto'
import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { getUserRoomsPermissions } from '~~/server/utils/rooms'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  const { room_id, meeting_title, description, start_time, end_time, guest_name } = await readBody(event)

  if (!room_id || !meeting_title?.trim() || !start_time || !end_time) {
    throw createError({ statusCode: 400, message: 'Campos obrigatórios em falta' })
  }

  // Authenticated users need ROOMS:RESERVE; guests just need a name
  if (currentUser) {
    const perms = await getUserRoomsPermissions(currentUser.id)
    if (!perms.includes('ROOMS:RESERVE')) {
      throw createError({ statusCode: 403, message: 'Sem permissão para fazer reservas' })
    }
  } else {
    if (!guest_name?.trim()) {
      throw createError({ statusCode: 400, message: 'Nome obrigatório para reservas sem conta' })
    }
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

  // Strict double-booking check
  const conflicts = await sql`
    SELECT id FROM room_reservations
    WHERE room_id = ${room_id}
      AND start_time < ${endDt}
      AND end_time > ${startDt}
    LIMIT 1
  `
  if (conflicts.length > 0) {
    throw createError({ statusCode: 409, message: 'Sala já reservada para este horário' })
  }

  let result
  if (currentUser) {
    result = await sql`
      INSERT INTO room_reservations (room_id, user_id, meeting_title, description, start_time, end_time)
      VALUES (${room_id}, ${currentUser.id}, ${meeting_title.trim()}, ${description || null}, ${startDt}, ${endDt})
      RETURNING id, room_id, user_id, meeting_title, description, start_time, end_time, created_at
    `
  } else {
    const bookingToken = randomBytes(32).toString('hex')
    const tokenExpiresAt = new Date(Date.now() + 10 * 60 * 1000)

    result = await sql`
      INSERT INTO room_reservations (room_id, guest_name, booking_token, token_expires_at, meeting_title, description, start_time, end_time)
      VALUES (${room_id}, ${guest_name.trim()}, ${bookingToken}, ${tokenExpiresAt}, ${meeting_title.trim()}, ${description || null}, ${startDt}, ${endDt})
      RETURNING id, room_id, guest_name, meeting_title, description, start_time, end_time, booking_token, token_expires_at, created_at
    `
  }

  return result[0]
})
