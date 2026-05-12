import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { getAccessToken, deleteGraphSubscription } from '~~/server/utils/msgraph'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Não autenticado' })
  if (currentUser.permission !== 0) throw createError({ statusCode: 403, message: 'Acesso negado' })

  const id = Number(getRouterParam(event, 'id'))
  if (!id) throw createError({ statusCode: 400, message: 'ID inválido' })

  const rows = await sql<{ subscription_id: string }[]>`
    SELECT subscription_id FROM msgraph_subscriptions WHERE id = ${id} LIMIT 1
  `
  if (!rows.length) throw createError({ statusCode: 404, message: 'Subscrição não encontrada' })

  // Best-effort deletion in Graph (it may already be expired)
  try {
    const token = await getAccessToken()
    await deleteGraphSubscription(rows[0]!.subscription_id, token)
  } catch {
    // Ignore — Graph subscription may have already expired
  }

  await sql`DELETE FROM msgraph_subscriptions WHERE id = ${id}`

  return { success: true }
})
