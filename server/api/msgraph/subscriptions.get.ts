import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Não autenticado' })
  if (currentUser.permission !== 0) throw createError({ statusCode: 403, message: 'Acesso negado' })

  const rows = await sql`
    SELECT s.id, s.subscription_id, s.resource_email, s.expiration_datetime,
           s.created_at, s.updated_at,
           r.name AS room_name
    FROM msgraph_subscriptions s
    LEFT JOIN meeting_rooms r ON r.id = s.room_id
    ORDER BY s.expiration_datetime ASC
  `
  return rows
})
