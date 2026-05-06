export const useRbac = () => {
  const permissionCodes = ref<string[]>([])
  const userRole = ref<{ id: number, name: string } | null>(null)
  const loading = ref(true)

  const loadPermissions = async () => {
    loading.value = true
    try {
      const response = await useApiFetch('/api/users/me/permissions') as { permissionCodes: string[], user?: { role?: { id: number, name: string } } }
      permissionCodes.value = response.permissionCodes || []
      userRole.value = response.user?.role || null
    } catch (error) {
      console.error('Failed to load permissions:', error)
      permissionCodes.value = []
    } finally {
      loading.value = false
    }
  }

  onMounted(() => {
    loadPermissions()
  })

  const can = (permissionCode: string): boolean =>
    permissionCodes.value.includes(permissionCode)

  const canAny = (codes: string[]): boolean =>
    codes.some(code => permissionCodes.value.includes(code))

  const canAll = (codes: string[]): boolean =>
    codes.every(code => permissionCodes.value.includes(code))

  const canAccessModule = (module: string): boolean =>
    permissionCodes.value.some(code => code.startsWith(`${module}:`))

  const getModulePermissions = (module: string): string[] =>
    permissionCodes.value.filter(code => code.startsWith(`${module}:`))

  const canVacation = computed(() => canAccessModule('VACATION'))
  const canEquipment = computed(() => canAccessModule('EQUIPMENT'))
  const canRooms = computed(() => canAccessModule('ROOMS'))
  const canSettings = computed(() => canAccessModule('SETTINGS'))

  const canApproveVacation = computed(() => can('VACATION:APPROVE'))
  const canManageRoles = computed(() => can('SETTINGS:MANAGE_ROLES'))
  const canManageUsers = computed(() => can('SETTINGS:MANAGE_USERS'))

  return {
    permissionCodes,
    userRole,
    loading,
    can,
    canAny,
    canAll,
    canAccessModule,
    getModulePermissions,
    loadPermissions,
    canVacation,
    canEquipment,
    canRooms,
    canSettings,
    canApproveVacation,
    canManageRoles,
    canManageUsers
  }
}
