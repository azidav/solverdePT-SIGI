import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  if (currentUser.permission > 0) {
    throw createError({ statusCode: 403, message: 'Forbidden - Admin only' })
  }

  const users = await sql`
    SELECT
      u.id,
      u.username,
      u.name,
      u.email,
      u.department,
      u.permission,
      u.status,
      u.role_id,
      r.name as role_name,
      u.created_at,
      u.updated_at,
      COALESCE(
        (
          SELECT json_agg(json_build_object('id', ur_r.id, 'name', ur_r.name))
          FROM user_roles ur
          JOIN roles ur_r ON ur.role_id = ur_r.id
          WHERE ur.user_id = u.id
        ),
        '[]'::json
      ) as roles
    FROM users u
    LEFT JOIN roles r ON u.role_id = r.id
    WHERE u.status = -1
    ORDER BY u.updated_at DESC
  `

  return users
})
