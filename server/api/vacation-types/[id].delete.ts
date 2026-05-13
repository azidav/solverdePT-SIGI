import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })
  if ((currentUser as any).permission !== 0) throw createError({ statusCode: 403, message: 'Apenas administradores' })

  const id = parseInt(getRouterParam(event, 'id') || '')
  if (isNaN(id)) throw createError({ statusCode: 400, message: 'ID inválido' })

  const [type] = await sql`SELECT code FROM vacation_types WHERE id = ${id}`
  if (!type) throw createError({ statusCode: 404, message: 'Tipo não encontrado' })
  if (type.code === 'annual') throw createError({ statusCode: 422, message: 'O tipo "Férias Anuais" não pode ser eliminado' })

  await sql`DELETE FROM vacation_types WHERE id = ${id}`
  return { success: true }
})
