import type { ToastConfig } from '~/stores/toast'

/**
 * Composable para usar o sistema de toaster universal
 *
 * @example
 * const toaster = useToaster()
 * toaster.success('Operação realizada!')
 * toaster.error('Algo deu errado', 10000)
 * toaster.show({ message: 'Aviso', type: 'warning', duration: 3000 })
 */
export function useToaster() {
  const toastStore = useToastStore()

  return {
    /**
     * Exibe um toast com configuração customizada
     * @param config - Configuração do toast
     * @returns ID do toast criado
     */
    show: (config: ToastConfig) => toastStore.show(config),

    /**
     * Exibe toast de sucesso (verde)
     * @param message - Mensagem a exibir
     * @param titleOrDuration - Título (string) ou duração (number)
     * @param duration - Duração em ms (default: 5000) - usado quando titleOrDuration é string
     */
    success: (message: string, titleOrDuration?: string | number, duration?: number) => toastStore.success(message, titleOrDuration, duration),

    /**
     * Exibe toast de erro (vermelho)
     * @param message - Mensagem a exibir
     * @param titleOrDuration - Título (string) ou duração (number)
     * @param duration - Duração em ms (default: 5000) - usado quando titleOrDuration é string
     */
    error: (message: string, titleOrDuration?: string | number, duration?: number) => toastStore.error(message, titleOrDuration, duration),

    /**
     * Exibe toast informativo (azul)
     * @param message - Mensagem a exibir
     * @param titleOrDuration - Título (string) ou duração (number)
     * @param duration - Duração em ms (default: 5000) - usado quando titleOrDuration é string
     */
    info: (message: string, titleOrDuration?: string | number, duration?: number) => toastStore.info(message, titleOrDuration, duration),

    /**
     * Exibe toast de aviso (amarelo)
     * @param message - Mensagem a exibir
     * @param titleOrDuration - Título (string) ou duração (number)
     * @param duration - Duração em ms (default: 5000) - usado quando titleOrDuration é string
     */
    warning: (message: string, titleOrDuration?: string | number, duration?: number) => toastStore.warning(message, titleOrDuration, duration),

    /**
     * Exibe toast padrão (cinza)
     * @param message - Mensagem a exibir
     * @param titleOrDuration - Título (string) ou duração (number)
     * @param duration - Duração em ms (default: 5000) - usado quando titleOrDuration é string
     */
    default: (message: string, titleOrDuration?: string | number, duration?: number) => toastStore.default(message, titleOrDuration, duration),

    /**
     * Remove um toast específico
     * @param id - ID do toast a remover
     */
    remove: (id: string) => toastStore.remove(id),

    /**
     * Remove todos os toasts ativos
     */
    clear: () => toastStore.clear(),

    /**
     * Lista de toasts ativos
     */
    toasts: computed(() => toastStore.activeToasts)
  }
}
