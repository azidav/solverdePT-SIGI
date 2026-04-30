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

  await sql`DELETE FROM meeting_rooms WHERE id = ${roomId}`
  return { success: true }
})
