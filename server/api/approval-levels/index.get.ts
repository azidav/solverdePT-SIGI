import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const levels = await sql`
    SELECT
      al.id,
      al.name,
      al.description,
      al.step_order,
      al.parent_id,
      al.created_at,
      COALESCE(
        json_agg(
          json_build_object('id', u.id, 'name', u.name, 'username', u.username, 'email', u.email, 'birthday', u.birthday)
          ORDER BY u.name
        ) FILTER (WHERE u.id IS NOT NULL),
        '[]'::json
      ) AS members
    FROM approval_levels al
    LEFT JOIN approval_level_members alm ON alm.level_id = al.id
    LEFT JOIN users u ON u.id = alm.user_id AND u.status >= 0
    GROUP BY al.id
    ORDER BY al.step_order ASC, al.id ASC
  `

  return levels
})
