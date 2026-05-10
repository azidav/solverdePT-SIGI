import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const canView = await hasUserPermission(event, ['VACATION:VIEW_TEAM'])
  if (!canView) throw createError({ statusCode: 403, message: 'Sem permissão para exportar relatórios' })

  const year = parseInt(getQuery(event).year as string)
  if (!year || isNaN(year)) throw createError({ statusCode: 400, message: 'Parâmetro "year" obrigatório' })

  const rows = await sql`
    SELECT
      u.employee_no,
      u.name,
      u.department,
      COALESCE(lb.base_days,      22) AS base_days,
      COALESCE(lb.carryover_days,  0) AS carryover_days,
      COALESCE(lb.birthday_bonus,  0) AS birthday_bonus,
      COALESCE(lb.used_days,       0) AS used_days,
      COALESCE(lb.pending_days,    0) AS pending_days,
      (
        COALESCE(lb.base_days, 22) +
        COALESCE(lb.carryover_days, 0) +
        COALESCE(lb.birthday_bonus, 0)
      ) - COALESCE(lb.used_days, 0) - COALESCE(lb.pending_days, 0) AS available
    FROM users u
    LEFT JOIN leave_balances lb ON lb.employee_id = u.id AND lb.year = ${year}
    WHERE u.status = 1
    ORDER BY u.department ASC NULLS LAST, u.name ASC
  `

  return rows.map(r => ({
    employee_no:    r.employee_no ?? '',
    name:           r.name,
    department:     r.department ?? '',
    base_days:      Number(r.base_days),
    carryover_days: Number(r.carryover_days),
    birthday_bonus: Number(r.birthday_bonus),
    used_days:      Number(r.used_days),
    pending_days:   Number(r.pending_days),
    available:      Number(r.available)
  }))
})
