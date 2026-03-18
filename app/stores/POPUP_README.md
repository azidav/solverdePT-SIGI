# Stores Pinia

## Universal Popup Store

Sistema universal para gerenciar popups/modais na aplicação com configuração flexível.

### Setup

1. Adicione o componente `<UniversalPopup />` no layout ou página principal
2. Use `usePopupStore()` para abrir popups em qualquer componente

```vue
<template>
  <div>
    <!-- Seu conteúdo -->
    <UniversalPopup />
  </div>
</template>
```

### Tipos de Popup

- `common` - Popup genérico informativo (ícone azul)
- `confirmation` - Popup de confirmação (ícone amarelo)
- `delete` - Popup de eliminação (ícone vermelho)

### Exemplos de Uso

#### 1. Popup Simples (Informativo)

```typescript
const popupStore = usePopupStore()

popupStore.open({
  type: 'common',
  title: 'Informação',
  content: 'Operação realizada com sucesso!',
  acceptButton: { label: 'OK' }
})
```

#### 2. Popup de Confirmação

```typescript
popupStore.open({
  type: 'confirmation',
  title: 'Confirmar Ação',
  content: 'Tem a certeza que deseja prosseguir?',
  onAccept: async () => {
    // Lógica ao confirmar
    await saveData()
  },
  onDecline: () => {
    console.log('Cancelado')
  }
})
```

#### 3. Popup de Eliminação

```typescript
popupStore.open({
  type: 'delete',
  title: 'Eliminar Item',
  content: `Tem a certeza que deseja eliminar <strong>${itemName}</strong>?`,
  onAccept: async () => {
    try {
      await $fetch(`/api/items/${id}`, { method: 'DELETE' })
      toast.add({ title: 'Eliminado com sucesso', color: 'success' })
    } catch (error) {
      toast.add({ title: 'Erro ao eliminar', color: 'error' })
    }
  }
})
```

#### 4. Popup com Componente Personalizado

```typescript
import MyCustomForm from '~/components/MyCustomForm.vue'

popupStore.open({
  type: 'common',
  title: 'Editar Dados',
  pageComponent: MyCustomForm,
  pageProps: {
    userId: 123,
    initialData: { name: 'João' }
  },
  acceptButton: { label: 'Guardar' },
  onAccept: async () => {
    // Lógica de submissão
  }
})
```

#### 4b. Popup com Página Completa (Lazy Load)

```typescript
// Carrega uma página Vue de forma lazy
popupStore.open({
  type: 'common',
  title: 'Novo Cargo',
  pagePath: '~/pages/users/roles/new.vue',
  pageProps: {
    // Props para a página
    prefilledData: { name: 'Gestor' }
  },
  acceptButton: { label: 'Criar' },
  declineButton: { label: 'Cancelar' },
  onAccept: async () => {
    // A lógica de submit pode estar na própria página
    // ou aqui através de um emit/callback
  }
})
```

#### 4c. Popup com Página Inline (Sem Lazy Load)

```typescript
import RoleFormPage from '~/pages/users/roles/new.vue'

popupStore.open({
  type: 'common',
  title: 'Adicionar Cargo',
  pageComponent: RoleFormPage,
  pageProps: {
    mode: 'create',
    redirectOnSuccess: false
  },
  acceptButton: null, // A página tem seus próprios botões
  declineButton: { label: 'Fechar' }
})
```

#### 5. Popup com Ícone Personalizado

```typescript
popupStore.open({
  type: 'confirmation',
  title: 'Enviar Email',
  icon: 'i-lucide-mail',
  content: 'Enviar notificação por email?',
  acceptButton: {
    label: 'Enviar',
    color: 'primary',
    icon: 'i-lucide-send'
  },
  onAccept: async () => {
    await sendEmail()
  }
})
```

#### 6. Popup com Callback onClose

```typescript
popupStore.open({
  type: 'common',
  title: 'Aviso',
  content: 'Sessão expirada',
  acceptButton: { label: 'Entendido' },
  onClose: () => {
    // Executado quando o popup fecha (X ou botão)
    router.push('/login')
  }
})
```

#### 7. Popup com Página Adaptável

```typescript
// Exemplo: Abrir formulário de criação como popup
import RoleFormPage from '~/components/examples/PopupAdaptablePage.vue'

popupStore.open({
  type: 'common',
  title: 'Criar Novo Cargo',
  pageComponent: RoleFormPage,
  pageProps: {
    mode: 'popup', // Diz à página para renderizar sem layout
    redirectOnSuccess: false,
    prefilledData: { name: 'Novo Cargo' }
  },
  acceptButton: null, // Página tem seu próprio botão submit
  declineButton: { label: 'Cancelar' }
})

// A mesma página pode ser usada normalmente em /users/roles/new
// e como popup quando chamada pelo store
```

#### 8. Popup Sem Botões (Página com Controle Próprio)

```typescript
popupStore.open({
  type: 'common',
  title: 'Editor Avançado',
  pagePath: '~/pages/editor/advanced.vue',
  acceptButton: null,
  declineButton: null,
  // A página fecha o popup chamando popupStore.close()
})
```

### API Completa

#### PopupConfig Interface

```typescript
interface PopupConfig {
  type: 'common' | 'confirmation' | 'delete'
  title?: string
  icon?: string // Ícone personalizado (ex: 'i-lucide-mail')
  content?: string // HTML string
  
  // Renderizar conteúdo customizado (escolha um):
  pageComponent?: Component // Componente Vue importado diretamente
  pagePath?: string // Path para lazy load (ex: '~/pages/users/new.vue')
  pageId?: string // ID/identificador da página (para uso futuro)
  pageProps?: Record<string, unknown> // Props para componente/página
  
  // Botões e callbacks:
  acceptButton?: PopupButton
  declineButton?: PopupButton
  onClose?: () => void | Promise<void>
  onAccept?: () => void | Promise<void>
  onDecline?: () => void | Promise<void>
}

interface PopupButton {
  label: string
  color?: 'primary' | 'error' | 'success' | 'warning' | 'neutral'
  variant?: 'solid' | 'outline' | 'soft' | 'subtle' | 'ghost'
  icon?: string
  onClick?: () => void | Promise<void>
}
```

#### Store Methods

- `popupStore.open(config)` - Abre popup com configuração
- `popupStore.close()` - Fecha popup atual
- `popupStore.accept()` - Executa ação de aceitar
- `popupStore.decline()` - Executa ação de recusar

#### Store State

- `popupStore.isOpen` - boolean
- `popupStore.config` - PopupConfig | null
- `popupStore.currentConfig` - getter para config atual
- `popupStore.isPopupOpen` - getter para estado de abertura

---

### Diferenças: pageComponent vs pagePath

| Feature | `pageComponent` | `pagePath` |
|---------|----------------|------------|
| **Import** | Direto (import statement) | Lazy load dinâmico |
| **Bundle** | Incluído no build principal | Code-splitting automático |
| **Performance** | Mais rápido (já carregado) | Carrega sob demanda |
| **Uso ideal** | Componentes pequenos/frequentes | Páginas grandes/raras |

**Recomendação**: Use `pageComponent` para componentes leves e frequentes. Use `pagePath` para páginas complexas que raramente são abertas em popup.

---

### Boas Práticas

#### 1. Páginas Adaptáveis (Dual-Mode)

Crie páginas que funcionam tanto como rota normal quanto como popup:

```vue
<script setup>
const props = defineProps<{
  mode?: 'page' | 'popup'
}>()

const popupStore = usePopupStore()

function handleSuccess() {
  if (props.mode === 'popup') {
    popupStore.close()
  } else {
    router.push('/success')
  }
}
</script>

<template>
  <!-- Renderiza layout completo se mode !== 'popup' -->
  <UDashboardPanel v-if="mode !== 'popup'">
    <!-- Layout completo -->
  </UDashboardPanel>
  
  <!-- Conteúdo simples para popup -->
  <div v-else>
    <!-- Só o essencial -->
  </div>
</template>
```

#### 2. Fechar Popup de Dentro da Página

```vue
<script setup>
const popupStore = usePopupStore()

async function handleSubmit() {
  await saveData()
  popupStore.close() // Fecha o popup após salvar
}
</script>
```

#### 3. Popup com Loading State

```typescript
const popupStore = usePopupStore()

popupStore.open({
  type: 'confirmation',
  title: 'Processar',
  content: 'Deseja iniciar o processamento?',
  onAccept: async () => {
    // O popup fecha automaticamente após onAccept
    // mas você pode manter aberto para mostrar loading
    try {
      await heavyOperation()
    } catch (error) {
      // Popup já fechou, usar toast para feedback
      toast.add({ title: 'Erro', color: 'error' })
    }
  }
})
```

#### 4. Popups Encadeados

```typescript
// Popup 1
popupStore.open({
  type: 'confirmation',
  title: 'Passo 1',
  content: 'Confirmar primeira ação?',
  onAccept: () => {
    // Popup 2 (abre quando o primeiro fecha)
    setTimeout(() => {
      popupStore.open({
        type: 'common',
        title: 'Passo 2',
        content: 'Próxima ação...'
      })
    }, 100)
  }
})
```

---

### Exemplos de Uso Real

#### Criar Item com Popup

```typescript
// Em qualquer componente/página
const popupStore = usePopupStore()

function openCreateRolePopup() {
  popupStore.open({
    type: 'common',
    title: 'Criar Novo Cargo',
    pagePath: '~/pages/users/roles/new.vue',
    pageProps: {
      mode: 'popup',
      redirectOnSuccess: false
    },
    declineButton: { label: 'Cancelar' },
    onClose: () => {
      // Refresh lista após fechar
      refreshRoles()
    }
  })
}
```

#### Confirmação de Ação Destrutiva

```typescript
function confirmDeleteUser(userId: number, userName: string) {
  popupStore.open({
    type: 'delete',
    title: 'Eliminar Utilizador',
    content: `
      <p>Tem certeza que deseja eliminar <strong>${userName}</strong>?</p>
      <p class="text-sm text-error mt-2">Esta ação é irreversível!</p>
    `,
    onAccept: async () => {
      await $fetch(`/api/users/${userId}`, { method: 'DELETE' })
      toast.add({ title: 'Utilizador eliminado', color: 'success' })
      refreshUsers()
    }
  })
}
```
