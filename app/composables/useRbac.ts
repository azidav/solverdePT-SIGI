/**
 * Composable para RBAC dinâmico (Roles e Permissões)
 * Substitui o sistema static de permission levels
 */
export const useRbac = () => {
  const permissionCodes = ref<string[]>([])
  const userRole = ref<any>(null)
  const loading = ref(false)

  const loadPermissions = async () => {
    loading.value = true
    try {
      const response = await useApiFetch('/api/users/me/permissions')
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

  /**
   * Verifica se o utilizador tem uma permissão específica
   * @param permissionCode Código de permissão (ex: 'VACATION:APPROVE')
   */
  const can = (permissionCode: string): boolean => {
    return permissionCodes.value.includes(permissionCode)
  }

  /**
   * Verifica se o utilizador tem ALGUMA das permissões
   * @param codes Array de códigos (ex: ['VACATION:APPROVE', 'VACATION:VIEW_TEAM'])
   */
  const canAny = (codes: string[]): boolean => {
    return codes.some((code) => permissionCodes.value.includes(code))
  }

  /**
   * Verifica se o utilizador tem TODAS as permissões
   * @param codes Array de códigos
   */
  const canAll = (codes: string[]): boolean => {
    return codes.every((code) => permissionCodes.value.includes(code))
  }

  /**
   * Verifica se o utilizador tem acesso a um módulo inteiro
   * @param module Nome do módulo (ex: 'VACATION', 'EQUIPMENT')
   */
  const canAccessModule = (module: string): boolean => {
    return permissionCodes.value.some((code) => code.startsWith(`${module}:`))
  }

  /**
   * Retorna todas as permissões para um módulo
   * @param module Nome do módulo
   */
  const getModulePermissions = (module: string): string[] => {
    return permissionCodes.value.filter((code) => code.startsWith(`${module}:`))
  }

  // Helpers para módulos comuns
  const canVacation = computed(() => canAccessModule('VACATION'))
  const canEquipment = computed(() => canAccessModule('EQUIPMENT'))
  const canRooms = computed(() => canAccessModule('ROOMS'))
  const canSettings = computed(() => canAccessModule('SETTINGS'))

  // Helpers para ações comuns
  const canApproveVacation = computed(() => can('VACATION:APPROVE'))
  const canManageRoles = computed(() => can('SETTINGS:MANAGE_ROLES'))
  const canManageUsers = computed(() => can('SETTINGS:MANAGE_USERS'))

  return {
    // State
    permissionCodes,
    userRole,
    loading,

    // Methods
    can,
    canAny,
    canAll,
    canAccessModule,
    getModulePermissions,
    loadPermissions,

    // Computed helpers
    canVacation,
    canEquipment,
    canRooms,
    canSettings,
    canApproveVacation,
    canManageRoles,
    canManageUsers
  }
}
