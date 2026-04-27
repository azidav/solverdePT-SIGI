import { useAuth } from './useAuth'

export async function useApiFetch(url: string, options?: any) {
  try {
    return await $fetch(url, options)
  } catch (e: any) {
    const route = useRoute()

    if (
      e?.status === 401 &&
      route.path !== "/login" &&
      route.path !== "/register" &&
      route.path !== "/forgot-password"
    ) {
      // Show toast for session expired
      const toast = useToast();
      toast.add({
        title: "Session expired",
        description: "Your session has expired. Please log in again.",
        color: "error",
        icon: "i-lucide-log-out",
      });
      useAuth().logout();
    }
    throw e
  }
}
