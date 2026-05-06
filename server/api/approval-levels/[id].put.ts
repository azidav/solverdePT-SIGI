import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })
  if ((currentUser as any).permission > 0) throw createError({ statusCode: 403, message: 'Apenas administradores' })

  const id = parseInt(getRouterParam(event, 'id') || '0')
  const { name, description } = await readBody(event)
  if (!name?.trim()) throw createError({ statusCode: 400, message: 'Nome obrigatório' })

  const [level] = await sql`
    UPDATE approval_levels
    SET name = ${name.trim()}, description = ${description || null}, updated_at = NOW()
    WHERE id = ${id}
    RETURNING *
  `
  if (!level) throw createError({ statusCode: 404, message: 'Nível não encontrado' })
  return level
})
