import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const userId = getQuery(event).user_id

  if (userId) {
    // Get roles for a specific user
    const roles = await sql`
      SELECT r.id, r.name, r.description, ur.assigned_at, u.name as assigned_by_name
      FROM user_roles ur
      JOIN roles r ON ur.role_id = r.id
      LEFT JOIN users u ON ur.assigned_by = u.id
      WHERE ur.user_id = ${parseInt(userId as string)}
      ORDER BY r.name ASC
    `
    return roles
  }

  // Get all user-role assignments
  const userRoles = await sql`
    SELECT ur.id, ur.user_id, ur.role_id, ur.assigned_at,
           u.name as user_name, r.name as role_name
    FROM user_roles ur
    JOIN users u ON ur.user_id = u.id
    JOIN roles r ON ur.role_id = r.id
    ORDER BY u.name ASC
  `

  return userRoles
})
