import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const roleId = getRouterParam(event, 'id')
  if (!roleId) throw createError({ statusCode: 400, message: 'Role ID is required' })

  // Check role exists
  const roles = await sql`
    SELECT id FROM roles WHERE id = ${parseInt(roleId)}
  `
  if (roles.length === 0) {
    throw createError({ statusCode: 404, message: 'Role not found' })
  }

  // Get permissions for role
  const permissions = await sql`
    SELECT p.id, p.code, p.description, p.module, p.action
    FROM role_permissions rp
    INNER JOIN permissions p ON rp.permission_id = p.id
    WHERE rp.role_id = ${parseInt(roleId)}
    ORDER BY p.module, p.action
  `

  return permissions
})
