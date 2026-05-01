import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { getAccessToken, getMsGraphConfig, createGraphSubscription } from '~~/server/utils/msgraph'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Não autenticado' })
  if (currentUser.permission !== 0) throw createError({ statusCode: 403, message: 'Acesso negado' })

  const { mapping_id } = await readBody(event)
  if (!mapping_id) throw createError({ statusCode: 400, message: 'mapping_id é obrigatório' })

  const mappings = await sql<{ id: number; room_id: number; resource_email: string }[]>`
    SELECT id, room_id, resource_email FROM room_graph_mappings WHERE id = ${mapping_id} LIMIT 1
  `
  if (!mappings.length) throw createError({ statusCode: 404, message: 'Mapeamento não encontrado' })
  const mapping = mappings[0]!

  const config = await getMsGraphConfig()
  if (config.msgraph_enabled !== 'true') {
    throw createError({ statusCode: 503, message: 'Integração Microsoft Graph não está activada' })
  }

  // Build the public webhook URL from the incoming request headers
  const forwardedProto = getHeader(event, 'x-forwarded-proto') || 'https'
  const forwardedHost = getHeader(event, 'x-forwarded-host') || getHeader(event, 'host') || ''
  const notificationUrl = `${forwardedProto}://${forwardedHost}/api/webhook/msgraph`

  const token = await getAccessToken()
  const sub = await createGraphSubscription(
    mapping.resource_email,
    notificationUrl,
    config.msgraph_webhook_secret || '',
    token
  )

  const rows = await sql`
    INSERT INTO msgraph_subscriptions
      (subscription_id, room_id, resource_email, expiration_datetime)
    VALUES
      (${sub.id}, ${mapping.room_id}, ${mapping.resource_email}, ${new Date(sub.expirationDateTime)})
    ON CONFLICT (subscription_id) DO UPDATE
      SET expiration_datetime = EXCLUDED.expiration_datetime,
          updated_at = NOW()
    RETURNING id, subscription_id, resource_email, expiration_datetime, created_at
  `

  return rows[0]
})
