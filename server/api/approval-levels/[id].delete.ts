import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })
  if ((currentUser as any).permission > 0) throw createError({ statusCode: 403, message: 'Apenas administradores' })

  const id = parseInt(getRouterParam(event, 'id') || '0')
  await sql`DELETE FROM approval_levels WHERE id = ${id}`

  // Re-sequence remaining levels
  const remaining = await sql`SELECT id FROM approval_levels ORDER BY step_order ASC, id ASC`
  for (let i = 0; i < remaining.length; i++) {
    await sql`UPDATE approval_levels SET step_order = ${i + 1} WHERE id = ${remaining[i]!.id}`
  }

  return { success: true }
})
