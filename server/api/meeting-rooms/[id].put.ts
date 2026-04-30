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

  const roomId = parseInt(getRouterParam(event, 'id') || '0')
  if (!roomId) throw createError({ statusCode: 400, message: 'ID inválido' })

  const body = await readBody(event)
  const updateData: Record<string, unknown> = {}

  if (body.name !== undefined) updateData.name = body.name
  if (body.description !== undefined) updateData.description = body.description
  if (body.image_url !== undefined) updateData.image_url = body.image_url
  if (body.capacity !== undefined) updateData.capacity = body.capacity
  if (body.location !== undefined) updateData.location = body.location
  if (body.amenities !== undefined) updateData.amenities = body.amenities
  if (body.status !== undefined) updateData.status = body.status
  updateData.updated_at = new Date()

  const result = await sql`
    UPDATE meeting_rooms SET ${sql(updateData)} WHERE id = ${roomId} RETURNING *
  `
  if (result.length === 0) throw createError({ statusCode: 404, message: 'Sala não encontrada' })
  return result[0]
})
