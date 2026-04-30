import sql from '~~/server/utils/db'

export async function getUserRoomsPermissions(userId: number): Promise<string[]> {
  const perms = await sql`
    SELECT DISTINCT p.code
    FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    JOIN role_permissions rp ON r.id = rp.role_id
    JOIN permissions p ON rp.permission_id = p.id
    WHERE ur.user_id = ${userId}
    AND p.module = 'ROOMS'
  `
  return perms.map((p: { code: string }) => p.code)
}
