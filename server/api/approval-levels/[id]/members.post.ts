import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })
  if ((currentUser as any).permission > 0) throw createError({ statusCode: 403, message: 'Apenas administradores' })

  const levelId = parseInt(getRouterParam(event, 'id') || '0')
  const { user_ids } = await readBody(event)
  if (!Array.isArray(user_ids) || user_ids.length === 0) {
    throw createError({ statusCode: 400, message: 'user_ids obrigatório' })
  }

  for (const userId of user_ids) {
    await sql`
      INSERT INTO approval_level_members (level_id, user_id)
      VALUES (${levelId}, ${userId})
      ON CONFLICT (level_id, user_id) DO NOTHING
    `
  }

  return { success: true }
})
