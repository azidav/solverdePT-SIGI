import { useAuth } from './useAuth'

export async function useApiFetch(url: string, options?: Record<string, unknown>) {
  try {
    return await $fetch(url, options)
  } catch (e: unknown) {
    const err = e as { status?: number, statusCode?: number, response?: { status?: number } }
    const statusCode = err?.status ?? err?.statusCode ?? err?.response?.status
    const route = useRoute()
    const authPages = ['/login', '/register', '/forgot-password', '/reset-password']

    if (statusCode === 401 && !authPages.includes(route.path)) {
      const toast = useToast()
      toast.add({
        title: 'Sessão expirada',
        description: 'A tua sessão expirou. Faz login novamente.',
        color: 'error',
        icon: 'i-lucide-log-out'
      })
      useAuth().logout()
    }
    throw e
  }
}
