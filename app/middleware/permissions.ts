export default defineNuxtRouteMiddleware((to) => {
  const { user } = useAuth()
  const { can } = usePermissions()

  // Check if user is authenticated
  if (!user.value) {
    return navigateTo('/login')
  }

  // Route-specific permission checks
  const routePermissions: Record<string, () => boolean> = {
    '/users/accounts': () => can('VIEW_ALL_USERS'),
    '/settings': () => can('ACCESS_SETTINGS'),
    '/settings/members': () => can('VIEW_ALL_USERS'),
  }

  // Check if route requires specific permission
  const checkPermission = routePermissions[to.path]
  if (checkPermission && !checkPermission()) {
    return navigateTo('/')
  }
})
