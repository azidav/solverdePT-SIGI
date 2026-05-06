import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { logUserAction } from '~~/server/utils/audit'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const id = parseInt(getRouterParam(event, 'id') || '')
  if (isNaN(id)) throw createError({ statusCode: 400, message: 'ID inválido' })

  const [request] = await sql<{ employee_id: number; status: string; days_count: number; start_date: string }[]>`
    SELECT employee_id, status, days_count, start_date FROM vacation_requests WHERE id = ${id}
  `

  if (!request) throw createError({ statusCode: 404, message: 'Pedido não encontrado' })

  const canManage = (currentUser as any).permission <= 1
  if (request.employee_id !== currentUser.id && !canManage) {
    throw createError({ statusCode: 403, message: 'Sem permissão para cancelar este pedido' })
  }

  if (request.status !== 'pending') {
    throw createError({ statusCode: 409, message: 'Só é possível cancelar pedidos pendentes' })
  }

  const year = new Date(request.start_date as string).getFullYear()

  await sql`
    UPDATE vacation_requests SET status = 'cancelled', updated_at = NOW() WHERE id = ${id}
  `

  await sql`
    UPDATE leave_balances
    SET pending_days = GREATEST(0, pending_days - ${request.days_count})
    WHERE employee_id = ${request.employee_id} AND year = ${year}
  `

  await sql`
    INSERT INTO vacation_request_history
      (request_id, actor_id, actor_name, old_status, new_status, step_order, comment)
    VALUES
      (${id}, ${currentUser.id}, ${(currentUser as any).name}, 'pending', 'cancelled', NULL, 'Pedido cancelado')
  `

  await logUserAction(event, currentUser as any, 'CANCEL', 'VACATION_REQUEST', id, undefined)

  return { success: true }
})
