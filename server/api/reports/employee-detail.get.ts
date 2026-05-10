import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const canView = await hasUserPermission(event, ['VACATION:VIEW_TEAM'])
  if (!canView) throw createError({ statusCode: 403, message: 'Sem permissão para exportar relatórios' })

  const query = getQuery(event)
  const userId = query.user_id ? parseInt(query.user_id as string) : null
  const year   = query.year    ? parseInt(query.year as string)    : null

  if (!userId || isNaN(userId)) throw createError({ statusCode: 400, message: 'Parâmetro "user_id" obrigatório' })

  const [employee] = await sql`
    SELECT id, employee_no, name, email, department, job_title, hire_date, birthday
    FROM users WHERE id = ${userId}
  `
  if (!employee) throw createError({ statusCode: 404, message: 'Colaborador não encontrado' })

  const balanceWhere = year ? sql`AND lb.year = ${year}` : sql``
  const balances = await sql`
    SELECT
      lb.year,
      lb.base_days,
      lb.carryover_days,
      lb.birthday_bonus,
      lb.used_days,
      lb.pending_days,
      (lb.base_days + lb.carryover_days + lb.birthday_bonus)
        - lb.used_days - lb.pending_days AS available
    FROM leave_balances lb
    WHERE lb.employee_id = ${userId}
    ${balanceWhere}
    ORDER BY lb.year DESC
  `

  const requestWhere = year ? sql`AND EXTRACT(YEAR FROM vr.start_date) = ${year}` : sql``
  const requests = await sql`
    SELECT
      vr.id,
      vr.type,
      vt.name AS type_name,
      vr.start_date,
      vr.end_date,
      vr.days_count,
      vr.half_day,
      vr.status,
      vr.reason,
      vr.created_at,
      COALESCE(
        json_agg(
          json_build_object(
            'step_order', aws.step_order,
            'role_name',  aws.role_name,
            'status',     aws.status,
            'approver',   ua.name,
            'actioned_at',aws.actioned_at,
            'comment',    aws.comment
          ) ORDER BY aws.step_order ASC
        ) FILTER (WHERE aws.id IS NOT NULL),
        '[]'::json
      ) AS approval_steps
    FROM vacation_requests vr
    LEFT JOIN vacation_types vt ON vt.code = vr.type
    LEFT JOIN approval_workflow_steps aws ON aws.request_id = vr.id
    LEFT JOIN users ua ON ua.id = aws.approver_id
    WHERE vr.employee_id = ${userId}
    ${requestWhere}
    GROUP BY vr.id, vt.name
    ORDER BY vr.start_date DESC
  `

  return {
    employee,
    balances: balances.map(b => ({
      year:           Number(b.year),
      base_days:      Number(b.base_days),
      carryover_days: Number(b.carryover_days),
      birthday_bonus: Number(b.birthday_bonus),
      used_days:      Number(b.used_days),
      pending_days:   Number(b.pending_days),
      available:      Number(b.available)
    })),
    requests: requests.map(r => ({
      ...r,
      days_count:     Number(r.days_count),
      approval_steps: r.approval_steps ?? []
    }))
  }
})
