import { defineStore } from 'pinia'
import type { Component } from 'vue'

export type PopupType = 'common' | 'confirmation' | 'delete'

export interface PopupButton {
  label: string
  color?: 'primary' | 'error' | 'success' | 'warning' | 'neutral'
  variant?: 'solid' | 'outline' | 'soft' | 'subtle' | 'ghost'
  icon?: string
  onClick?: () => void | Promise<void>
}

export interface PopupConfig {
  type: PopupType
  title?: string
  icon?: string
  content?: string
  // Renderizar conteúdo customizado
  pageId?: string // ID/caminho da página (ex: 'roles/new', 'users/123/edit')
  pageComponent?: Component // Componente Vue
  pagePath?: string // Path para lazy load (ex: '~/pages/users/roles/new.vue')
  pageProps?: Record<string, unknown> // Props para componente ou página
  // Botões e callbacks
  acceptButton?: PopupButton
  declineButton?: PopupButton
  onClose?: () => void | Promise<void>
  onAccept?: () => void | Promise<void>
  onDecline?: () => void | Promise<void>
}

interface PopupState {
  isOpen: boolean
  config: PopupConfig | null
}

export const usePopupStore = defineStore('popup', {
  state: (): PopupState => ({
    isOpen: false,
    config: null
  }),

  getters: {
    currentConfig: (state): PopupConfig | null => state.config,
    isPopupOpen: (state): boolean => state.isOpen
  },

  actions: {
    open(config: PopupConfig) {
      this.config = config
      this.isOpen = true
    },

    async close() {
      if (this.config?.onClose) {
        await this.config.onClose()
      }
      this.isOpen = false
      this.config = null
    },

    async accept() {
      if (this.config?.onAccept) {
        await this.config.onAccept()
      }
      if (this.config?.acceptButton?.onClick) {
        await this.config.acceptButton.onClick()
      }
      await this.close()
    },

    async decline() {
      if (this.config?.onDecline) {
        await this.config.onDecline()
      }
      if (this.config?.declineButton?.onClick) {
        await this.config.declineButton.onClick()
      }
      await this.close()
    }
  }
})
