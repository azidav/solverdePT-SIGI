import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'
import { logUserAction } from '~~/server/utils/audit'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // Requires SETTINGS:MANAGE_ROLES
  const hasPermission = await hasUserPermission(event, ['SETTINGS:MANAGE_ROLES'])
  if (!hasPermission) {
    throw createError({ statusCode: 403, message: 'Forbidden - Requires SETTINGS:MANAGE_ROLES' })
  }

  const roleId = getRouterParam(event, 'id')
  if (!roleId) throw createError({ statusCode: 400, message: 'Role ID is required' })

  // Check if role exists and is not system role
  const roles = await sql`
    SELECT id, is_system, name, description
    FROM roles
    WHERE id = ${parseInt(roleId)}
  `

  if (roles.length === 0) {
    throw createError({ statusCode: 404, message: 'Role not found' })
  }

  if (roles[0].is_system) {
    throw createError({ statusCode: 403, message: `Cannot delete system role: ${roles[0].name}` })
  }

  // Check if role is in use
  const usersWithRole = await sql`
    SELECT COUNT(*) as count
    FROM users
    WHERE role_id = ${parseInt(roleId)}
  `

  if (usersWithRole[0].count > 0) {
    throw createError({
      statusCode: 409,
      message: `Cannot delete role - ${usersWithRole[0].count} user(s) assigned`
    })
  }

  await sql`
    DELETE FROM roles
    WHERE id = ${parseInt(roleId)}
  `

  // Audit log
  await logUserAction(
    event,
    currentUser,
    'DELETE',
    'ROLE',
    parseInt(roleId),
    roles[0].name
  )

  return { success: true, message: 'Role deleted successfully' }
})
