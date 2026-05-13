import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'
import { logUserAction } from '~~/server/utils/audit'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const canConfig = await hasUserPermission(event, ['VACATION:CONFIG_PERIODS'])
  if (!canConfig) throw createError({ statusCode: 403, message: 'Sem permissão para gerir períodos restritos' })

  const body = await readBody(event)
  const { title, start_date, end_date, reason, department } = body

  if (!title || !start_date || !end_date) {
    throw createError({ statusCode: 400, message: 'Título, data de início e data de fim são obrigatórios' })
  }

  if (new Date(start_date) > new Date(end_date)) {
    throw createError({ statusCode: 400, message: 'A data de início não pode ser posterior à data de fim' })
  }

  const [newRow] = await sql`
    INSERT INTO blackout_dates (title, start_date, end_date, reason, department, created_by)
    VALUES (${title}, ${start_date}, ${end_date}, ${reason || null}, ${department || null}, ${currentUser.id})
    RETURNING id
  `

  await logUserAction(event, currentUser as any, 'CREATE', 'BLACKOUT_DATE', newRow!.id as number, title)

  return { id: newRow!.id }
})
