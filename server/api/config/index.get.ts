import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const canView = await hasUserPermission(event, ['SETTINGS:VIEW'])
  if (!canView) throw createError({ statusCode: 403, message: 'Sem permissão para ver configurações' })

  const vars = await sql`
    SELECT id, section, key, label, value, is_secret, description, input_type
    FROM config_variables
    ORDER BY section, id
  `

  return vars
})
