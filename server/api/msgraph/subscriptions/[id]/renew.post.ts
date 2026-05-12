import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { getAccessToken, renewGraphSubscription } from '~~/server/utils/msgraph'

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

  const token = await getAccessToken()
  const renewed = await renewGraphSubscription(rows[0]!.subscription_id, token)

  const updated = await sql`
    UPDATE msgraph_subscriptions
    SET expiration_datetime = ${new Date(renewed.expirationDateTime)}, updated_at = NOW()
    WHERE id = ${id}
    RETURNING id, subscription_id, resource_email, expiration_datetime, updated_at
  `

  return updated[0]
})
