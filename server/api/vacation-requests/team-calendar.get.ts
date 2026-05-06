import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const canViewTeam = await hasUserPermission(event, ['VACATION:VIEW_TEAM'])
  if (!canViewTeam) throw createError({ statusCode: 403, message: 'Sem permissão para ver o calendário da equipa' })

  const query = getQuery(event)
  const month = query.month as string | undefined
  const levelIdsParam = query.level_ids as string | undefined
  const levelIds = levelIdsParam
    ? levelIdsParam.split(',').map(Number).filter(n => !isNaN(n) && n > 0)
    : []
  const userId = query.user_id ? parseInt(query.user_id as string) : null

  let dateFilter = sql``
  if (month) {
    const [year, mon] = month.split('-').map(Number)
    const firstDay = `${year}-${String(mon).padStart(2, '0')}-01`
    const lastDay = new Date(year!, mon!, 0).toISOString().split('T')[0]!
    dateFilter = sql`AND vr.start_date <= ${lastDay} AND vr.end_date >= ${firstDay}`
  }

  const levelFilter = levelIds.length > 0
    ? sql`AND vr.employee_id IN (SELECT user_id FROM approval_level_members WHERE level_id = ANY(${levelIds}))`
    : sql``

  const userFilter = userId ? sql`AND vr.employee_id = ${userId}` : sql``

  const rows = await sql`
    SELECT
      vr.id,
      vr.employee_id,
      vr.type,
      vr.start_date,
      vr.end_date,
      vr.days_count,
      u.name AS employee_name,
      SPLIT_PART(u.name, ' ', 1) AS employee_first_name,
      u.department
    FROM vacation_requests vr
    INNER JOIN users u ON vr.employee_id = u.id
    WHERE vr.status = 'approved'
      ${levelFilter}
      ${userFilter}
      ${dateFilter}
    ORDER BY u.name ASC, vr.start_date ASC
  `

  const [birthdayCfg] = await sql`SELECT value FROM config_variables WHERE key = 'vacation_birthday_enabled'`
  const birthdayEnabled = birthdayCfg?.value === 'true'

  return { items: rows, birthdayEnabled }
})
