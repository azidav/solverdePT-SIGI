import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Não autenticado' })
  if (currentUser.permission !== 0) throw createError({ statusCode: 403, message: 'Acesso negado' })

  const { room_id, resource_email } = await readBody(event)
  if (!room_id || !resource_email?.trim()) {
    throw createError({ statusCode: 400, message: 'room_id e resource_email são obrigatórios' })
  }

  const rooms = await sql`SELECT id FROM meeting_rooms WHERE id = ${room_id} LIMIT 1`
  if (!rooms.length) throw createError({ statusCode: 404, message: 'Sala não encontrada' })

  try {
    const rows = await sql`
      INSERT INTO room_graph_mappings (room_id, resource_email)
      VALUES (${room_id}, ${resource_email.trim().toLowerCase()})
      RETURNING id, room_id, resource_email, created_at
    `
    return rows[0]
  } catch (err: any) {
    if (err?.code === '23505') {
      throw createError({ statusCode: 409, message: 'Este email de recurso já está mapeado' })
    }
    throw err
  }
})
