# Universal Toaster System

Sistema universal de notificações toast usando Nuxt UI com Pinia.

## Setup

1. Adicione o componente `<UniversalToaster />` no layout principal:

```vue
<!-- app/layouts/default.vue -->
<template>
  <div>
    <NuxtPage />
    <UniversalToaster />
  </div>
</template>
```

2. Use o composable `useAppToast()` (wrapper do Nuxt UI) em qualquer componente:

```vue
<script setup>
const toast = useAppToast()

function handleSuccess() {
  toast.success('Operação realizada com sucesso!', 'Sucesso')
}
</script>
```

## API

### Tipos de Toast

- `default` - Toast padrão (cinza) com ícone de mensagem
- `info` - Toast informativo (azul) com ícone de info
- `success` - Toast de sucesso (verde) com ícone de check
- `warning` - Toast de aviso (amarelo) com ícone de alerta
- `error` - Toast de erro (vermelho) com ícone de X

### Métodos

#### `toast.show(config)`
Exibe toast com configuração customizada.

```typescript
toast.show({
  message: 'Mensagem customizada',
  title: 'Título Opcional',
  type: 'info',
  duration: 3000 // 3 segundos
})
```

#### Atalhos por Tipo

```typescript
// Toast de sucesso (5 segundos por padrão)
toast.success('Item criado com sucesso!')

// Toast de erro (5 segundos por padrão)
toast.error('Erro ao salvar dados')

// Toast informativo
toast.info('Nova versão disponível')

// Toast de aviso
toast.warning('Sessão expirando em 5 minutos')

// Toast padrão
toast.default('Notificação geral')

// Com duração customizada (em milissegundos)
toast.success('Salvo!', 2000) // 2 segundos
toast.error('Erro crítico!', 10000) // 10 segundos

// Com título (segundo parâmetro string)
toast.success('Operação concluída com sucesso', 'Sucesso')
toast.error('Não foi possível salvar os dados', 'Erro')
toast.info('Atualização disponível para download', 'Nova Versão')
toast.warning('Sua sessão expira em 5 minutos', 'Atenção')

// Com título E duração customizada
toast.success('Dados salvos', 'Sucesso', 3000)
toast.error('Falha na conexão', 'Erro Crítico', 10000)
```

#### Gerenciamento

```typescript
// Remover toast específico
const toastId = toaster.success('Operação em andamento...')
setTimeout(() => {
  toaster.remove(toastId)
}, 2000)

// Limpar todos os toasts
toaster.clear()

// Acessar lista de toasts ativos
const activeToasts = toaster.toasts.value
```

## Exemplos de Uso

### 1. Feedback de Operações CRUD

```typescript
async function createRole(data) {
  const toaster = useToaster()
  
  try {
    await $fetch('/api/roles', { method: 'POST', body: data })
    toaster.success('Cargo criado com sucesso!', 'Sucesso')
  } catch (error) {
    toaster.error('Não foi possível criar o cargo', 'Erro')
  }
}
```

### 2. Validação de Formulário

```typescript
function validateForm() {
  const toaster = useToaster()
  
  if (!form.name) {
    toaster.warning('Nome é obrigatório')
    return false
  }
  
  if (form.name.length < 3) {
    toaster.error('Nome deve ter pelo menos 3 caracteres', 7000)
    return false
  }
  
  return true
}
```

### 3. Informações do Sistema

```typescript
function checkUpdates() {
  const toaster = useToaster()
  
  toaster.info('Verificando atualizações...', 2000)
  
  setTimeout(() => {
    toaster.success('Sistema atualizado!')
  }, 2000)
}
```

### 4. Confirmação de Ações

```typescript
async function deleteItem(id: number) {
  const toaster = useToaster()
  
  try {
    await $fetch(`/api/items/${id}`, { method: 'DELETE' })
    toaster.success('Item eliminado', 3000)
    refreshList()
  } catch (error) {
    toaster.error('Não foi possível eliminar o item', 5000)
  }
}
```

### 5. Toast com ID Customizado

```typescript
const toaster = useToaster()

// Criar toast com ID específico
toaster.show({
  id: 'saving-progress',
  message: 'Salvando...',
  type: 'info',
  duration: 0 // Não fecha automaticamente
})

// Remover quando terminar
setTimeout(() => {
  toaster.remove('saving-progress')
  toaster.success('Salvo com sucesso!')
}, 3000)
```

### 6. Notificações em Sequência

```typescript
const toaster = useToaster()

async function processMultipleItems(items: Item[]) {
  toaster.info(`Processando ${items.length} itens...`, 2000)
  
  let success = 0
  let failed = 0
  
  for (const item of items) {
    try {
      await processItem(item)
      success++
    } catch {
      failed++
    }
  }
  
  if (success > 0) {
    toaster.success(`${success} itens processados com sucesso`)
  }
  
  if (failed > 0) {
    toaster.error(`${failed} itens falharam`)
  }
}
```

### 7. Toast Persistente (Sem Auto-Hide)

```typescript
const toaster = useToaster()

// Toast que não fecha automaticamente
const loadingId = toaster.show({
  message: 'Carregando dados grandes...',
  type: 'info',
  duration: 0 // 0 = não fecha automaticamente
})

// Fechar manualmente quando terminar
await loadBigData()
toaster.remove(loadingId)
toaster.success('Dados carregados!')
```

### 8. Toast em Resposta a Eventos

```typescript
// Notificar quando dados mudarem
watch(dataStore.users, (newUsers, oldUsers) => {
  const toaster = useToaster()
  
  if (newUsers.length > oldUsers.length) {
    toaster.info('Novo usuário adicionado')
  }
})

// Notificar erro de conexão
onErrorCaptured((error) => {
  const toaster = useToaster()
  toaster.error('Erro de conexão', 8000)
})
```

## Configuração Avançada

### Interface ToastConfig

```typescript
interface ToastConfig {
  message: string                    // Mensagem a exibir
  title?: string                     // Título opcional (exibido em negrito acima da mensagem)
  type?: 'default' | 'info' | 'success' | 'warning' | 'error' // Tipo do toast
  duration?: number                  // Duração em ms (default: 5000, 0 = permanente)
  id?: string                        // ID customizado (opcional)
}
```

### Store Methods

```typescript
const toastStore = useToastStore()

// Métodos disponíveis
toastStore.show(config)                    // Criar toast
toastStore.remove(id)                      // Remover toast
toastStore.clear()                         // Limpar todos
toastStore.success(msg, titleOrDur, dur)   // Atalho sucesso
toastStore.error(msg, titleOrDur, dur)     // Atalho erro
toastStore.info(msg, titleOrDur, dur)      // Atalho info
toastStore.warning(msg, titleOrDur, dur)   // Atalho aviso
toastStore.default(msg, titleOrDur, dur)   // Atalho padrão

// Assinaturas dos atalhos:
// method(message: string)                           -> sem título, duração padrão
// method(message: string, duration: number)         -> sem título, duração custom
// method(message: string, title: string)            -> com título, duração padrão
// method(message: string, title: string, duration)  -> com título e duração custom

// Getters
toastStore.activeToasts // Array de toasts ativos
```

## Boas Práticas

1. **Duração Apropriada**
   - Mensagens curtas: 2-3 segundos
   - Mensagens normais: 5 segundos (padrão)
   - Mensagens importantes/erros: 7-10 segundos
   - Loading/processamento: duration = 0 (fechar manualmente)

2. **Tipo Correto**
   - `success` - Operações concluídas
   - `error` - Erros que impedem ação
   - `warning` - Avisos que não bloqueiam
   - `info` - Informações gerais
   - `default` - Mensagens neutras

3. **Mensagens Claras**
   ```typescript
   // ❌ Vago
   toaster.error('Erro')
   
   // ✅ Específico
   toaster.error('Erro ao salvar: nome já existe')
   ```

4. **Não Abusar**
   ```typescript
   // ❌ Toast para cada ação
   items.forEach(item => {
     toaster.info(`Processando ${item.name}`)
   })
   
   // ✅ Toast resumido
   toaster.info(`Processando ${items.length} itens...`)
   // ... depois
   toaster.success('Todos os itens processados!')
   ```

## Estilização

O componente usa classes do Nuxt UI e pode ser customizado via `ui` prop:

```vue
<UCard
  :ui="{
    body: 'p-0',
    background: 'bg-elevated',
    shadow: 'shadow-lg'
  }"
>
```

As cores são baseadas no tipo do toast e seguem o design system do Nuxt UI.
