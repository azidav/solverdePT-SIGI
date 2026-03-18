export default defineNuxtRouteMiddleware((to) => {
  const auth = useAuth()
  const publicRoutes = ['/login']
  // Also accept a small persistent cookie as an auth hint (useful during navigation)
  const logged = useCookie('auth.loggedIn')
  const isAuth = auth.isAuthenticated.value || logged?.value === '1'

  if (!isAuth && !publicRoutes.includes(to.path)) {
    // Add the original destination as a query parameter
    return navigateTo({
      path: '/login',
      query: { redirect: to.fullPath }
    })
  }

  // Prevent authenticated users from accessing login/register pages
  if (isAuth && publicRoutes.includes(to.path)) {
    return navigateTo('/')
  }
})
