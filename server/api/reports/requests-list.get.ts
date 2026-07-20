import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const canView = await hasUserPermission(event, ['VACATION:EXPORT_REPORTS'])
  if (!canView) throw createError({ statusCode: 403, message: 'Sem permissão para exportar relatórios' })

  const query = getQuery(event)
  const year       = query.year       ? parseInt(query.year as string)       : null
  const status     = query.status     ? String(query.status)                 : null
  const department = query.department ? String(query.department)             : null

  let where = sql`WHERE 1=1`
  if (year)       where = sql`${where} AND EXTRACT(YEAR FROM vr.start_date) = ${year}`
  if (status)     where = sql`${where} AND vr.status = ${status}`
  if (department) where = sql`${where} AND u.department = ${department}`

  const rows = await sql`
    SELECT
      u.name           AS employee,
      u.employee_no,
      u.department,
      vt.name          AS type_name,
      vr.type,
      vr.start_date,
      vr.end_date,
      vr.days_count,
      vr.half_day,
      vr.half_day_period,
      vr.status,
      vr.reason,
      vr.created_at,
      approver_sq.approver_name AS approved_by,
      approver_sq.actioned_at   AS approval_date
    FROM vacation_requests vr
    INNER JOIN users u ON vr.employee_id = u.id
    LEFT JOIN vacation_types vt ON vt.code = vr.type
    LEFT JOIN LATERAL (
      SELECT ua.name AS approver_name, aws.actioned_at
      FROM approval_workflow_steps aws
      LEFT JOIN users ua ON ua.id = aws.approver_id
      WHERE aws.request_id = vr.id AND aws.status = 'approved'
      ORDER BY aws.step_order DESC
      LIMIT 1
    ) approver_sq ON true
    ${where}
    ORDER BY vr.start_date ASC, u.name ASC
  `

  return rows.map(r => ({
    employee:      r.employee,
    employee_no:   r.employee_no ?? '',
    department:    r.department ?? '',
    type:          r.type,
    type_name:     r.type_name ?? r.type,
    start_date:    r.start_date,
    end_date:      r.end_date,
    days_count:    Number(r.days_count),
    half_day:      r.half_day,
    half_day_period: r.half_day_period ?? null,
    status:        r.status,
    reason:        r.reason ?? '',
    created_at:    r.created_at,
    approved_by:   r.approved_by ?? '',
    approval_date: r.approval_date ?? null
  }))
})
