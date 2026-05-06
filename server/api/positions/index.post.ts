import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { logUserAction } from '~~/server/utils/audit'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  if ((currentUser as any).permission > 0) {
    throw createError({ statusCode: 403, message: 'Apenas administradores podem gerir posições' })
  }

  const body = await readBody(event)
  const { name, description, parent_id } = body

  if (!name?.trim()) {
    throw createError({ statusCode: 400, message: 'O nome da posição é obrigatório' })
  }

  // Prevent circular reference: parent must not be a descendant
  if (parent_id) {
    const [parent] = await sql`SELECT id FROM positions WHERE id = ${parent_id}`
    if (!parent) throw createError({ statusCode: 400, message: 'Posição pai não encontrada' })
  }

  const [newPos] = await sql`
    INSERT INTO positions (name, description, parent_id)
    VALUES (${name.trim()}, ${description || null}, ${parent_id || null})
    RETURNING id, name
  `

  await logUserAction(event, currentUser as any, 'CREATE', 'USER', newPos!.id as number, `Posição: ${newPos!.name}`)

  return { id: newPos!.id }
})
