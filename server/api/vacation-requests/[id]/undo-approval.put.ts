import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const id = parseInt(getRouterParam(event, 'id') || '0')
  if (!id) throw createError({ statusCode: 400, message: 'ID inválido' })

  const [request] = await sql<{
    status: string
    processed_externally: boolean
    employee_id: number
    days_count: number
    type: string
    start_date: string
  }[]>`
    SELECT status, processed_externally, employee_id, days_count, type, start_date
    FROM vacation_requests WHERE id = ${id}
  `
  if (!request) throw createError({ statusCode: 404, message: 'Pedido não encontrado' })
  if (request.status !== 'approved') throw createError({ statusCode: 409, message: 'Só é possível reverter pedidos aprovados' })
  if (request.processed_externally) throw createError({ statusCode: 409, message: 'Não é possível reverter um pedido já processado externamente' })

  // Only members of the level that approved the step can undo
  const [approvedStep] = await sql<{ level_id: number | null, step_order: number }[]>`
    SELECT level_id, step_order FROM approval_workflow_steps
    WHERE request_id = ${id} AND status = 'approved'
    ORDER BY step_order DESC LIMIT 1
  `
  if (!approvedStep) throw createError({ statusCode: 409, message: 'Nenhum passo aprovado encontrado' })

  if (approvedStep.level_id) {
    const [membership] = await sql`
      SELECT 1 FROM approval_level_members
      WHERE level_id = ${approvedStep.level_id} AND user_id = ${currentUser.id}
    `
    if (!membership) throw createError({ statusCode: 403, message: 'Sem permissão para reverter esta aprovação' })
  }

  const daysCount = Number(request.days_count)
  const year = new Date(String(request.start_date)).getFullYear()

  const [vacType] = await sql<{ uses_balance: boolean }[]>`
    SELECT uses_balance FROM vacation_types WHERE code = ${request.type} LIMIT 1
  `
  const usesBalance = vacType?.uses_balance !== false

  // Revert the approved step back to pending
  await sql`
    UPDATE approval_workflow_steps
    SET status = 'pending', approver_id = NULL, comment = NULL, actioned_at = NULL
    WHERE request_id = ${id} AND step_order = ${approvedStep.step_order}
  `

  // Reset the request to pending at that step
  await sql`
    UPDATE vacation_requests
    SET status = 'pending', current_approval_step = ${approvedStep.step_order}, updated_at = NOW()
    WHERE id = ${id}
  `

  // Move used_days back to pending_days
  if (usesBalance) {
    await sql`
      UPDATE leave_balances
      SET
        used_days    = GREATEST(0, used_days - ${daysCount}),
        pending_days = pending_days + ${daysCount}
      WHERE employee_id = ${request.employee_id} AND year = ${year}
    `
  }

  // Log in history
  await sql`
    INSERT INTO vacation_request_history
      (request_id, actor_id, actor_name, old_status, new_status, step_order, comment)
    VALUES
      (${id}, ${currentUser.id}, ${(currentUser as any).name}, 'approved', 'pending',
       ${approvedStep.step_order}, 'Aprovação revertida pelo aprovador')
  `

  return { success: true }
})
