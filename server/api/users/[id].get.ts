import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const userId = getRouterParam(event, 'id')
  if (!userId) throw createError({ statusCode: 400, message: 'User ID is required' })

  try {
    const users = await sql`
      SELECT id, username, name, email, department, permission, status, created_at, updated_at
      FROM users
      WHERE id = ${parseInt(userId)}
    `

    if (users.length === 0) {
      throw createError({ statusCode: 404, message: 'User not found' })
    }

    return users[0]
  } catch (error: unknown) {
    if (error instanceof Error && 'statusCode' in error) throw error
    const message = error instanceof Error ? error.message : 'Error fetching user'
    throw createError({ statusCode: 500, message })
  }
})
