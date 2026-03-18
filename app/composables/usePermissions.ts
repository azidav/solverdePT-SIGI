import { hasPermission, type Capability, PERMISSIONS } from '~/utils/permissions'

export const usePermissions = () => {
  const { user } = useAuth()

  const userPermission = computed(() => user.value?.permission)

  const can = (capability: Capability): boolean => {
    return hasPermission(userPermission.value, capability)
  }

  const isAdmin = computed(() => userPermission.value === PERMISSIONS.ADMIN)
  const isManager = computed(() => userPermission.value === PERMISSIONS.MANAGER)
  const isEmployee = computed(() => userPermission.value === PERMISSIONS.EMPLOYEE)
  const isRestricted = computed(() => userPermission.value === PERMISSIONS.RESTRICTED)

  // User management
  const canViewAllUsers = computed(() => can('VIEW_ALL_USERS'))
  const canManageUsers = computed(() => can('MANAGE_USERS'))

  // Settings
  const canAccessSettings = computed(() => can('ACCESS_SETTINGS'))
  const canChangeSystemSettings = computed(() => can('CHANGE_SYSTEM_SETTINGS'))

  return {
    can,
    userPermission,
    isAdmin,
    isManager,
    isEmployee,
    isRestricted,
    canViewAllUsers,
    canManageUsers,
    canAccessSettings,
    canChangeSystemSettings,
  }
}
