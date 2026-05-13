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

  const [pos] = await sql<{ name: string }[]>`SELECT name FROM positions WHERE id = ${id}`
  if (!pos) throw createError({ statusCode: 404, message: 'Posição não encontrada' })

  const [childCount] = await sql`SELECT COUNT(*) AS c FROM positions WHERE parent_id = ${id}`
  if (parseInt(childCount!.c as string) > 0) {
    throw createError({
      statusCode: 409,
      message: 'Não é possível eliminar uma posição que tem subposições. Mova ou elimine as subposições primeiro.'
    })
  }

  const [userCount] = await sql`SELECT COUNT(*) AS c FROM users WHERE position_id = ${id}`
  if (parseInt(userCount!.c as string) > 0) {
    throw createError({
      statusCode: 409,
      message: 'Não é possível eliminar uma posição atribuída a utilizadores. Reatribua os utilizadores primeiro.'
    })
  }

  await sql`DELETE FROM positions WHERE id = ${id}`

  await logUserAction(event, currentUser as any, 'DELETE', 'USER', id, `Posição: ${pos.name}`)

  return { success: true }
})
