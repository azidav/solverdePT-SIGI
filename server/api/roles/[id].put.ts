import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'
import { logUserAction } from '~~/server/utils/audit'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // Requires SETTINGS:MANAGE_ROLES
  const hasPermission = await hasUserPermission(event, ['SETTINGS:MANAGE_ROLES'])
  if (!hasPermission) {
    throw createError({ statusCode: 403, message: 'Forbidden - Requires SETTINGS:MANAGE_ROLES' })
  }

  const roleId = getRouterParam(event, 'id')
  if (!roleId) throw createError({ statusCode: 400, message: 'Role ID is required' })

  const body = await readBody(event)
  const { name, description } = body

  // Check if role exists and is not system role
  const roles = await sql`
    SELECT id, is_system, name, description
    FROM roles
    WHERE id = ${parseInt(roleId)}
  `

  if (roles.length === 0) {
    throw createError({ statusCode: 404, message: 'Role not found' })
  }

  if (roles[0].is_system) {
    throw createError({ statusCode: 403, message: 'Cannot modify system roles' })
  }

  const updateData: Record<string, any> = {}
  if (name !== undefined) updateData.name = name
  if (description !== undefined) updateData.description = description
  updateData.updated_at = new Date()

  try {
    const result = await sql`
      UPDATE roles
      SET ${sql(updateData)}
      WHERE id = ${parseInt(roleId)}
      RETURNING id, name, description, is_system, created_at
    `

    // Audit log
    await logUserAction(
      event,
      currentUser,
      'UPDATE',
      'ROLE',
      parseInt(roleId),
      result[0].name
    )

    return result[0]
  } catch (error: any) {
    if (error.message?.includes('duplicate key')) {
      throw createError({ statusCode: 409, message: 'Role name already exists' })
    }
    throw error
  }
})
