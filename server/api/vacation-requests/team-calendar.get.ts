import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'

function getSubtreeIds(
  levels: { id: number, parent_id: number | null }[],
  rootId: number
): number[] {
  const result = [rootId]
  for (const l of levels) {
    if (l.parent_id === rootId) {
      result.push(...getSubtreeIds(levels, l.id))
    }
  }
  return result
}

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const canViewTeam = await hasUserPermission(event, ['VACATION:VIEW_TEAM'])
  if (!canViewTeam) throw createError({ statusCode: 403, message: 'Sem permissão para ver o calendário da equipa' })

  const canViewAll = await hasUserPermission(event, ['VACATION:VIEW_ALL_TEAM'])

  // Determine which level IDs this user is allowed to see
  let allowedLevelIds: number[] | null = null // null = unrestricted

  if (!canViewAll) {
    const allLevels = await sql<{ id: number, parent_id: number | null }[]>`
      SELECT id, parent_id FROM approval_levels
    `
    const [membership] = await sql<{ level_id: number }[]>`
      SELECT level_id FROM approval_level_members WHERE user_id = ${currentUser.id} LIMIT 1
    `
    allowedLevelIds = membership
      ? getSubtreeIds(allLevels, membership.level_id)
      : []
  }

  const query = getQuery(event)
  const month = query.month as string | undefined
  const userId = query.user_id ? parseInt(query.user_id as string) : null

  // Parse requested level_ids, then intersect with allowed set
  const requestedIds = (query.level_ids as string | undefined)
    ?.split(',').map(Number).filter(n => !isNaN(n) && n > 0) ?? []

  let effectiveLevelIds: number[]
  if (allowedLevelIds === null) {
    effectiveLevelIds = requestedIds
  } else if (requestedIds.length > 0) {
    effectiveLevelIds = requestedIds.filter(id => allowedLevelIds!.includes(id))
  } else {
    effectiveLevelIds = allowedLevelIds
  }

  let dateFilter = sql``
  if (month) {
    const [year, mon] = month.split('-').map(Number)
    const firstDay = `${year}-${String(mon).padStart(2, '0')}-01`
    const lastDay = new Date(year!, mon!, 0).toISOString().split('T')[0]!
    dateFilter = sql`AND vr.start_date <= ${lastDay} AND vr.end_date >= ${firstDay}`
  }

  const levelFilter = effectiveLevelIds.length > 0
    ? sql`AND vr.employee_id IN (SELECT user_id FROM approval_level_members WHERE level_id = ANY(${effectiveLevelIds}))`
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
