// Permission levels
export const PERMISSIONS = {
  ADMIN: 0,        // Administrador - acesso total
  MANAGER: 1,      // Gestor - pode gerir módulos de outros
  EMPLOYEE: 2,     // Colaborador - pode criar pedidos e reservas
  RESTRICTED: 3    // Acesso restrito - apenas visualização
} as const

// Permission capabilities
export const CAPABILITIES = {
  // User management
  VIEW_ALL_USERS: [PERMISSIONS.ADMIN, PERMISSIONS.MANAGER],
  MANAGE_USERS: [PERMISSIONS.ADMIN],

  // Settings
  ACCESS_SETTINGS: [PERMISSIONS.ADMIN],
  CHANGE_SYSTEM_SETTINGS: [PERMISSIONS.ADMIN],
} as const

export type PermissionLevel = typeof PERMISSIONS[keyof typeof PERMISSIONS]
export type Capability = keyof typeof CAPABILITIES

export function getPermissionLabel(permission: number): string {
  switch (permission) {
    case PERMISSIONS.ADMIN:
      return 'Administrador'
    case PERMISSIONS.MANAGER:
      return 'Gestor'
    case PERMISSIONS.EMPLOYEE:
      return 'Colaborador'
    case PERMISSIONS.RESTRICTED:
      return 'Restrito'
    default:
      return 'Desconhecido'
  }
}

export function hasPermission(userPermission: number | undefined, capability: Capability): boolean {
  if (userPermission === undefined) return false
  const allowedPermissions = CAPABILITIES[capability]
  return allowedPermissions.includes(userPermission as PermissionLevel)
}

export function hasMinimumPermission(userPermission: number | undefined, minPermission: PermissionLevel): boolean {
  if (userPermission === undefined) return false
  return userPermission <= minPermission
}
