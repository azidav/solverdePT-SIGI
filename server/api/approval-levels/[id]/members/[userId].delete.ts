import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })
  if ((currentUser as any).permission > 0) throw createError({ statusCode: 403, message: 'Apenas administradores' })

  const levelId = parseInt(getRouterParam(event, 'id') || '0')
  const userId = parseInt(getRouterParam(event, 'userId') || '0')

  await sql`DELETE FROM approval_level_members WHERE level_id = ${levelId} AND user_id = ${userId}`
  return { success: true }
})
