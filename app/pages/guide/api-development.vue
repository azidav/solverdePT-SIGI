<template>
  <div class="min-h-screen bg-gray-50">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <!-- Navigation -->
      <div class="mb-8">
        <NuxtLink
          to="/guide"
          class="inline-flex items-center text-blue-600 hover:text-blue-800 font-medium mb-4"
        >
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
          </svg>
          Back to Guides
        </NuxtLink>
      </div>

      <div class="flex gap-8">
        <!-- Sidebar Navigation -->
        <aside class="hidden lg:block w-64 flex-shrink-0">
          <div class="sticky top-8 bg-white rounded-lg shadow p-6">
            <h3 class="font-semibold text-gray-900 mb-4">On This Page</h3>
            <nav class="space-y-1">
              <!-- Toaster Section -->
              <div class="mb-4">
                <a href="#toaster" class="block text-sm font-medium text-blue-600 hover:text-blue-800 mb-2">
                  🍞 Toaster System
                </a>
                <div class="ml-3 space-y-1 border-l-2 border-gray-200 pl-3">
                  <a href="#toaster-basic" class="block text-sm text-gray-600 hover:text-gray-900">Basic Usage</a>
                  <a href="#toaster-types" class="block text-sm text-gray-600 hover:text-gray-900">Toast Types</a>
                  <a href="#toaster-crud" class="block text-sm text-gray-600 hover:text-gray-900">CRUD Operations</a>
                  <a href="#toaster-validation" class="block text-sm text-gray-600 hover:text-gray-900">Form Validation</a>
                  <a href="#toaster-loading" class="block text-sm text-gray-600 hover:text-gray-900">Loading States</a>
                  <a href="#toaster-upload" class="block text-sm text-gray-600 hover:text-gray-900">File Upload</a>
                  <a href="#toaster-duration" class="block text-sm text-gray-600 hover:text-gray-900">Custom Duration</a>
                  <a href="#toaster-control" class="block text-sm text-gray-600 hover:text-gray-900">Manual Control</a>
                </div>
              </div>

              <!-- Popup Section -->
              <div class="mb-4">
                <a href="#popup" class="block text-sm font-medium text-blue-600 hover:text-blue-800 mb-2">
                  🪟 Popup System
                </a>
                <div class="ml-3 space-y-1 border-l-2 border-gray-200 pl-3">
                  <a href="#popup-basic" class="block text-sm text-gray-600 hover:text-gray-900">Basic Usage</a>
                  <a href="#popup-types" class="block text-sm text-gray-600 hover:text-gray-900">Popup Types</a>
                  <a href="#popup-form" class="block text-sm text-gray-600 hover:text-gray-900">Form in Popup</a>
                  <a href="#popup-component" class="block text-sm text-gray-600 hover:text-gray-900">Component Form</a>
                  <a href="#popup-edit" class="block text-sm text-gray-600 hover:text-gray-900">Edit Page</a>
                  <a href="#popup-confirm" class="block text-sm text-gray-600 hover:text-gray-900">Confirmation</a>
                  <a href="#popup-delete" class="block text-sm text-gray-600 hover:text-gray-900">Delete</a>
                  <a href="#popup-info" class="block text-sm text-gray-600 hover:text-gray-900">Info Dialog</a>
                  <a href="#popup-config" class="block text-sm text-gray-600 hover:text-gray-900">Configuration</a>
                </div>
              </div>

              <a href="#combined" class="block text-sm font-medium text-blue-600 hover:text-blue-800">
                🔗 Combined Usage
              </a>
              <a href="#references" class="block text-sm text-gray-600 hover:text-gray-900">
                File References
              </a>
            </nav>
          </div>
        </aside>

        <!-- Content -->
        <article class="flex-1 bg-white rounded-lg shadow-lg p-8 prose prose-blue max-w-none">
        <h1>UI Components Guide</h1>

        <div class="bg-blue-50 border-l-4 border-blue-500 p-4 my-6">
          <p class="font-semibold text-blue-900 mb-2">Overview</p>
          <p class="text-blue-800 mb-0">
            This guide covers the main UI feedback systems: <strong>Toaster</strong> for notifications and <strong>Popups</strong> for modals and dialogs.
          </p>
        </div>

        <!-- TOASTER SECTION -->
        <h2 id="toaster">🍞 Universal Toaster System</h2>

        <p>The Universal Toaster provides a consistent way to show temporary notifications to users. It's perfect for success messages, errors, warnings, and general information.</p>

        <h3 id="toaster-basic">Basic Usage</h3>

        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>const toast = useAppToast()

// Simple success message
toast.success('Dados salvos!')

// Error with title
toast.error('Falha ao conectar ao servidor', 'Erro de Conexão')

// Info with title
toast.info('Você tem 3 novas mensagens', 'Mensagens')

// Warning with title
toast.warning('Espaço em disco baixo (10% disponível)', 'Atenção')

// Default toast
toast.default('Notificação geral')</code></pre>

        <h3 id="toaster-types">Toast Types</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 my-6">
          <div class="border border-green-200 bg-green-50 p-4 rounded">
            <div class="font-semibold text-green-900 mb-2">✅ Success</div>
            <code class="text-sm">toast.success(message, title?, duration?)</code>
          </div>
          <div class="border border-red-200 bg-red-50 p-4 rounded">
            <div class="font-semibold text-red-900 mb-2">❌ Error</div>
            <code class="text-sm">toast.error(message, title?, duration?)</code>
          </div>
          <div class="border border-blue-200 bg-blue-50 p-4 rounded">
            <div class="font-semibold text-blue-900 mb-2">ℹ️ Info</div>
            <code class="text-sm">toast.info(message, title?, duration?)</code>
          </div>
          <div class="border border-yellow-200 bg-yellow-50 p-4 rounded">
            <div class="font-semibold text-yellow-900 mb-2">⚠️ Warning</div>
            <code class="text-sm">toast.warning(message, title?, duration?)</code>
          </div>
        </div>

        <h3 id="toaster-crud">Example 1: CRUD Operations with Feedback</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>async function crudOperations() {
  const toast = useAppToast()

  // Create
  try {
    await $fetch('/api/items', { method: 'POST', body: { name: 'Item' } })
    toast.success('Item criado com sucesso!', 'Sucesso')
  } catch {
    toast.error('Não foi possível criar o item', 'Erro ao Criar')
  }

  // Update with custom duration
  try {
    await $fetch('/api/items/1', { method: 'PUT', body: { name: 'Novo nome' } })
    toast.success('Alterações salvas', 'Atualizado', 3000)
  } catch {
    toast.error('Falha ao salvar alterações', 'Erro', 7000)
  }

  // Delete
  try {
    await $fetch('/api/items/1', { method: 'DELETE' })
    toast.success('Item removido', 'Eliminado', 2000)
  } catch {
    toast.error('Não foi possível eliminar o item', 'Erro')
  }
}</code></pre>

        <h3 id="toaster-validation">Example 2: Form Validation</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>function formValidation(formData: { name: string; email: string }) {
  const toast = useAppToast()

  if (!formData.name) {
    toast.warning('Nome é obrigatório')
    return false
  }

  if (formData.name.length < 3) {
    toast.error('Nome deve ter pelo menos 3 caracteres', 6000)
    return false
  }

  if (!formData.email.includes('@')) {
    toast.error('Email inválido')
    return false
  }

  toast.success('Formulário válido!')
  return true
}</code></pre>

        <h3 id="toaster-loading">Example 3: Loading States</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>async function loadingWithToast() {
  const toast = useAppToast()

  // Persistent toast (duration: 0 means it won't auto-close)
  const loadingId = toast.show({
    message: 'Carregando dados...',
    type: 'info',
    duration: 0
  })

  try {
    await fetch('https://api.example.com/data')
    toast.remove(loadingId)
    toast.success('Dados carregados!')
  } catch {
    toast.remove(loadingId)
    toast.error('Erro ao carregar dados')
  }
}</code></pre>

        <h3 id="toaster-upload">Example 4: File Upload Feedback</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>async function uploadWithFeedback(file: File) {
  const toast = useAppToast()

  const uploadId = toast.show({
    message: \`Enviando \${file.name}...\`,
    type: 'info',
    duration: 0
  })

  try {
    const formData = new FormData()
    formData.append('file', file)

    await $fetch('/api/upload', {
      method: 'POST',
      body: formData
    })

    toast.remove(uploadId)
    toast.success(\`\${file.name} enviado com sucesso!\`)
  } catch (error) {
    toast.remove(uploadId)
    toast.error(\`Erro ao enviar \${file.name}\`)
  }
}</code></pre>

        <h3 id="toaster-duration">Custom Duration</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>const toast = useAppToast()

// Quick toast (2 seconds)
toast.success('Copiado!', 2000)

// Normal toast (5 seconds - default)
toast.info('Informação importante')

// Long toast (10 seconds)
toast.error('Erro crítico que precisa de atenção', 10000)

// Persistent toast (won't close automatically)
const persistentId = toast.show({
  message: 'Aguardando confirmação...',
  type: 'warning',
  duration: 0
})

// Close it manually later
setTimeout(() => {
  toast.remove(persistentId)
}, 5000)</code></pre>

        <h3 id="toaster-control">Manual Control</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>const toast = useAppToast()

// Show multiple toasts
toast.info('Toast 1')
toast.info('Toast 2')
toast.info('Toast 3')

// Clear all toasts
toast.clear()

// Individual control
const id1 = toast.warning('Aviso importante')
const id2 = toast.info('Informação')

// Remove specific toast
toast.remove(id1)

// Access active toasts
console.log('Active toasts:', toast.toasts.value)</code></pre>

        <div class="bg-yellow-50 border-l-4 border-yellow-500 p-4 my-6">
          <p class="font-semibold text-yellow-900 mb-2">💡 Best Practices</p>
          <ul class="text-yellow-800 mb-0 space-y-1">
            <li>Use <strong>success</strong> for successful operations</li>
            <li>Use <strong>error</strong> for failures and critical issues</li>
            <li>Use <strong>warning</strong> for important information that needs attention</li>
            <li>Use <strong>info</strong> for general notifications</li>
            <li>Keep messages short and clear</li>
            <li>Use titles for context when needed</li>
            <li>Adjust duration based on message importance</li>
          </ul>
        </div>

        <!-- POPUP SECTION -->
        <h2 id="popup" class="mt-12">🪟 Universal Popup System</h2>

        <p>The Universal Popup system provides a flexible way to display modals, dialogs, and confirmations. It can render full pages, components, or simple HTML content.</p>

        <h3 id="popup-basic">Basic Usage</h3>

        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>import { usePopupStore } from '~/stores/popup'

const popupStore = usePopupStore()

// Open a popup
popupStore.open({
  type: 'common',
  title: 'My Popup',
  content: 'Simple text content',
  acceptButton: { label: 'OK' },
  declineButton: { label: 'Cancelar' }
})

// Close popup
popupStore.close()</code></pre>

        <h3 id="popup-types">Popup Types</h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 my-6">
          <div class="border border-blue-200 bg-blue-50 p-4 rounded">
            <div class="font-semibold text-blue-900 mb-2">Common</div>
            <div class="text-sm text-blue-800">General purpose popup</div>
          </div>
          <div class="border border-orange-200 bg-orange-50 p-4 rounded">
            <div class="font-semibold text-orange-900 mb-2">Confirmation</div>
            <div class="text-sm text-orange-800">Yes/No confirmations</div>
          </div>
          <div class="border border-red-200 bg-red-50 p-4 rounded">
            <div class="font-semibold text-red-900 mb-2">Delete</div>
            <div class="text-sm text-red-800">Deletion confirmations</div>
          </div>
        </div>

        <h3 id="popup-form">Example 1: Create/Edit Form in Popup</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>function openCreateRolePopup() {
  popupStore.open({
    type: 'common',
    title: 'Criar Novo Cargo',
    // Load a page as popup content
    pagePath: '~/pages/users/roles/new.vue',
    pageProps: {
      mode: 'popup',
      redirectOnSuccess: false
    },
    declineButton: { label: 'Cancelar' },
    onClose: async () => {
      // Refresh data after closing
      await refreshRoles()
    }
  })
}</code></pre>

        <h3 id="popup-component">Example 2: Component Form in Popup</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>import RoleForm from '~/components/forms/RoleForm.vue'

function openRoleFormPopup() {
  popupStore.open({
    type: 'common',
    title: 'Adicionar Cargo',
    // Direct component import
    pageComponent: RoleForm,
    pageProps: {
      initialData: { name: '' }
    },
    acceptButton: { label: 'Salvar' },
    onAccept: async () => {
      // Submit logic can be here or in component
      toast.add({ title: 'Salvo!', color: 'success' })
    }
  })
}</code></pre>

        <h3 id="popup-edit">Example 3: Edit Page in Popup</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>function openEditRolePopup(roleId: number) {
  popupStore.open({
    type: 'common',
    title: 'Editar Cargo',
    pagePath: \`~/pages/users/roles/[id].vue\`,
    pageProps: {
      mode: 'popup',
      id: roleId
    },
    acceptButton: null, // Page has its own buttons
    declineButton: { label: 'Fechar' }
  })
}</code></pre>

        <h3 id="popup-confirm">Example 4: Confirmation Dialog</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>function confirmAction(userName: string) {
  popupStore.open({
    type: 'confirmation',
    title: 'Confirmar Ação',
    content: \`
      &lt;p&gt;Deseja realmente executar esta ação para &lt;strong&gt;\${userName}&lt;/strong&gt;?&lt;/p&gt;
      &lt;ul class="list-disc ml-5 mt-2 text-sm"&gt;
        &lt;li&gt;Todas as permissões serão removidas&lt;/li&gt;
        &lt;li&gt;O acesso será bloqueado&lt;/li&gt;
        &lt;li&gt;Esta ação pode ser revertida&lt;/li&gt;
      &lt;/ul&gt;
    \`,
    acceptButton: {
      label: 'Sim, confirmar',
      color: 'primary',
      icon: 'i-lucide-check'
    },
    onAccept: async () => {
      await executeAction()
      toast.add({ title: 'Ação executada', color: 'success' })
    }
  })
}</code></pre>

        <h3 id="popup-delete">Example 5: Delete Confirmation</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>async function deleteRole(roleId: number, roleName: string) {
  popupStore.open({
    type: 'delete',
    title: 'Eliminar Cargo',
    icon: 'i-lucide-trash-2',
    content: \`
      Tem certeza que deseja eliminar o cargo &lt;strong&gt;\${roleName}&lt;/strong&gt;?&lt;br&gt;
      &lt;span class="text-sm text-error"&gt;Esta ação não pode ser desfeita.&lt;/span&gt;
    \`,
    onAccept: async () => {
      try {
        await $fetch(\`/api/roles/\${roleId}\`, { method: 'DELETE' })
        toast.add({
          title: 'Cargo eliminado',
          description: \`\${roleName} foi removido com sucesso\`,
          color: 'success'
        })
        refreshRoles()
      } catch (error) {
        toast.add({
          title: 'Erro ao eliminar',
          description: error.message,
          color: 'error'
        })
      }
    }
  })
}</code></pre>

        <h3 id="popup-info">Example 6: Simple Info Dialog</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>function showInfo(message: string) {
  popupStore.open({
    type: 'common',
    title: 'Informação',
    content: message,
    acceptButton: { label: 'OK' },
    declineButton: null // No cancel button
  })
}</code></pre>

        <h3>Example 7: Session Expired Dialog</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>function openSessionExpired() {
  popupStore.open({
    type: 'common',
    title: 'Sessão Expirada',
    icon: 'i-lucide-alert-circle',
    content: 'Sua sessão expirou. Faça login novamente.',
    acceptButton: { label: 'Ir para Login' },
    onClose: () => {
      // Executed when closing (accept or X button)
      navigateTo('/login')
    }
  })
}</code></pre>

        <h3 id="popup-config">Popup Configuration Options</h3>

        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 border">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Property</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Description</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr>
                <td class="px-6 py-4 text-sm font-mono">type</td>
                <td class="px-6 py-4 text-sm">string</td>
                <td class="px-6 py-4 text-sm">'common' | 'confirmation' | 'delete'</td>
              </tr>
              <tr>
                <td class="px-6 py-4 text-sm font-mono">title</td>
                <td class="px-6 py-4 text-sm">string</td>
                <td class="px-6 py-4 text-sm">Popup title</td>
              </tr>
              <tr>
                <td class="px-6 py-4 text-sm font-mono">content</td>
                <td class="px-6 py-4 text-sm">string</td>
                <td class="px-6 py-4 text-sm">HTML content (optional)</td>
              </tr>
              <tr>
                <td class="px-6 py-4 text-sm font-mono">pagePath</td>
                <td class="px-6 py-4 text-sm">string</td>
                <td class="px-6 py-4 text-sm">Path to page component (lazy loaded)</td>
              </tr>
              <tr>
                <td class="px-6 py-4 text-sm font-mono">pageComponent</td>
                <td class="px-6 py-4 text-sm">Component</td>
                <td class="px-6 py-4 text-sm">Direct component import</td>
              </tr>
              <tr>
                <td class="px-6 py-4 text-sm font-mono">pageProps</td>
                <td class="px-6 py-4 text-sm">object</td>
                <td class="px-6 py-4 text-sm">Props to pass to page/component</td>
              </tr>
              <tr>
                <td class="px-6 py-4 text-sm font-mono">acceptButton</td>
                <td class="px-6 py-4 text-sm">object | null</td>
                <td class="px-6 py-4 text-sm">{ label, color?, icon? }</td>
              </tr>
              <tr>
                <td class="px-6 py-4 text-sm font-mono">declineButton</td>
                <td class="px-6 py-4 text-sm">object | null</td>
                <td class="px-6 py-4 text-sm">{ label, color?, icon? }</td>
              </tr>
              <tr>
                <td class="px-6 py-4 text-sm font-mono">onAccept</td>
                <td class="px-6 py-4 text-sm">function</td>
                <td class="px-6 py-4 text-sm">Callback when accept is clicked</td>
              </tr>
              <tr>
                <td class="px-6 py-4 text-sm font-mono">onDecline</td>
                <td class="px-6 py-4 text-sm">function</td>
                <td class="px-6 py-4 text-sm">Callback when decline is clicked</td>
              </tr>
              <tr>
                <td class="px-6 py-4 text-sm font-mono">onClose</td>
                <td class="px-6 py-4 text-sm">function</td>
                <td class="px-6 py-4 text-sm">Callback when popup closes (any way)</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="bg-green-50 border-l-4 border-green-500 p-4 my-6">
          <p class="font-semibold text-green-900 mb-2">💡 Best Practices</p>
          <ul class="text-green-800 mb-0 space-y-1">
            <li>Use <strong>pagePath</strong> for lazy loading (better performance)</li>
            <li>Use <strong>pageComponent</strong> for small, frequently used components</li>
            <li>Set <code>acceptButton: null</code> when the page/component controls its own actions</li>
            <li>Use <strong>onClose</strong> to refresh data after popup closes</li>
            <li>Combine with toast system for better user feedback</li>
            <li>Use appropriate types: 'common' for general, 'delete' for deletions</li>
          </ul>
        </div>

        <h2 id="combined" class="mt-12">🔗 Combining Toaster and Popup</h2>

        <p>You can combine both systems for a complete user experience:</p>

        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>function toastWithPopup() {
  const toast = useAppToast()
  const popupStore = usePopupStore()

  popupStore.open({
    type: 'confirmation',
    title: 'Confirmar Ação',
    content: 'Deseja realmente continuar?',
    onAccept: async () => {
      toast.info('Processando...')
      try {
        await executeAction()
        toast.success('Ação concluída!')
      } catch {
        toast.error('Ação falhou')
      }
    },
    onDecline: () => {
      toast.default('Ação cancelada')
    }
  })
}</code></pre>

        <h2 id="references">File References</h2>
        <ul>
          <li>Toaster Examples: <code>app/composables/useToasterExamples.ts</code></li>
          <li>Popup Examples: <code>app/composables/usePopupExamples.ts</code></li>
          <li>Toaster Store: <code>app/stores/toast.ts</code></li>
          <li>Popup Store: <code>app/stores/popup.ts</code></li>
          <li>Toaster Component: <code>app/components/UniversalToaster.vue</code></li>
          <li>Popup Component: <code>app/components/UniversalPopup.vue</code></li>
        </ul>
        </article>
      </div>

      <!-- Bottom Navigation -->
      <div class="mt-8">
        <NuxtLink
          to="/guide"
          class="inline-flex items-center text-blue-600 hover:text-blue-800 font-medium"
        >
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
          </svg>
          Back to Guides
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: false
})
</script>
