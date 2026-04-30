import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

/**
 * Verifica se um utilizador tem as permissões necessárias
 * @param requiredPermissions Array de códigos de permissão (ex: ['VACATION:APPROVE', 'VACATION:VIEW_TEAM'])
 * @param requireAll Se true, requer TODAS as permissões; se false, requer ALGUMA
 */
export const hasUserPermission = async (
  event: any,
  requiredPermissions: string[],
  requireAll: boolean = false
): Promise<boolean> => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) return false

  // Fetch user's permissions via user_roles (multi-role)
  const userPermissions = await sql`
    SELECT DISTINCT p.code
    FROM user_roles ur
    INNER JOIN roles r ON ur.role_id = r.id
    INNER JOIN role_permissions rp ON r.id = rp.role_id
    INNER JOIN permissions p ON rp.permission_id = p.id
    WHERE ur.user_id = ${currentUser.id}
  `

  const userPermissionCodes = userPermissions.map((p: any) => p.code)

  if (requireAll) {
    return requiredPermissions.every((perm) => userPermissionCodes.includes(perm))
  } else {
    return requiredPermissions.some((perm) => userPermissionCodes.includes(perm))
  }
}

/**
 * Middleware que verifica permissões e lança erro se não autorizado
 */
export const authorize = (requiredPermissions: string[], requireAll: boolean = false) => {
  return defineEventHandler(async (event) => {
    const currentUser = await getUserFromEvent(event)
    if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

    const hasPermission = await hasUserPermission(event, requiredPermissions, requireAll)

    if (!hasPermission) {
      throw createError({
        statusCode: 403,
        message: `Forbidden - Required one of: ${requiredPermissions.join(', ')}`
      })
    }
  })
}

/**
 * Fetch user's permissions
 */
export const getUserPermissions = async (userId: number): Promise<string[]> => {
  const permissions = await sql`
    SELECT DISTINCT p.code
    FROM user_roles ur
    INNER JOIN roles r ON ur.role_id = r.id
    INNER JOIN role_permissions rp ON r.id = rp.role_id
    INNER JOIN permissions p ON rp.permission_id = p.id
    WHERE ur.user_id = ${userId}
  `

  return permissions.map((p: any) => p.code)
}
