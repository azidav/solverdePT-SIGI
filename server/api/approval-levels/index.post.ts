import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })
  if ((currentUser as any).permission > 0) throw createError({ statusCode: 403, message: 'Apenas administradores' })

  const { name, description } = await readBody(event)
  if (!name?.trim()) throw createError({ statusCode: 400, message: 'Nome obrigatório' })

  // Place at end of chain
  const [last] = await sql`SELECT COALESCE(MAX(step_order), 0) AS max FROM approval_levels`
  const stepOrder = (last?.max as number ?? 0) + 1

  const [level] = await sql`
    INSERT INTO approval_levels (name, description, step_order)
    VALUES (${name.trim()}, ${description || null}, ${stepOrder})
    RETURNING *
  `

  return { ...level, members: [] }
})
