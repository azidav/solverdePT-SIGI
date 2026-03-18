import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // Only admin can delete users
  if (currentUser.permission > 0) {
    throw createError({ statusCode: 403, message: 'Forbidden - Admin only' })
  }

  const body = await readBody(event)
  const userIds = Array.isArray(body?.ids) ? body.ids : body?.id ? [body.id] : []

  if (userIds.length === 0) {
    throw createError({ statusCode: 400, message: 'User ID(s) required' })
  }

  try {
    // Soft delete - set status to -1 instead of hard delete
    const result = await sql`
      UPDATE users
      SET status = -1, updated_at = ${new Date()}
      WHERE id IN ${sql(userIds.map((id: string | number) => parseInt(String(id))))}
      RETURNING id
    `

    return {
      success: true,
      message: `${result.length} user(s) deleted successfully`,
      deletedCount: result.length
    }
  } catch (error: unknown) {
    if (error instanceof Error && 'statusCode' in error) throw error
    const message = error instanceof Error ? error.message : 'Error deleting user(s)'
    throw createError({ statusCode: 500, message })
  }
})
