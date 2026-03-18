import { defineStore } from 'pinia'

export type ToastType = 'default' | 'info' | 'success' | 'warning' | 'error'

export interface ToastConfig {
  message: string
  title?: string
  type?: ToastType
  duration?: number // em milissegundos, default 5000
  id?: string
}

interface Toast extends Omit<Required<ToastConfig>, 'title'> {
  id: string
  title?: string
  timestamp: number
}

interface ToastState {
  toasts: Toast[]
}

export const useToastStore = defineStore('toast', {
  state: (): ToastState => ({
    toasts: []
  }),

  getters: {
    activeToasts: (state): Toast[] => state.toasts
  },

  actions: {
    show(config: ToastConfig) {
      const toast: Toast = {
        id: config.id || `toast-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        message: config.message,
        title: config.title,
        type: config.type || 'default',
        duration: config.duration ?? 5000,
        timestamp: Date.now()
      }

      this.toasts.push(toast)

      // Auto remove após duration
      if (toast.duration > 0) {
        setTimeout(() => {
          this.remove(toast.id)
        }, toast.duration)
      }

      return toast.id
    },

    remove(id: string) {
      const index = this.toasts.findIndex(t => t.id === id)
      if (index !== -1) {
        this.toasts.splice(index, 1)
      }
    },

    clear() {
      this.toasts = []
    },

    // Atalhos para tipos específicos
    success(message: string, titleOrDuration?: string | number, duration?: number) {
      const title = typeof titleOrDuration === 'string' ? titleOrDuration : undefined
      const dur = typeof titleOrDuration === 'number' ? titleOrDuration : duration
      return this.show({ message, title, type: 'success', duration: dur })
    },

    error(message: string, titleOrDuration?: string | number, duration?: number) {
      const title = typeof titleOrDuration === 'string' ? titleOrDuration : undefined
      const dur = typeof titleOrDuration === 'number' ? titleOrDuration : duration
      return this.show({ message, title, type: 'error', duration: dur })
    },

    info(message: string, titleOrDuration?: string | number, duration?: number) {
      const title = typeof titleOrDuration === 'string' ? titleOrDuration : undefined
      const dur = typeof titleOrDuration === 'number' ? titleOrDuration : duration
      return this.show({ message, title, type: 'info', duration: dur })
    },

    warning(message: string, titleOrDuration?: string | number, duration?: number) {
      const title = typeof titleOrDuration === 'string' ? titleOrDuration : undefined
      const dur = typeof titleOrDuration === 'number' ? titleOrDuration : duration
      return this.show({ message, title, type: 'warning', duration: dur })
    },

    default(message: string, titleOrDuration?: string | number, duration?: number) {
      const title = typeof titleOrDuration === 'string' ? titleOrDuration : undefined
      const dur = typeof titleOrDuration === 'number' ? titleOrDuration : duration
      return this.show({ message, title, type: 'default', duration: dur })
    }
  }
})
