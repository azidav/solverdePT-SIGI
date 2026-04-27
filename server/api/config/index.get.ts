import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  if (currentUser.permission > 0) {
    throw createError({ statusCode: 403, message: 'Forbidden - Admin only' })
  }

  const vars = await sql`
    SELECT id, section, key, label, value, is_secret, description, input_type
    FROM config_variables
    ORDER BY section, id
  `

  return vars
})
