import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { logUserAction } from '~~/server/utils/audit'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  if ((currentUser as any).permission > 0) {
    throw createError({ statusCode: 403, message: 'Apenas administradores podem gerir posições' })
  }

  const id = parseInt(getRouterParam(event, 'id') || '')
  if (isNaN(id)) throw createError({ statusCode: 400, message: 'ID inválido' })

  const body = await readBody(event)
  const { name, description, parent_id } = body

  if (!name?.trim()) {
    throw createError({ statusCode: 400, message: 'O nome da posição é obrigatório' })
  }

  // Prevent self-reference or circular parenting via descendant check
  if (parent_id === id) {
    throw createError({ statusCode: 400, message: 'Uma posição não pode ser o seu próprio pai' })
  }

  if (parent_id) {
    // Walk up from parent_id to ensure it doesn't eventually lead back to id
    const ancestors = await sql`
      WITH RECURSIVE ancestors AS (
        SELECT id, parent_id FROM positions WHERE id = ${parent_id}
        UNION ALL
        SELECT p.id, p.parent_id FROM positions p INNER JOIN ancestors a ON p.id = a.parent_id
      )
      SELECT id FROM ancestors
    `
    if (ancestors.some((a: any) => a.id === id)) {
      throw createError({ statusCode: 400, message: 'Referência circular: o pai selecionado é um descendente desta posição' })
    }
  }

  const [updated] = await sql`
    UPDATE positions
    SET name = ${name.trim()}, description = ${description || null}, parent_id = ${parent_id || null}, updated_at = NOW()
    WHERE id = ${id}
    RETURNING id, name
  `

  if (!updated) throw createError({ statusCode: 404, message: 'Posição não encontrada' })

  await logUserAction(event, currentUser as any, 'UPDATE', 'USER', id, `Posição: ${updated.name}`)

  return updated
})
