import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // List all roles with user count from user_roles table
  const roles = await sql`
    SELECT
      r.id,
      r.name,
      r.description,
      r.is_system,
      r.created_at,
      r.updated_at,
      (SELECT COUNT(*) FROM user_roles ur WHERE ur.role_id = r.id) as users_count,
      COALESCE(
        (
          SELECT json_agg(json_build_object('id', u.id, 'name', u.name, 'email', u.email))
          FROM user_roles ur
          JOIN users u ON ur.user_id = u.id
          WHERE ur.role_id = r.id
        ),
        '[]'::json
      ) as users
    FROM roles r
    ORDER BY r.name ASC
  `
  return roles
})
