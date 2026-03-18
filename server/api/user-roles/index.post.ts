import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { logUserAction } from '~~/server/utils/audit'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // Check permission
  if (currentUser.permission > 1) {
    throw createError({ statusCode: 403, message: 'Forbidden - Requires admin permissions' })
  }

  const body = await readBody(event)
  const { user_id, role_ids } = body

  if (!user_id || !Array.isArray(role_ids)) {
    throw createError({ statusCode: 400, message: 'user_id and role_ids array are required' })
  }

  // Get user info for audit
  const [targetUser] = await sql`SELECT id, name FROM users WHERE id = ${user_id}`
  if (!targetUser) {
    throw createError({ statusCode: 404, message: 'User not found' })
  }

  // Get current roles for comparison
  const currentRoles = await sql`
    SELECT role_id FROM user_roles WHERE user_id = ${user_id}
  `
  const currentRoleIds = currentRoles.map(r => r.role_id)

  // Delete existing roles
  await sql`DELETE FROM user_roles WHERE user_id = ${user_id}`

  // Insert new roles
  if (role_ids.length > 0) {
    for (const roleId of role_ids) {
      await sql`
        INSERT INTO user_roles (user_id, role_id, assigned_by)
        VALUES (${user_id}, ${roleId}, ${currentUser.id})
      `
    }
  }

  // Also update the legacy role_id column (for backwards compatibility)
  const primaryRoleId = role_ids.length > 0 ? role_ids[0] : null
  await sql`UPDATE users SET role_id = ${primaryRoleId} WHERE id = ${user_id}`

  // Get role names for audit
  const roleNames = await sql`SELECT id, name FROM roles WHERE id = ANY(${role_ids})`
  const roleNamesStr = roleNames.map(r => r.name).join(', ')

  // Audit log
  await logUserAction(
    event,
    currentUser,
    'UPDATE',
    'USER_ROLE',
    user_id,
    targetUser.name
  )

  return { success: true, message: 'Roles updated successfully' }
})
