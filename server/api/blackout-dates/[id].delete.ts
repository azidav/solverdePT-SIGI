import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'
import { logUserAction } from '~~/server/utils/audit'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const canConfig = await hasUserPermission(event, ['VACATION:CONFIG_PERIODS'])
  if (!canConfig) throw createError({ statusCode: 403, message: 'Sem permissão para gerir períodos restritos' })

  const id = parseInt(getRouterParam(event, 'id') || '')
  if (isNaN(id)) throw createError({ statusCode: 400, message: 'ID inválido' })

  const [row] = await sql<{ title: string }[]>`SELECT title FROM blackout_dates WHERE id = ${id}`
  if (!row) throw createError({ statusCode: 404, message: 'Período restrito não encontrado' })

  await sql`DELETE FROM blackout_dates WHERE id = ${id}`

  await logUserAction(event, currentUser as any, 'DELETE', 'BLACKOUT_DATE', id, row.title)

  return { success: true }
})
