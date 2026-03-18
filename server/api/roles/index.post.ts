import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'
import { logUserAction } from '~~/server/utils/audit'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // Create role - requires SETTINGS:MANAGE_ROLES
  const hasPermission = await hasUserPermission(event, ['SETTINGS:MANAGE_ROLES'])
  if (!hasPermission) {
    throw createError({ statusCode: 403, message: 'Forbidden - Requires SETTINGS:MANAGE_ROLES' })
  }

  const body = await readBody(event)
  const { name, description } = body

  if (!name || name.trim().length === 0) {
    throw createError({ statusCode: 400, message: 'Role name is required' })
  }

  try {
    const result = await sql`
      INSERT INTO roles (name, description, is_system)
      VALUES (${name}, ${description || null}, FALSE)
      RETURNING id, name, description, is_system, created_at
    `

    // Audit log
    await logUserAction(
      event,
      currentUser,
      'CREATE',
      'ROLE',
      result[0].id,
      name
    )

    return result[0]
  } catch (error: any) {
    if (error.message?.includes('duplicate key')) {
      throw createError({ statusCode: 409, message: 'Role already exists' })
    }
    throw error
  }
})
