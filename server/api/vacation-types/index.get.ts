import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const onlyActive = getQuery(event).active !== 'false'

  const types = await sql`
    SELECT id, name, code, uses_balance, requires_approval_chain, is_active, sort_order
    FROM vacation_types
    ${onlyActive ? sql`WHERE is_active = true` : sql``}
    ORDER BY sort_order ASC, id ASC
  `
  return types
})
