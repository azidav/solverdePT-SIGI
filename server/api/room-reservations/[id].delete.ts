import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { getUserRoomsPermissions } from '~~/server/utils/rooms'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  const reservationId = parseInt(getRouterParam(event, 'id') || '0')
  if (!reservationId) throw createError({ statusCode: 400, message: 'ID inválido' })

  const body = await readBody(event).catch(() => ({})) as { booking_token?: string }

  const rows = await sql`SELECT * FROM room_reservations WHERE id = ${reservationId} LIMIT 1`
  if (rows.length === 0) throw createError({ statusCode: 404, message: 'Reserva não encontrada' })

  const reservation = rows[0]

  if (currentUser) {
    const perms = await getUserRoomsPermissions(currentUser.id)
    const canCancelAny = perms.includes('ROOMS:CANCEL_ANY')
    const isOwn = reservation.user_id === currentUser.id

    if (!canCancelAny && !isOwn) {
      throw createError({ statusCode: 403, message: 'Sem permissão para cancelar esta reserva' })
    }
  } else {
    // Guest cancellation — token required and must not be expired
    if (!body.booking_token) {
      throw createError({ statusCode: 401, message: 'Token obrigatório para cancelar reserva de convidado' })
    }
    if (reservation.booking_token !== body.booking_token) {
      throw createError({ statusCode: 403, message: 'Token inválido' })
    }
    if (!reservation.token_expires_at || new Date(reservation.token_expires_at) < new Date()) {
      throw createError({ statusCode: 403, message: 'O prazo para cancelar esta reserva expirou (10 min)' })
    }
  }

  await sql`DELETE FROM room_reservations WHERE id = ${reservationId}`
  return { success: true }
})
