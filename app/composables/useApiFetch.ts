import { useAuth } from './useAuth'

export async function useApiFetch(url: string, options?: any) {
  try {
    return await $fetch(url, options)
  } catch (e: any) {
    const statusCode = e?.status ?? e?.statusCode ?? e?.response?.status
    const route = useRoute()
    const authPages = ['/login', '/register', '/forgot-password', '/reset-password']

    if (statusCode === 401 && !authPages.includes(route.path)) {
      const toast = useToast()
      toast.add({
        title: 'Sessão expirada',
        description: 'A sua sessão expirou. Por favor, faça login novamente.',
        color: 'error',
        icon: 'i-lucide-log-out',
      })
      useAuth().logout()
    }
    throw e
  }
}
