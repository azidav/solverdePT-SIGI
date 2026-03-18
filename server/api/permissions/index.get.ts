import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const permissions = await sql`
    SELECT id, code, description, module, action
    FROM permissions
    ORDER BY module ASC, action ASC
  `

  // Group by module for easier UI consumption
  const grouped = permissions.reduce(
    (acc: Record<string, any[]>, perm: any) => {
      if (!acc[perm.module]) {
        acc[perm.module] = []
      }
      acc[perm.module].push(perm)
      return acc
    },
    {}
  )

  return {
    flat: permissions,
    grouped
  }
})
