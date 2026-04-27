import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const userId = getRouterParam(event, 'id')
  if (!userId) throw createError({ statusCode: 400, message: 'User ID is required' })

  try {
    const users = await sql`
      SELECT
        u.id, u.username, u.name, u.email, u.department, u.job_title,
        u.permission, u.status, u.role_id, u.created_at, u.updated_at,
        COALESCE(
          (
            SELECT json_agg(json_build_object('id', r.id, 'name', r.name))
            FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = u.id
          ),
          '[]'::json
        ) as roles
      FROM users u
      WHERE u.id = ${parseInt(userId)}
    `

    if (users.length === 0) {
      throw createError({ statusCode: 404, message: 'User not found' })
    }

    return users[0]
  } catch (error: unknown) {
    if (error instanceof Error && 'statusCode' in error) throw error
    const message = error instanceof Error ? error.message : 'Error fetching user'
    throw createError({ statusCode: 500, message })
  }
})
