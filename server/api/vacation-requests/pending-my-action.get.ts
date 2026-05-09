import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

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
      u.name  AS employee_name,
      aws.role_name AS level_name
    FROM vacation_requests vr
    JOIN users u ON u.id = vr.employee_id
    JOIN approval_workflow_steps aws
      ON aws.request_id = vr.id
      AND aws.step_order = vr.current_approval_step
    JOIN approval_level_members alm
      ON alm.level_id = aws.level_id
      AND alm.user_id = ${currentUser.id}
    WHERE vr.status = 'pending'
    ORDER BY vr.created_at ASC
    LIMIT 20
  `

  return rows
})
