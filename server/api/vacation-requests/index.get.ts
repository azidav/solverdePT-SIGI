import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const canViewTeam = await hasUserPermission(event, ['VACATION:VIEW_TEAM'])
  const canViewOwn = await hasUserPermission(event, ['VACATION:VIEW_OWN'])

  // RH members can access the unprocessed list even without VIEW_TEAM
  const [isRhMember] = await sql`
    SELECT 1 FROM approval_level_members alm
    INNER JOIN approval_levels al ON al.id = alm.level_id
    WHERE alm.user_id = ${currentUser.id} AND al.is_rh = true LIMIT 1
  `

  const query = getQuery(event)
  const unprocessed = query.unprocessed === '1'

  if (!canViewOwn && !canViewTeam && !(unprocessed && isRhMember)) {
    throw createError({ statusCode: 403, message: 'Sem permissão para ver pedidos de férias' })
  }

  const status = query.status as string | undefined
  const year = query.year ? parseInt(query.year as string) : null
  const page = Math.max(1, parseInt(query.page as string) || 1)
  const limit = Math.min(100, parseInt(query.limit as string) || 20)
  const offset = (page - 1) * limit

  const ownOnly = query.own === '1'

  let whereClause = sql`WHERE 1=1`

  if (!canViewTeam || ownOnly) {
    whereClause = sql`${whereClause} AND vr.employee_id = ${currentUser.id}`
  }

  if (unprocessed) {
    whereClause = sql`${whereClause} AND vr.status = 'approved' AND vr.processed_externally = false`
  } else if (status) {
    whereClause = sql`${whereClause} AND vr.status = ${status}`
  }

  if (year) {
    whereClause = sql`${whereClause} AND EXTRACT(YEAR FROM vr.start_date) = ${year}`
  }

  const [countRow] = await sql`
    SELECT COUNT(*) AS total
    FROM vacation_requests vr
    ${whereClause}
  `

  const rows = await sql`
    SELECT
      vr.id,
      vr.type,
      vr.start_date,
      vr.end_date,
      vr.days_count,
      vr.status,
      vr.current_approval_step,
      vr.created_at,
      vr.updated_at,
      u.id   AS employee_id,
      u.name AS employee_name,
      u.department
    FROM vacation_requests vr
    INNER JOIN users u ON vr.employee_id = u.id
    ${whereClause}
    ORDER BY vr.created_at DESC
    LIMIT ${limit} OFFSET ${offset}
  `

  return {
    data: rows,
    pagination: {
      page,
      limit,
      total: parseInt(countRow!.total as string),
      totalPages: Math.ceil(parseInt(countRow!.total as string) / limit)
    }
  }
})
