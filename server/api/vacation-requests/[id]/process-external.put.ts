import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const [isRhMember] = await sql`
    SELECT 1 FROM approval_level_members alm
    INNER JOIN approval_levels al ON al.id = alm.level_id
    WHERE alm.user_id = ${currentUser.id} AND al.is_rh = true
    LIMIT 1
  `
  if (!isRhMember) throw createError({ statusCode: 403, message: 'Apenas o grupo RH pode registar o processamento externo' })

  const id = parseInt(getRouterParam(event, 'id') || '0')
  if (!id) throw createError({ statusCode: 400, message: 'ID inválido' })

  const { processed } = await readBody(event)

  const [updated] = await sql`
    UPDATE vacation_requests
    SET processed_externally = ${!!processed}, updated_at = NOW()
    WHERE id = ${id} AND status = 'approved'
    RETURNING id, processed_externally
  `
  if (!updated) throw createError({ statusCode: 404, message: 'Pedido não encontrado ou ainda não aprovado' })
  return updated
})
