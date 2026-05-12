import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Não autenticado' })
  if (currentUser.permission !== 0) throw createError({ statusCode: 403, message: 'Acesso negado' })

  const rows = await sql`
    SELECT m.id, m.room_id, m.resource_email, m.created_at,
           r.name AS room_name
    FROM room_graph_mappings m
    JOIN meeting_rooms r ON r.id = m.room_id
    ORDER BY r.name
  `
  return rows
})
