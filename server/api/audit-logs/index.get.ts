import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // Only Admin can view audit logs
  if (currentUser.permission > 0) {
    throw createError({ statusCode: 403, message: 'Forbidden - Admin access required' })
  }

  const query = getQuery(event)
  const { start_date, end_date, action, entity_type, user_id, page = '1', limit = '50' } = query

  const pageNum = parseInt(page as string, 10) || 1
  const limitNum = Math.min(parseInt(limit as string, 10) || 50, 100)
  const offset = (pageNum - 1) * limitNum

  // Build dynamic query conditions
  let conditions = sql`1=1`

  if (start_date) {
    conditions = sql`${conditions} AND al.created_at >= ${start_date}::date`
  }

  if (end_date) {
    conditions = sql`${conditions} AND al.created_at < (${end_date}::date + interval '1 day')`
  }

  if (action) {
    conditions = sql`${conditions} AND al.action = ${action}`
  }

  if (entity_type) {
    conditions = sql`${conditions} AND al.entity_type = ${entity_type}`
  }

  if (user_id) {
    conditions = sql`${conditions} AND al.user_id = ${parseInt(user_id as string, 10)}`
  }

  // Get total count
  const [countResult] = await sql`
    SELECT COUNT(*) as total
    FROM audit_logs al
    WHERE ${conditions}
  `

  // Get paginated logs
  const logs = await sql`
    SELECT
      al.id,
      al.user_id,
      al.user_name,
      al.action,
      al.entity_type,
      al.entity_id,
      al.entity_name,
      al.ip_address,
      al.user_agent,
      al.created_at
    FROM audit_logs al
    WHERE ${conditions}
    ORDER BY al.created_at DESC
    LIMIT ${limitNum}
    OFFSET ${offset}
  `

  return {
    data: logs,
    pagination: {
      page: pageNum,
      limit: limitNum,
      total: parseInt(countResult.total, 10),
      totalPages: Math.ceil(parseInt(countResult.total, 10) / limitNum)
    }
  }
})
