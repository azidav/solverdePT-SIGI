export default defineNuxtRouteMiddleware(() => {
  const auth = useAuth()
  const logged = useCookie('auth.loggedIn')
  const isAuth = auth.isAuthenticated.value || logged.value === '1'
  setPageLayout(isAuth ? 'default' : 'booking')
})
