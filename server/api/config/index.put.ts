import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const canChange = await hasUserPermission(event, ['SETTINGS:CHANGE'])
  if (!canChange) throw createError({ statusCode: 403, message: 'Sem permissão para alterar configurações' })

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
