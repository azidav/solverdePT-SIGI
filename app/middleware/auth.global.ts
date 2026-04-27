export default defineNuxtRouteMiddleware((to) => {
  const auth = useAuth()
  const logged = useCookie('auth.loggedIn')
  const isAuth = auth.isAuthenticated.value || logged?.value === '1'

  const publicRoutes = ['/login', '/forgot-password', '/reset-password']
  const forcedChangeRoute = '/change-password'

  // Not authenticated → send to login (except public routes)
  if (!isAuth && !publicRoutes.includes(to.path)) {
    return navigateTo({ path: '/login', query: { redirect: to.fullPath } })
  }

  // Authenticated on a public route → send home
  if (isAuth && publicRoutes.includes(to.path)) {
    return navigateTo('/')
  }

  // Must change password → force to /change-password
  if (isAuth && auth.user.value?.must_change_password && to.path !== forcedChangeRoute) {
    return navigateTo(forcedChangeRoute)
  }

  // Password already changed → don't allow back to forced page
  if (isAuth && !auth.user.value?.must_change_password && to.path === forcedChangeRoute) {
    return navigateTo('/')
  }
})
