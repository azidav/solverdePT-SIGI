import sql from '~~/server/utils/db'
import { getUserFromEvent, getUserPermissions } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // Get user with role and full details
  const users = await sql`
    SELECT
      u.id, u.username, u.name, u.email, u.department,
      r.id as role_id, r.name as role_name, r.description as role_description
    FROM users u
    LEFT JOIN roles r ON u.role_id = r.id
    WHERE u.id = ${currentUser.id}
  `

  if (users.length === 0) {
    throw createError({ statusCode: 404, message: 'User not found' })
  }

  const user = users[0]

  // Get permissions via user_roles (multi-role, authoritative source)
  const permissions = await sql`
    SELECT DISTINCT p.id, p.code, p.description, p.module, p.action
    FROM user_roles ur
    INNER JOIN roles r ON ur.role_id = r.id
    INNER JOIN role_permissions rp ON r.id = rp.role_id
    INNER JOIN permissions p ON rp.permission_id = p.id
    WHERE ur.user_id = ${currentUser.id}
    ORDER BY p.module, p.action
  `

  const permissionCodes = permissions.map((p: any) => p.code)

  return {
    user: {
      id: user.id,
      username: user.username,
      name: user.name,
      email: user.email,
      department: user.department,
      role: {
        id: user.role_id,
        name: user.role_name,
        description: user.role_description
      }
    },
    permissions,
    permissionCodes
  }
})
