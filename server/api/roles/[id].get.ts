import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const roleId = getRouterParam(event, 'id')
  if (!roleId) throw createError({ statusCode: 400, message: 'Role ID is required' })

  const roles = await sql`
    SELECT id, name, description, is_system, created_at
    FROM roles
    WHERE id = ${parseInt(roleId)}
  `

  if (roles.length === 0) {
    throw createError({ statusCode: 404, message: 'Role not found' })
  }

  return roles[0]
})
