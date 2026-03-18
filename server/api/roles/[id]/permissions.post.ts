import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'

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
  const { permissionIds } = body

  console.log('[PermissionsAPI] Received request')
  console.log('[PermissionsAPI] Role ID:', roleId)
  console.log('[PermissionsAPI] Body:', body)
  console.log('[PermissionsAPI] Permission IDs:', permissionIds)

  if (!Array.isArray(permissionIds)) {
    throw createError({ statusCode: 400, message: 'permissionIds must be an array' })
  }

  // Check role exists and is not system role
  const roles = await sql`
    SELECT id, is_system FROM roles WHERE id = ${parseInt(roleId)}
  `
  if (roles.length === 0) {
    throw createError({ statusCode: 404, message: 'Role not found' })
  }

  if (roles[0].is_system) {
    throw createError({ statusCode: 403, message: 'Cannot modify system role permissions' })
  }

  // Remove existing permissions
  await sql`
    DELETE FROM role_permissions WHERE role_id = ${parseInt(roleId)}
  `

  // Insert new permissions
  if (permissionIds.length > 0) {
    // Validate permission IDs exist
    const validPermissions = await sql`
      SELECT id FROM permissions WHERE id IN ${sql(permissionIds)}
    `

    console.log('[PermissionsAPI] Valid permissions found:', validPermissions.length, 'of', permissionIds.length)

    if (validPermissions.length !== permissionIds.length) {
      throw createError({
        statusCode: 400,
        message: `Some permission IDs are invalid. Expected ${permissionIds.length}, found ${validPermissions.length}`
      })
    }

    try {
      await sql`
        INSERT INTO role_permissions (role_id, permission_id)
        VALUES ${sql(
          permissionIds.map((pid: number) => [parseInt(roleId), pid])
        )}
      `
      console.log('[PermissionsAPI] Successfully inserted permissions')
    } catch (error) {
      console.error('[PermissionsAPI] Insert error:', error)
      throw createError({
        statusCode: 409,
        message: 'Error assigning permissions to role'
      })
    }
  }

  // Return updated permissions
  const permissions = await sql`
    SELECT p.id, p.code, p.description, p.module, p.action
    FROM role_permissions rp
    INNER JOIN permissions p ON rp.permission_id = p.id
    WHERE rp.role_id = ${parseInt(roleId)}
    ORDER BY p.module, p.action
  `

  return permissions
})
