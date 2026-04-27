# Guia de Permissões & Controlo de Acesso

Este projeto usa um sistema híbrido de permissões com **duas camadas**:

| Camada | Onde | Para quê |
|---|---|---|
| **Nível numérico** (legacy) | `users.permission` | Controlo grosseiro: Admin / Manager / Employee |
| **Códigos RBAC** (moderno) | Tabela `permissions` via `role_permissions` | Controlo fino por módulo e ação |

---

## 1. Conceitos

### Níveis numéricos (`users.permission`)
| Valor | Label | Acesso |
|---|---|---|
| `0` | Admin | Tudo |
| `1` | Manager | Gestão de módulos |
| `2` | Employee | Pedidos e reservas |
| `3` | Restricted | Só leitura |

### Códigos de permissão (RBAC)
Formato: `MÓDULO:AÇÃO`

| Código | Descrição |
|---|---|
| `SETTINGS:VIEW` | Ver secção de definições |
| `SETTINGS:MANAGE_ROLES` | Criar/editar/eliminar grupos e permissões |
| `SETTINGS:MANAGE_USERS` | Gerir utilizadores |
| `VACATION:APPROVE` | Aprovar pedidos de férias |
| `VACATION:VIEW_TEAM` | Ver férias da equipa |
| `EQUIPMENT:*` | Ações sobre equipamentos |
| `ROOMS:*` | Ações sobre salas de reunião |

Os códigos são atribuídos a **grupos (roles)**, e os grupos são atribuídos a **utilizadores**.

---

## 2. Proteger uma página (Frontend)

### Opção A — `useRbac()` (recomendado, RBAC moderno)

```vue
<script setup lang="ts">
const { can, canManageRoles } = useRbac()

// Verificação simples
if (!can('SETTINGS:VIEW')) {
  navigateTo('/')
}
</script>
```

O `useRbac()` carrega os códigos do servidor em `onMounted` via `/api/users/me/permissions`.

**Métodos disponíveis:**

```ts
const {
  can('CÓDIGO'),              // tem exactamente este código?
  canAny(['COD1','COD2']),    // tem pelo menos um?
  canAll(['COD1','COD2']),    // tem todos?
  canAccessModule('VACATION'),// tem qualquer permissão deste módulo?

  // Atalhos pré-definidos
  canManageRoles,   // SETTINGS:MANAGE_ROLES
  canManageUsers,   // SETTINGS:MANAGE_USERS
  canSettings,      // qualquer SETTINGS:*
  canVacation,      // qualquer VACATION:*
} = useRbac()
```

### Opção B — `usePermissions()` (legacy, nível numérico)

```vue
<script setup lang="ts">
const { isAdmin, can } = usePermissions()

// can() usa as capabilities definidas em app/utils/permissions.ts
if (!can('ACCESS_SETTINGS')) {
  navigateTo('/')
}
</script>
```

### Opção C — Middleware de rota

Adicionar em `app/middleware/permissions.ts`:

```ts
if (to.path.startsWith('/nova-secao')) {
  const { can } = usePermissions()
  if (!can('MANAGE_USERS')) {
    return navigateTo('/')
  }
}
```

---

## 3. Mostrar/esconder elementos na UI

```vue
<template>
  <!-- Só admins veem este botão -->
  <UButton v-if="can('SETTINGS:MANAGE_ROLES')" label="Editar" />

  <!-- Usando os atalhos -->
  <div v-if="canManageRoles">
    <UButton label="Eliminar Grupo" color="error" />
  </div>

  <!-- Usando nível numérico -->
  <span v-if="isAdmin">Acesso total</span>
</template>

<script setup lang="ts">
const { can, canManageRoles } = useRbac()
const { isAdmin } = usePermissions()
</script>
```

---

## 4. Proteger um endpoint da API (Backend)

### Forma simples — verificação manual

```ts
// server/api/minha-feature/index.get.ts
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const user = await getUserFromEvent(event)
  if (!user) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // Verificação por nível numérico (rápido)
  if (user.permission > 1) {
    throw createError({ statusCode: 403, message: 'Forbidden' })
  }

  // ... lógica da API
})
```

### Forma avançada — `authorize()` middleware (RBAC)

```ts
// server/api/minha-feature/index.post.ts
import { authorize } from '~~/server/utils/authorize'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const user = await getUserFromEvent(event)
  if (!user) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // Verifica se o utilizador tem o código de permissão
  const ok = await authorize(event, ['SETTINGS:MANAGE_ROLES'])
  if (!ok) throw createError({ statusCode: 403, message: 'Forbidden' })

  // ... lógica da API
})
```

Ou com `hasUserPermission` para mais controlo:

```ts
import { hasUserPermission } from '~~/server/utils/authorize'

const hasAccess = await hasUserPermission(event, ['VACATION:APPROVE'], false) // false = qualquer um
```

---

## 5. Adicionar um novo código de permissão

### Passo 1 — Inserir na base de dados

```sql
INSERT INTO permissions (code, description, module, action)
VALUES ('NOVA_FEATURE:GERIR', 'Gerir Nova Feature', 'NOVA_FEATURE', 'GERIR');
```

### Passo 2 — Adicionar label no GroupForm

Em `app/components/permissions/GroupForm.vue`, o objeto `moduleLabels` e `moduleIcons` controlam a UI na matriz de permissões:

```ts
const moduleLabels: Record<string, string> = {
  VACATION: 'Férias',
  EQUIPMENT: 'Equipamentos',
  ROOMS: 'Salas de Reunião',
  SETTINGS: 'Definições',
  NOVA_FEATURE: 'Nova Feature',   // ← adicionar aqui
}

const moduleIcons: Record<string, string> = {
  NOVA_FEATURE: 'i-lucide-star',  // ← e aqui
}
```

### Passo 3 — Usar no frontend

```ts
const { can } = useRbac()
if (can('NOVA_FEATURE:GERIR')) { /* ... */ }
```

### Passo 4 — Usar no backend

```ts
const ok = await authorize(event, ['NOVA_FEATURE:GERIR'])
```

---

## 6. Adicionar permissão ao menu lateral

Em `app/layouts/default.vue`, os itens do menu são construídos dinamicamente com `useRbac()`:

```ts
if (can('NOVA_FEATURE:GERIR')) {
  mainLinks.push({
    label: 'Nova Feature',
    icon: 'i-lucide-star',
    to: '/nova-feature',
    onSelect: () => { open.value = false }
  })
}
```

---

## 7. Referência de ficheiros

| Ficheiro | Responsabilidade |
|---|---|
| `app/composables/useRbac.ts` | Composable principal RBAC (frontend) |
| `app/composables/usePermissions.ts` | Composable legacy numérico (frontend) |
| `app/utils/permissions.ts` | Constantes e funções utilitárias |
| `app/middleware/auth.global.ts` | Autenticação global (redireciona para /login) |
| `app/middleware/permissions.ts` | Guards de rota por permissão |
| `server/utils/authorize.ts` | Verificação de permissões no servidor |
| `server/utils/auth.ts` | `getUserFromEvent()` — ler utilizador do cookie JWT |
| `server/api/users/me/permissions.get.ts` | Endpoint que devolve códigos do utilizador atual |
| `server/api/permissions/index.get.ts` | Todos os códigos disponíveis no sistema |
