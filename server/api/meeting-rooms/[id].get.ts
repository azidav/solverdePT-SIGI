import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { getUserRoomsPermissions } from '~~/server/utils/rooms'

export default defineEventHandler(async (event) => {
  const roomId = parseInt(getRouterParam(event, 'id') || '0')
  if (!roomId) throw createError({ statusCode: 400, message: 'ID inválido' })

  // Public users only see active rooms; managers see all
  const currentUser = await getUserFromEvent(event)
  let canSeeInactive = false
  if (currentUser) {
    const perms = await getUserRoomsPermissions(currentUser.id)
    canSeeInactive = perms.includes('ROOMS:MANAGE')
  }

  const statusFilter = canSeeInactive ? sql`AND TRUE` : sql`AND mr.status = 'active'`

  const rows = await sql`
    SELECT * FROM meeting_rooms mr WHERE mr.id = ${roomId} ${statusFilter} LIMIT 1
  `
  if (rows.length === 0) throw createError({ statusCode: 404, message: 'Sala não encontrada' })
  return rows[0]
})
