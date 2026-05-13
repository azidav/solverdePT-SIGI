import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })
  if ((currentUser as any).permission !== 0) throw createError({ statusCode: 403, message: 'Apenas administradores' })

  const id = parseInt(getRouterParam(event, 'id') || '')
  if (isNaN(id)) throw createError({ statusCode: 400, message: 'ID inválido' })

  const { name, uses_balance, requires_approval_chain, is_active } = await readBody(event)

  const [row] = await sql`
    UPDATE vacation_types SET
      name                   = COALESCE(${name ?? null}, name),
      uses_balance           = COALESCE(${uses_balance ?? null}, uses_balance),
      requires_approval_chain = COALESCE(${requires_approval_chain ?? null}, requires_approval_chain),
      is_active              = COALESCE(${is_active ?? null}, is_active),
      updated_at             = NOW()
    WHERE id = ${id}
    RETURNING *
  `
  if (!row) throw createError({ statusCode: 404, message: 'Tipo não encontrado' })
  return row
})
