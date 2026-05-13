import { getUserFromEvent } from '~~/server/utils/auth'
import { skipWorkflowStep } from '~~/server/utils/vacation'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  if ((currentUser as any).permission > 0) {
    throw createError({ statusCode: 403, message: 'Apenas administradores podem escalar níveis de aprovação' })
  }

  const id = parseInt(getRouterParam(event, 'id') || '')
  if (isNaN(id)) throw createError({ statusCode: 400, message: 'ID inválido' })

  const body = await readBody(event)
  await skipWorkflowStep(id, currentUser as any, body?.comment)

  return { success: true }
})
