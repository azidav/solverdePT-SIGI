import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const id = parseInt(getRouterParam(event, 'id') || '')
  if (isNaN(id)) throw createError({ statusCode: 400, message: 'ID inválido' })

  const [request] = await sql`
    SELECT
      vr.*,
      u.name AS employee_name,
      u.department
    FROM vacation_requests vr
    INNER JOIN users u ON vr.employee_id = u.id
    WHERE vr.id = ${id}
  `

  if (!request) throw createError({ statusCode: 404, message: 'Pedido não encontrado' })

  const isOwner = (request as any).employee_id === currentUser.id
  const canViewTeam = await hasUserPermission(event, ['VACATION:VIEW_TEAM'])

  if (!isOwner && !canViewTeam) {
    // Allow level members of this request's workflow to view it
    const [levelAccess] = await sql`
      SELECT 1
      FROM approval_workflow_steps aws
      JOIN approval_level_members alm ON alm.level_id = aws.level_id
      WHERE aws.request_id = ${id} AND alm.user_id = ${currentUser.id}
      LIMIT 1
    `
    // Also allow RH group members (they need to mark requests as processed)
    const [rhAccess] = await sql`
      SELECT 1 FROM approval_level_members alm
      INNER JOIN approval_levels al ON al.id = alm.level_id
      WHERE alm.user_id = ${currentUser.id} AND al.is_rh = true
      LIMIT 1
    `
    if (!levelAccess && !rhAccess) throw createError({ statusCode: 403, message: 'Sem permissão para ver este pedido' })
  }

  const history = await sql`
    SELECT * FROM vacation_request_history
    WHERE request_id = ${id}
    ORDER BY actioned_at ASC
  `

  const steps = await sql`
    SELECT * FROM approval_workflow_steps
    WHERE request_id = ${id}
    ORDER BY step_order ASC
  `

  // Determine if current user can act on the current approval step
  let can_act = false
  if ((request as any).status === 'pending') {
    const currentStep = (request as any).current_approval_step
    const [step] = await sql`
      SELECT level_id FROM approval_workflow_steps
      WHERE request_id = ${id} AND step_order = ${currentStep}
    `
    if (step?.level_id) {
      const [membership] = await sql`
        SELECT 1 FROM approval_level_members
        WHERE level_id = ${step.level_id} AND user_id = ${currentUser.id}
      `
      can_act = !!membership
    }
  }

  // Determine if current user can undo the approval
  // Allowed when: status is approved, not yet processed externally,
  // and the user is a member of the level that approved the (last) step
  let can_undo = false
  if ((request as any).status === 'approved' && !(request as any).processed_externally) {
    const [approvedStep] = await sql`
      SELECT level_id FROM approval_workflow_steps
      WHERE request_id = ${id} AND status = 'approved'
      ORDER BY step_order DESC LIMIT 1
    `
    if (approvedStep?.level_id) {
      const [membership] = await sql`
        SELECT 1 FROM approval_level_members
        WHERE level_id = ${approvedStep.level_id} AND user_id = ${currentUser.id}
      `
      can_undo = !!membership
    }
  }

  return { ...request, history, steps, can_act, can_undo }
})
