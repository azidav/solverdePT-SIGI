import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  if ((currentUser as any).permission > 0) {
    throw createError({ statusCode: 403, message: 'Apenas administradores podem ver a configuração do workflow' })
  }

  const rows = await sql`
    SELECT * FROM approval_workflow_config ORDER BY step_order ASC
  `

  return rows
})
