export default defineNuxtRouteMiddleware((to) => {
  const auth = useAuth()
  const logged = useCookie('auth.loggedIn')
  const isAuth = auth.isAuthenticated.value || logged?.value === '1'

  // Auth pages: redirect logged-in users away (they don't need login/forgot-password)
  const authPages = ['/login', '/forgot-password', '/reset-password']
  // Guest-accessible pages: open to everyone, but auth users can also visit
  const guestPages = ['/meeting-rooms']
  const publicRoutes = [...authPages, ...guestPages]
  const forcedChangeRoute = '/change-password'

  // Not authenticated → send to login (except public routes)
  if (!isAuth && !publicRoutes.includes(to.path)) {
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
