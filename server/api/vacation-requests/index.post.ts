import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'
import { countWorkingDays, assertNoBlackout, createWorkflowSteps, recalculateLeaveBalance } from '~~/server/utils/vacation'
import { logUserAction } from '~~/server/utils/audit'
import { sendVacationPendingApprovalEmail, sendVacationApprovedEmail } from '~~/server/utils/email'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const canCreate = await hasUserPermission(event, ['VACATION:CREATE'])
  if (!canCreate) throw createError({ statusCode: 403, message: 'Sem permissão para criar pedidos de férias' })

  // Ensure at least one approval level is configured with members
  const [levelCheck] = await sql`
    SELECT COUNT(*) AS total
    FROM approval_levels al
    WHERE EXISTS (
      SELECT 1 FROM approval_level_members WHERE level_id = al.id
    )
  `
  if (parseInt(levelCheck!.total as string) === 0) {
    throw createError({
      statusCode: 422,
      message: 'Não existem níveis de aprovação configurados. Contacte o administrador para configurar a hierarquia de aprovação.'
    })
  }

  const body = await readBody(event)
  const { start_date, end_date, type = 'annual', reason, include_weekends = false } = body

  if (!start_date || !end_date) {
    throw createError({ statusCode: 400, message: 'Data de início e fim são obrigatórias' })
  }

  if (new Date(start_date) > new Date(end_date)) {
    throw createError({ statusCode: 400, message: 'A data de início não pode ser posterior à data de fim' })
  }

  const [employee] = await sql<{ department: string | null }[]>`
    SELECT department FROM users WHERE id = ${currentUser.id}
  `

  await assertNoBlackout(start_date, end_date, employee?.department ?? null)

  const daysCount = await countWorkingDays(start_date, end_date, employee?.department ?? null, !!include_weekends)
  if (daysCount === 0) {
    throw createError({ statusCode: 400, message: 'O período selecionado não contém dias úteis' })
  }

  const year = new Date(start_date).getFullYear()

  // Ensure balance row exists for this year
  await recalculateLeaveBalance(currentUser.id, year)

  const [balance] = await sql<{ base_days: number; seniority_bonus: number; birthday_bonus: number; carryover_days: number; used_days: number; pending_days: number }[]>`
    SELECT base_days, seniority_bonus, birthday_bonus, carryover_days, used_days, pending_days
    FROM leave_balances
    WHERE employee_id = ${currentUser.id} AND year = ${year}
  `

  const totalAllowed = (balance?.base_days ?? 22) + (balance?.seniority_bonus ?? 0) + (balance?.birthday_bonus ?? 0) + (balance?.carryover_days ?? 0)
  const totalUsedAndPending = (balance?.used_days ?? 0) + (balance?.pending_days ?? 0)

  if (totalUsedAndPending + daysCount > totalAllowed) {
    throw createError({
      statusCode: 422,
      message: `Saldo insuficiente. Disponível: ${totalAllowed - totalUsedAndPending} dias.`
    })
  }

  const [newRequest] = await sql`
    INSERT INTO vacation_requests
      (employee_id, type, start_date, end_date, days_count, reason)
    VALUES
      (${currentUser.id}, ${type}, ${start_date}, ${end_date}, ${daysCount}, ${reason || null})
    RETURNING id
  `

  const requestId = newRequest!.id as number
  const hasSteps = await createWorkflowSteps(requestId, currentUser.id)

  const host = event.node.req.headers['host'] || 'localhost:3000'
  const protocol = process.env.NODE_ENV === 'production' ? 'https' : 'http'
  const startFmt = new Intl.DateTimeFormat('pt-PT').format(new Date(start_date + 'T00:00:00'))
  const endFmt = new Intl.DateTimeFormat('pt-PT').format(new Date(end_date + 'T00:00:00'))
  const requestUrl = `${protocol}://${host}/ferias/${requestId}`

  if (!hasSteps) {
    // Employee is at the top of the hierarchy — auto-approve immediately
    await sql`
      UPDATE vacation_requests SET status = 'approved', updated_at = NOW() WHERE id = ${requestId}
    `
    await sql`
      UPDATE leave_balances
      SET used_days = used_days + ${daysCount}
      WHERE employee_id = ${currentUser.id} AND year = ${year}
    `
    await logUserAction(event, currentUser as any, 'CREATE', 'VACATION_REQUEST', requestId, `Férias ${start_date} → ${end_date}`)
    await sql`
      INSERT INTO vacation_request_history
        (request_id, actor_id, actor_name, old_status, new_status, step_order, comment)
      VALUES
        (${requestId}, ${currentUser.id}, ${(currentUser as any).name}, NULL, 'approved', 0, 'Aprovado automaticamente — sem nível superior')
    `
    const emp = currentUser as any
    if (emp.email) {
      sendVacationApprovedEmail(emp.email, emp.name, { startDate: startFmt, endDate: endFmt, daysCount, requestUrl }).catch(console.error)
    }
    return { id: requestId, days_count: daysCount, auto_approved: true }
  }

  await sql`
    UPDATE leave_balances
    SET pending_days = pending_days + ${daysCount}
    WHERE employee_id = ${currentUser.id} AND year = ${year}
  `

  await logUserAction(event, currentUser as any, 'CREATE', 'VACATION_REQUEST', requestId, `Férias ${start_date} → ${end_date}`)

  await sql`
    INSERT INTO vacation_request_history
      (request_id, actor_id, actor_name, old_status, new_status, step_order, comment)
    VALUES
      (${requestId}, ${currentUser.id}, ${(currentUser as any).name}, NULL, 'pending', 0, 'Pedido submetido')
  `

  // Notify first level approvers
  const [firstStep] = await sql<{ level_id: number | null, role_name: string }[]>`
    SELECT level_id, role_name FROM approval_workflow_steps
    WHERE request_id = ${requestId} AND step_order = 1
    LIMIT 1
  `
  if (firstStep?.level_id) {
    const approvers = await sql<{ email: string, name: string }[]>`
      SELECT u.email, u.name
      FROM approval_level_members alm
      JOIN users u ON u.id = alm.user_id
      WHERE alm.level_id = ${firstStep.level_id} AND u.status = 1 AND u.email IS NOT NULL
    `
    if (approvers.length > 0) {
      sendVacationPendingApprovalEmail(approvers, {
        employeeName: (currentUser as any).name,
        startDate: startFmt,
        endDate: endFmt,
        daysCount,
        requestUrl,
        levelName: firstStep.role_name as string
      }).catch(console.error)
    }
  }

  return { id: requestId, days_count: daysCount }
})
