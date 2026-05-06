import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { advanceWorkflow } from '~~/server/utils/vacation'
import { logUserAction } from '~~/server/utils/audit'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const id = parseInt(getRouterParam(event, 'id') || '')
  if (isNaN(id)) throw createError({ statusCode: 400, message: 'ID inválido' })

  const [req] = await sql`SELECT current_approval_step FROM vacation_requests WHERE id = ${id}`
  if (!req) throw createError({ statusCode: 404, message: 'Pedido não encontrado' })

  const [step] = await sql`
    SELECT level_id FROM approval_workflow_steps
    WHERE request_id = ${id} AND step_order = ${req.current_approval_step}
  `
  if (!step) throw createError({ statusCode: 422, message: 'Não há passos de aprovação pendentes' })

  if (step.level_id) {
    const [membership] = await sql`
      SELECT id FROM approval_level_members
      WHERE level_id = ${step.level_id} AND user_id = ${currentUser.id}
    `
    if (!membership) throw createError({ statusCode: 403, message: 'Não é membro do nível de aprovação atual' })
  }

  const body = await readBody(event)
  await advanceWorkflow(event, id, currentUser as any, true, body?.comment)
  await logUserAction(event, currentUser as any, 'APPROVE', 'VACATION_REQUEST', id, undefined)

  return { success: true }
})
