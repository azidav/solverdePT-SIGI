export default defineNuxtRouteMiddleware((to) => {
  const auth = useAuth()
  const logged = useCookie('auth.loggedIn')
  const isAuth = auth.isAuthenticated.value || logged?.value === '1'

  // Auth pages: redirect logged-in users away (they don't need login/forgot-password)
  const authPages = ['/login', '/forgot-password', '/reset-password']
  const publicRoutes = [...authPages]
  const forcedChangeRoute = '/change-password'

  // Public room display panels (tablet at each room's entrance) — dynamic segment, so prefix match
  const isPublicDisplay = to.path === '/painel-salas' || to.path.startsWith('/painel-salas/')

  // Not authenticated → send to login (except public routes)
  if (!isAuth && !publicRoutes.includes(to.path) && !isPublicDisplay) {
    return navigateTo({ path: '/login', query: { redirect: to.fullPath } })
  }

  // Authenticated on an auth-only page (login, etc.) → send home
  if (isAuth && authPages.includes(to.path)) {
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
