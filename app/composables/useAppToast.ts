import type { ComputedRef } from 'vue'

export type AppToastType = 'default' | 'info' | 'success' | 'warning' | 'error'

export interface AppToastOptions {
  message: string
  title?: string
  type?: AppToastType
  duration?: number // ms (default 5000). Use 0 or negative for persistent until manual close.
}

/**
 * Wrapper sobre `useToast()` do Nuxt UI para manter API uniforme
 * e suportar título, tipo e duração.
 *
 * Mantém compatibilidade com antiga assinatura dos atalhos:
 * toast.success(message)
 * toast.success(message, duration)
 * toast.success(message, title)
 * toast.success(message, title, duration)
 */
export function useAppToast() {
  const uiToast = useToast();

  function colorFor(type?: AppToastType) {
    switch (type) {
      case 'success': return 'success'
      case 'error': return 'error'
      case 'warning': return 'warning'
      case 'info': return 'primary'
      case 'default':
      default: return 'neutral'
    }
  }

  function show(opts: AppToastOptions) {
    const { message, title, type = 'default', duration } = opts
    // Nuxt UI uses `timeout` for auto hide (ms). Undefined falls back to module default.
    return uiToast.add({
      title: title,
      description: message,
      color: colorFor(type),
      timeout: duration === undefined ? 5000 : duration <= 0 ? undefined : duration
    })
  }

  // Helper to parse flexible parameters
  function parseParams(message: string, p1?: string | number, p2?: number) {
    let title: string | undefined
    let duration: number | undefined
    if (typeof p1 === 'string') {
      title = p1
      duration = p2
    } else if (typeof p1 === 'number') {
      duration = p1
    }
    return { title, duration }
  }

  return {
    // estado bruto (reactive list de toasts do Nuxt UI)
    toasts: uiToast.toasts as ComputedRef<unknown[]>,
    show,
    add: uiToast.add,
    remove: uiToast.remove,
    clear: uiToast.clear,
    success(message: string, p1?: string | number, p2?: number) {
      const { title, duration } = parseParams(message, p1, p2)
      return show({ message, title, type: 'success', duration })
    },
    error(message: string, p1?: string | number, p2?: number) {
      const { title, duration } = parseParams(message, p1, p2)
      return show({ message, title, type: 'error', duration })
    },
    warning(message: string, p1?: string | number, p2?: number) {
      const { title, duration } = parseParams(message, p1, p2)
      return show({ message, title, type: 'warning', duration })
    },
    info(message: string, p1?: string | number, p2?: number) {
      const { title, duration } = parseParams(message, p1, p2)
      return show({ message, title, type: 'info', duration })
    },
    default(message: string, p1?: string | number, p2?: number) {
      const { title, duration } = parseParams(message, p1, p2)
      return show({ message, title, type: 'default', duration })
    }
  }
}
