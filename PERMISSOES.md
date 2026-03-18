# Sistema de Permissões - Clínica de Psicologia

## Níveis de Permissão

O sistema possui 4 níveis hierárquicos de permissão (quanto menor o número, mais poder):

### 0 - Administrador
- Acesso total ao sistema
- Pode gerir utilizadores (criar, editar, remover)
- Pode ver e editar todas as sessões
- Pode atribuir sessões a qualquer terapeuta
- Acesso completo a configurações do sistema
- Pode ver todos os relatórios

### 1 - Gestor
- Pode ver todos os utilizadores
- Pode ver e editar todas as sessões
- Pode atribuir sessões a outros terapeutas
- Pode gerir clientes
- Acesso a configurações (exceto configurações do sistema)
- Pode ver todos os relatórios

### 2 - Terapeuta
- Pode ver apenas suas próprias sessões
- Pode criar e editar suas próprias sessões
- Pode ver e gerir clientes
- Não pode atribuir sessões a outros
- Pode ver apenas seus próprios relatórios
- Acesso limitado a configurações (apenas notificações e password)

### 3 - Restrito
- Acesso apenas para visualização
- Não pode criar ou editar nada
- Navegação limitada

## Como Usar

### No Código Vue (Componentes)

```vue
<script setup>
const { can, canCreateUsers, canEditAllSessions, isAdmin } = usePermissions()

// Verificar permissão específica
if (can('CREATE_USERS')) {
  // fazer algo
}

// Usar computed direto
if (isAdmin.value) {
  // fazer algo de admin
}
</script>

<template>
  <!-- Mostrar botão apenas para quem pode criar utilizadores -->
  <UButton v-if="canCreateUsers" @click="createUser">
    Novo Utilizador
  </UButton>

  <!-- Mostrar lista apenas para admins -->
  <div v-if="isAdmin">
    <!-- conteúdo admin -->
  </div>
</template>
```

### No Backend (API)

```typescript
// server/api/alguma-rota.ts
export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  
  // Verificar permissão
  if (!hasPermission(currentUser.permission, 'DELETE_USERS')) {
    throw createError({ statusCode: 403, message: 'Sem permissão' })
  }
  
  // continuar com a lógica
})
```

### Middleware de Rotas

O middleware `permissions.ts` protege automaticamente certas rotas:
- `/users` - requer `VIEW_ALL_USERS`
- `/settings` - requer `ACCESS_SETTINGS`
- `/settings/members` - requer `VIEW_ALL_USERS`

## Capacidades Disponíveis

### Gestão de Utilizadores
- `VIEW_ALL_USERS` - Ver todos os utilizadores
- `CREATE_USERS` - Criar novos utilizadores
- `EDIT_USERS` - Editar utilizadores
- `DELETE_USERS` - Remover utilizadores

### Gestão de Sessões
- `VIEW_ALL_SESSIONS` - Ver todas as sessões
- `VIEW_OWN_SESSIONS` - Ver próprias sessões
- `CREATE_SESSIONS` - Criar sessões
- `EDIT_ALL_SESSIONS` - Editar todas as sessões
- `EDIT_OWN_SESSIONS` - Editar próprias sessões
- `DELETE_SESSIONS` - Remover sessões
- `ASSIGN_SESSIONS_TO_OTHERS` - Atribuir sessões a outros

### Gestão de Clientes
- `VIEW_CLIENTS` - Ver clientes
- `CREATE_CLIENTS` - Criar clientes
- `EDIT_CLIENTS` - Editar clientes
- `DELETE_CLIENTS` - Remover clientes

### Configurações
- `ACCESS_SETTINGS` - Aceder a configurações
- `CHANGE_SYSTEM_SETTINGS` - Alterar configurações do sistema

### Relatórios
- `VIEW_REPORTS` - Ver todos os relatórios
- `VIEW_OWN_REPORTS` - Ver próprios relatórios

## Exemplo Prático

```vue
<script setup>
const { canDeleteUsers, canEditAllSessions, canViewClients } = usePermissions()

function handleDelete(userId) {
  if (!canDeleteUsers.value) {
    toast.add({ title: 'Sem permissão', color: 'error' })
    return
  }
  // executar delete
}
</script>

<template>
  <UCard>
    <template v-if="canViewClients">
      <ClientList />
    </template>
    
    <UButton 
      v-if="canEditAllSessions" 
      @click="editSession"
    >
      Editar Sessão
    </UButton>
  </UCard>
</template>
```

## Menu Lateral

O menu lateral já está configurado para mostrar/ocultar itens baseado nas permissões:
- **Customers** - apenas se `canViewClients`
- **Utilizadores** - apenas se `canViewAllUsers`
- **Settings** - apenas se `canAccessSettings`
- **Members** (em Settings) - apenas se `canViewAllUsers`

## Próximos Passos

1. Atualizar páginas existentes para usar o sistema de permissões
2. Adicionar verificações no backend para todas as rotas sensíveis
3. Criar UI para gestão de permissões de utilizadores
4. Adicionar logs de auditoria para ações sensíveis
