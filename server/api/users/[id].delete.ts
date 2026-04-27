import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { logUserAction } from '~~/server/utils/audit'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  if (currentUser.permission > 0) {
    throw createError({ statusCode: 403, message: 'Forbidden - Admin only' })
  }

  const userId = getRouterParam(event, 'id')
  if (!userId) throw createError({ statusCode: 400, message: 'User ID is required' })

  try {
    const [user] = await sql`
      SELECT id, name FROM users WHERE id = ${parseInt(userId)} AND status = -1
    `

    if (!user) {
      throw createError({ statusCode: 404, message: 'User not found or not in deleted state' })
    }

    await sql`DELETE FROM users WHERE id = ${parseInt(userId)}`

    await logUserAction(event, currentUser, 'DELETE', 'USER', parseInt(userId), user.name)

    return { success: true, message: 'User permanently deleted' }
  }
  catch (error: unknown) {
    if (error instanceof Error && 'statusCode' in error) throw error
    const message = error instanceof Error ? error.message : 'Error permanently deleting user'
    throw createError({ statusCode: 500, message })
  }
})
