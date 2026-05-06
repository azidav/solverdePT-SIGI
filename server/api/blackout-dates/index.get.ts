import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const rows = await sql`
    SELECT
      bd.*,
      u.name AS created_by_name
    FROM blackout_dates bd
    LEFT JOIN users u ON bd.created_by = u.id
    ORDER BY bd.start_date ASC
  `

  return rows
})
