import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { getUserRoomsPermissions } from '~~/server/utils/rooms'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const perms = await getUserRoomsPermissions(currentUser.id)
  if (!perms.includes('ROOMS:MANAGE')) {
    throw createError({ statusCode: 403, message: 'Requer permissão ROOMS:MANAGE' })
  }

  const { name, description, image_url, capacity, location, amenities, status } = await readBody(event)
  if (!name?.trim()) throw createError({ statusCode: 400, message: 'Nome da sala obrigatório' })

  const result = await sql`
    INSERT INTO meeting_rooms (name, description, image_url, capacity, location, amenities, status)
    VALUES (
      ${name.trim()},
      ${description || null},
      ${image_url || null},
      ${capacity || 0},
      ${location || null},
      ${amenities || null},
      ${status || 'active'}
    )
    RETURNING *
  `
  return result[0]
})
