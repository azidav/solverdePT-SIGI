import { computed } from 'vue'
import { useApiFetch } from './useApiFetch'

interface User {
  id: number
  username: string
  name: string
  email: string
  department: string
  permission: number
  status: number
  must_change_password?: boolean
}

export const useAuth = () => {
  // Persisted/shared state across the app using Nuxt's useState
  // Also store a cookie so auth survives full page reloads
  const userCookie = useCookie<User | null>('auth.user', { maxAge: 3600 })
  const user = useState<User | null>('auth.user', () => {
    try {
      return (userCookie.value as unknown) as User | null
    } catch (e) {
      return null
    }
  })
  const error = useState<string | null>('auth.error', () => null)

  // Derived state
  const isAuthenticated = computed(() => !!user.value)

  const login = async (username: string, password: string) => {
    try {
      error.value = null
      const response = await useApiFetch('/api/auth/login', {
        method: 'POST',
        body: { username, password },
      }) as { user?: User }

      if (response && response.user) {
        const u = response.user
        user.value = u
        userCookie.value = u // cookie will expire in 1 hour
        const logged = useCookie('auth.loggedIn')
        logged.value = '1'
        navigateTo('/')
      }
      return response
    } catch (e: any) {
      error.value = e.data?.message || 'Ocorreu um erro durante o login'
      user.value = null
      return null
    }
  }

  const loginWithUser = (u: User) => {
    user.value = u
    userCookie.value = u
    useCookie('auth.loggedIn').value = '1'
  }

  const logout = () => {
    user.value = null
    error.value = null
    // clear persisted cookie
    userCookie.value = null // clear cookie on logout
    const logged = useCookie('auth.loggedIn')
    logged.value = null
    navigateTo('/login')
  }

  return {
    user,
    isAuthenticated,
    error,
    login,
    loginWithUser,
    logout,
  }
}

// Provide default export for components that import the composable as default
export default useAuth
