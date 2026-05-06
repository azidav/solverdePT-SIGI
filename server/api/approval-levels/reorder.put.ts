import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })
  if ((currentUser as any).permission > 0) throw createError({ statusCode: 403, message: 'Apenas administradores' })

  // items: Array<{ id: number, parent_id: number | null, step_order: number }>
  const { items } = await readBody(event)
  if (!Array.isArray(items)) throw createError({ statusCode: 400, message: 'items obrigatório' })

  for (const item of items) {
    await sql`
      UPDATE approval_levels
      SET parent_id   = ${item.parent_id ?? null},
          step_order  = ${item.step_order},
          updated_at  = NOW()
      WHERE id = ${item.id}
    `
  }

  return { success: true }
})
