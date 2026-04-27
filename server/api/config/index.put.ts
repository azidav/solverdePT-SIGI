import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  if (currentUser.permission > 0) {
    throw createError({ statusCode: 403, message: 'Forbidden - Admin only' })
  }

  const updates = await readBody(event) as { key: string; value: string }[]

  if (!Array.isArray(updates) || updates.length === 0) {
    throw createError({ statusCode: 400, message: 'Expected array of { key, value }' })
  }

  for (const { key, value } of updates) {
    await sql`
      UPDATE config_variables
      SET value = ${value ?? ''}, updated_at = NOW()
      WHERE key = ${key}
    `
  }

  return { success: true }
})
