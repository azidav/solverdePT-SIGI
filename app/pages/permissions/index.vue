<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import { getPaginationRowModel } from '@tanstack/table-core'
import type { Row } from '@tanstack/table-core'

definePageMeta({
  title: 'Roles & Permissões'
})

const UButton = resolveComponent('UButton')
const UBadge = resolveComponent('UBadge')
const UDropdownMenu = resolveComponent('UDropdownMenu')
const UCheckbox = resolveComponent('UCheckbox')
const UAvatar = resolveComponent('UAvatar')

const toast = useToast()

// ============================================
// Interfaces
// ============================================
interface IGroup {
  id: number
  name: string
  description: string
  is_system: boolean
  users_count: number
  users: { id: number; name: string; email: string }[]
  modified_at: string
  modified_by: string
  created_at: string
  updated_at: string
}

interface IUser {
  id: number
  username: string
  name: string
  first_name: string
  last_name: string
  email: string
  role_id: number
  role_name: string
  status: number
  modified_at: string
  modified_by: string
  avatar?: { src?: string; alt?: string }
  roles: { id: number; name: string }[]
}

// ============================================
// State
// ============================================
const loading = ref(false)

// Groups data
const groups = ref<IGroup[]>([])
const groupsTable = useTemplateRef('groupsTable')
const groupRowSelection = ref({})

// Users data
const users = ref<IUser[]>([])
const usersTable = useTemplateRef('usersTable')
const userRowSelection = ref({})

// Pagination
const groupsPagination = ref({ pageIndex: 0, pageSize: 10 })
const usersPagination = ref({ pageIndex: 0, pageSize: 10 })

// Modals
const showGroupModal = ref(false)
const showUserModal = ref(false)
const showDeleteGroupModal = ref(false)
const editingGroup = ref<IGroup | null>(null)
const editingUser = ref<IUser | null>(null)
const groupToDelete = ref<{ id: number; name: string; usersCount: number }>({ id: 0, name: '', usersCount: 0 })

// ============================================
// Tabs
// ============================================
const tabs = [
  { label: 'Grupos', icon: 'i-lucide-users', slot: 'groups' },
  { label: 'Utilizadores', icon: 'i-lucide-user', slot: 'users' },
  { label: 'Utilizadores Desativados', icon: 'i-lucide-user-x', slot: 'disabled' }
]

// ============================================
// Computed: Filtered Data
// ============================================
const activeUsers = computed(() => users.value.filter(u => u.status === 1))
const disabledUsers = computed(() => users.value.filter(u => u.status !== 1))

// ============================================
// API Calls
// ============================================
async function loadGroups() {
  loading.value = true
  try {
    const data = await useApiFetch('/api/roles')
    groups.value = (data as IGroup[]).map(g => ({
      ...g,
      modified_at: g.updated_at || g.created_at || '',
      modified_by: 'Sistema'
    }))
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar grupos', color: 'error' })
  } finally {
    loading.value = false
  }
}

async function loadUsers() {
  loading.value = true
  try {
    const data = await useApiFetch('/api/users')
    users.value = (data as IUser[]).map(u => ({
      ...u,
      first_name: u.name?.split(' ')[0] || '',
      last_name: u.name?.split(' ').slice(1).join(' ') || '',
      modified_at: '',
      modified_by: '',
      roles: u.roles || []
    }))
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar utilizadores', color: 'error' })
  } finally {
    loading.value = false
  }
}

async function loadAllData() {
  await Promise.all([loadGroups(), loadUsers()])
}

// ============================================
// Group Actions
// ============================================
function openAddGroup() {
  editingGroup.value = null
  showGroupModal.value = true
}

function openEditGroup(group: IGroup) {
  editingGroup.value = { ...group }
  showGroupModal.value = true
}

function confirmDeleteGroup(group: IGroup) {
  groupToDelete.value = { id: group.id, name: group.name, usersCount: group.users_count || 0 }
  showDeleteGroupModal.value = true
}

async function executeDeleteGroup() {
  if (groupToDelete.value.usersCount > 0) {
    toast.add({
      title: 'Não é possível eliminar',
      description: `Este grupo tem ${groupToDelete.value.usersCount} utilizador(es) associado(s). Remova-os primeiro.`,
      color: 'warning'
    })
    showDeleteGroupModal.value = false
    return
  }

  try {
    await useApiFetch(`/api/roles/${groupToDelete.value.id}`, { method: 'DELETE' })
    toast.add({ title: 'Sucesso', description: 'Grupo eliminado com sucesso', color: 'success' })
    showDeleteGroupModal.value = false
    await loadGroups()
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : 'Erro ao eliminar grupo'
    toast.add({ title: 'Erro', description: msg, color: 'error' })
  }
}

// ============================================
// User Actions
// ============================================
function openAddUser() {
  editingUser.value = null
  showUserModal.value = true
}

function openEditUser(user: IUser) {
  editingUser.value = { ...user }
  showUserModal.value = true
}

// ============================================
// Table Columns: Groups
// ============================================
function getGroupRowItems(row: Row<IGroup>) {
  return [
    { type: 'label' as const, label: 'Ações' },
    {
      label: 'Editar',
      icon: 'i-lucide-edit',
      onSelect: () => openEditGroup(row.original)
    },
    { type: 'separator' as const },
    {
      label: 'Eliminar',
      icon: 'i-lucide-trash-2',
      color: 'error' as const,
      disabled: row.original.is_system,
      onSelect: () => confirmDeleteGroup(row.original)
    }
  ]
}

const groupColumns: TableColumn<IGroup>[] = [
  {
    id: 'select',
    header: ({ table }) =>
      h(UCheckbox, {
        'modelValue': table.getIsSomePageRowsSelected()
          ? 'indeterminate'
          : table.getIsAllPageRowsSelected(),
        'onUpdate:modelValue': (value: boolean | 'indeterminate') =>
          table.toggleAllPageRowsSelected(!!value),
        'ariaLabel': 'Selecionar tudo'
      }),
    cell: ({ row }) =>
      h(UCheckbox, {
        'modelValue': row.getIsSelected(),
        'onUpdate:modelValue': (value: boolean | 'indeterminate') => row.toggleSelected(!!value),
        'ariaLabel': 'Selecionar linha'
      })
  },
  {
    accessorKey: 'name',
    header: 'Nome',
    enableColumnFilter: true,
    filterFn: 'includesString',
    cell: ({ row }) => {
      return h('div', { class: 'flex items-center gap-2' }, [
        h('span', { class: 'font-medium text-highlighted cursor-pointer hover:underline', onClick: () => openEditGroup(row.original) }, row.original.name),
        row.original.is_system ? h(UBadge, { variant: 'subtle', color: 'info', size: 'xs' }, () => 'Sistema') : null
      ])
    }
  },
  {
    accessorKey: 'description',
    header: 'Descrição',
    cell: ({ row }) => h('span', { class: 'text-muted' }, row.original.description || '-')
  },
  {
    accessorKey: 'users_count',
    header: 'Utilizadores',
    cell: ({ row }) => {
      return h(UBadge, { variant: 'subtle', color: 'neutral' }, () => row.original.users_count.toString())
    }
  },
  {
    accessorKey: 'modified_at',
    header: 'Modificado',
    cell: ({ row }) => formatDate(row.original.modified_at || row.original.created_at)
  },
  {
    accessorKey: 'modified_by',
    header: 'Modificado por',
    cell: ({ row }) => row.original.modified_by || '-'
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }) => {
      return h(
        'div',
        { class: 'text-right' },
        h(
          UDropdownMenu,
          { content: { align: 'end' }, items: getGroupRowItems(row) },
          () => h(UButton, { icon: 'i-lucide-ellipsis-vertical', color: 'neutral', variant: 'ghost' })
        )
      )
    }
  }
]

// ============================================
// Table Columns: Users
// ============================================
function getUserRowItems(row: Row<IUser>) {
  return [
    { type: 'label' as const, label: 'Ações' },
    {
      label: 'Editar',
      icon: 'i-lucide-edit',
      onSelect: () => openEditUser(row.original)
    },
    {
      label: 'Copiar Email',
      icon: 'i-lucide-copy',
      onSelect: () => {
        navigator.clipboard.writeText(row.original.email)
        toast.add({ title: 'Copiado', description: 'Email copiado para a área de transferência' })
      }
    },
    { type: 'separator' as const },
    {
      label: row.original.status === 1 ? 'Desativar' : 'Ativar',
      icon: row.original.status === 1 ? 'i-lucide-user-x' : 'i-lucide-user-check',
      color: row.original.status === 1 ? 'warning' as const : 'success' as const,
      onSelect: () => toggleUserStatus(row.original)
    }
  ]
}

async function toggleUserStatus(user: IUser) {
  const newStatus = user.status === 1 ? 0 : 1
  try {
    await useApiFetch(`/api/users/${user.id}`, {
      method: 'PUT',
      body: { status: newStatus }
    })
    toast.add({
      title: 'Sucesso',
      description: `Utilizador ${newStatus === 1 ? 'ativado' : 'desativado'} com sucesso`,
      color: 'success'
    })
    await loadUsers()
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao alterar estado do utilizador', color: 'error' })
  }
}

const userColumns: TableColumn<IUser>[] = [
  {
    id: 'select',
    header: ({ table }) =>
      h(UCheckbox, {
        'modelValue': table.getIsSomePageRowsSelected()
          ? 'indeterminate'
          : table.getIsAllPageRowsSelected(),
        'onUpdate:modelValue': (value: boolean | 'indeterminate') =>
          table.toggleAllPageRowsSelected(!!value),
        'ariaLabel': 'Selecionar tudo'
      }),
    cell: ({ row }) =>
      h(UCheckbox, {
        'modelValue': row.getIsSelected(),
        'onUpdate:modelValue': (value: boolean | 'indeterminate') => row.toggleSelected(!!value),
        'ariaLabel': 'Selecionar linha'
      })
  },
  {
    accessorKey: 'username',
    header: 'Username',
    enableColumnFilter: true,
    filterFn: 'includesString',
    cell: ({ row }) => {
      return h('div', { class: 'flex items-center gap-3' }, [
        h(UAvatar, { size: 'sm', alt: row.original.name }),
        h('span', { class: 'font-medium text-highlighted cursor-pointer hover:underline', onClick: () => openEditUser(row.original) }, row.original.username || row.original.email)
      ])
    }
  },
  {
    accessorKey: 'first_name',
    header: 'Primeiro Nome',
    cell: ({ row }) => row.original.first_name || '-'
  },
  {
    accessorKey: 'last_name',
    header: 'Último Nome',
    cell: ({ row }) => row.original.last_name || '-'
  },
  {
    accessorKey: 'roles',
    header: 'Grupos',
    cell: ({ row }) => {
      const roles = row.original.roles || []
      if (roles.length > 0) {
        return h('div', { class: 'flex flex-wrap gap-1' },
          roles.map((r: { id: number; name: string }) =>
            h(UBadge, { variant: 'subtle', color: 'primary', size: 'xs', key: r.id }, () => r.name)
          )
        )
      }
      return h('span', { class: 'text-muted' }, '-')
    }
  },
  {
    accessorKey: 'status',
    header: 'Estado',
    cell: ({ row }) => {
      const statusMap: Record<number, { label: string; color: 'success' | 'warning' | 'error' }> = {
        1: { label: 'Ativo', color: 'success' },
        0: { label: 'Pendente', color: 'warning' },
        [-1]: { label: 'Desativado', color: 'error' }
      }
      const status = statusMap[row.original.status] || { label: 'Desconhecido', color: 'neutral' as const }
      return h(UBadge, { variant: 'subtle', color: status.color }, () => status.label)
    }
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }) => {
      return h(
        'div',
        { class: 'text-right' },
        h(
          UDropdownMenu,
          { content: { align: 'end' }, items: getUserRowItems(row) },
          () => h(UButton, { icon: 'i-lucide-ellipsis-vertical', color: 'neutral', variant: 'ghost' })
        )
      )
    }
  }
]

// ============================================
// Helpers
// ============================================
function formatDate(date: string | undefined) {
  if (!date) return '-'
  return new Date(date).toLocaleDateString('pt-PT', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  })
}

// ============================================
// Lifecycle
// ============================================
onMounted(() => {
  loadAllData()
})
</script>

<template>
  <UDashboardPanel id="permissions">
    <template #header>
      <UDashboardNavbar title="Roles & Permissões">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <UTabs :items="tabs" class="w-full">
        <!-- ========== TAB: GRUPOS ========== -->
        <template #groups>
          <div class="space-y-4 pt-4">
            <!-- Toolbar -->
            <div class="flex flex-wrap items-center justify-between gap-3">
              <UInput
                :model-value="(groupsTable?.tableApi?.getColumn('name')?.getFilterValue() as string)"
                class="max-w-sm"
                icon="i-lucide-search"
                placeholder="Pesquisar por nome..."
                @update:model-value="groupsTable?.tableApi?.getColumn('name')?.setFilterValue($event)"
              />

              <UButton
                label="Adicionar Grupo"
                icon="i-lucide-plus"
                color="primary"
                @click="openAddGroup"
              />
            </div>

            <!-- Table -->
            <UTable
              ref="groupsTable"
              v-model:row-selection="groupRowSelection"
              v-model:pagination="groupsPagination"
              :pagination-options="{ getPaginationRowModel: getPaginationRowModel() }"
              :data="groups"
              :columns="groupColumns"
              :loading="loading"
              :ui="{
                base: 'table-fixed border-separate border-spacing-0',
                thead: '[&>tr]:bg-elevated/50 [&>tr]:after:content-none',
                tbody: '[&>tr]:last:[&>td]:border-b-0',
                th: 'py-2 first:rounded-l-lg last:rounded-r-lg border-y border-default first:border-l last:border-r',
                td: 'border-b border-default',
                separator: 'h-0'
              }"
            />

            <!-- Pagination -->
            <div class="flex items-center justify-between gap-3 border-t border-default pt-4">
              <div class="text-sm text-muted">
                {{ groupsTable?.tableApi?.getFilteredSelectedRowModel().rows.length || 0 }} de
                {{ groupsTable?.tableApi?.getFilteredRowModel().rows.length || 0 }} linha(s) selecionada(s).
              </div>
              <UPagination
                :default-page="(groupsTable?.tableApi?.getState().pagination.pageIndex || 0) + 1"
                :items-per-page="groupsTable?.tableApi?.getState().pagination.pageSize"
                :total="groupsTable?.tableApi?.getFilteredRowModel().rows.length"
                @update:page="(p: number) => groupsTable?.tableApi?.setPageIndex(p - 1)"
              />
            </div>
          </div>
        </template>

        <!-- ========== TAB: UTILIZADORES ========== -->
        <template #users>
          <div class="space-y-4 pt-4">
            <!-- Toolbar -->
            <div class="flex flex-wrap items-center justify-between gap-3">
              <UInput
                :model-value="(usersTable?.tableApi?.getColumn('username')?.getFilterValue() as string)"
                class="max-w-sm"
                icon="i-lucide-search"
                placeholder="Pesquisar por username..."
                @update:model-value="usersTable?.tableApi?.getColumn('username')?.setFilterValue($event)"
              />

              <UButton
                label="Adicionar Utilizador"
                icon="i-lucide-plus"
                color="primary"
                @click="openAddUser"
              />
            </div>

            <!-- Table -->
            <UTable
              ref="usersTable"
              v-model:row-selection="userRowSelection"
              v-model:pagination="usersPagination"
              :pagination-options="{ getPaginationRowModel: getPaginationRowModel() }"
              :data="activeUsers"
              :columns="userColumns"
              :loading="loading"
              :ui="{
                base: 'table-fixed border-separate border-spacing-0',
                thead: '[&>tr]:bg-elevated/50 [&>tr]:after:content-none',
                tbody: '[&>tr]:last:[&>td]:border-b-0',
                th: 'py-2 first:rounded-l-lg last:rounded-r-lg border-y border-default first:border-l last:border-r',
                td: 'border-b border-default',
                separator: 'h-0'
              }"
            />

            <!-- Pagination -->
            <div class="flex items-center justify-between gap-3 border-t border-default pt-4">
              <div class="text-sm text-muted">
                {{ usersTable?.tableApi?.getFilteredSelectedRowModel().rows.length || 0 }} de
                {{ usersTable?.tableApi?.getFilteredRowModel().rows.length || 0 }} linha(s) selecionada(s).
              </div>
              <UPagination
                :default-page="(usersTable?.tableApi?.getState().pagination.pageIndex || 0) + 1"
                :items-per-page="usersTable?.tableApi?.getState().pagination.pageSize"
                :total="usersTable?.tableApi?.getFilteredRowModel().rows.length"
                @update:page="(p: number) => usersTable?.tableApi?.setPageIndex(p - 1)"
              />
            </div>
          </div>
        </template>

        <!-- ========== TAB: UTILIZADORES DESATIVADOS ========== -->
        <template #disabled>
          <div class="space-y-4 pt-4">
            <!-- Toolbar -->
            <div class="flex flex-wrap items-center justify-between gap-3">
              <UInput
                class="max-w-sm"
                icon="i-lucide-search"
                placeholder="Pesquisar por username..."
              />
            </div>

            <!-- Table -->
            <UTable
              :data="disabledUsers"
              :columns="userColumns"
              :loading="loading"
              :ui="{
                base: 'table-fixed border-separate border-spacing-0',
                thead: '[&>tr]:bg-elevated/50 [&>tr]:after:content-none',
                tbody: '[&>tr]:last:[&>td]:border-b-0',
                th: 'py-2 first:rounded-l-lg last:rounded-r-lg border-y border-default first:border-l last:border-r',
                td: 'border-b border-default',
                separator: 'h-0'
              }"
            />
          </div>
        </template>
      </UTabs>
    </template>
  </UDashboardPanel>

  <!-- ========== MODAL: Criar/Editar Grupo ========== -->
  <UModal v-model:open="showGroupModal" :title="editingGroup ? 'Editar Grupo' : 'Novo Grupo'">
    <template #body>
      <PermissionsGroupForm
        :group="editingGroup"
        :users="users"
        @cancel="showGroupModal = false"
        @saved="showGroupModal = false; loadAllData()"
      />
    </template>
  </UModal>

  <!-- ========== MODAL: Criar/Editar Utilizador ========== -->
  <UModal v-model:open="showUserModal" :title="editingUser ? 'Editar Utilizador' : 'Novo Utilizador'">
    <template #body>
      <PermissionsUserForm
        :user="editingUser"
        :groups="groups"
        @cancel="showUserModal = false"
        @saved="showUserModal = false; loadUsers()"
      />
    </template>
  </UModal>

  <!-- ========== MODAL: Confirmar Eliminação de Grupo ========== -->
  <UModal v-model:open="showDeleteGroupModal" title="Confirmar Eliminação">
    <template #body>
      <div class="space-y-4">
        <p>
          Tem a certeza que deseja eliminar o grupo
          <span class="font-semibold">{{ groupToDelete.name }}</span>?
        </p>

        <div v-if="groupToDelete.usersCount > 0" class="p-3 bg-warning-50 dark:bg-warning-900/20 rounded-lg border border-warning-200 dark:border-warning-800">
          <p class="text-sm text-warning-700 dark:text-warning-300 flex items-center gap-2">
            <UIcon name="i-lucide-info" class="size-4" />
            Este grupo tem <strong>{{ groupToDelete.usersCount }}</strong> utilizador(es) associado(s).
            Remova-os primeiro antes de eliminar o grupo.
          </p>
        </div>

        <div class="flex justify-end gap-2 pt-4">
          <UButton
            label="Cancelar"
            color="neutral"
            variant="subtle"
            @click="showDeleteGroupModal = false"
          />
          <UButton
            label="Eliminar"
            color="error"
            :disabled="groupToDelete.usersCount > 0"
            @click="executeDeleteGroup"
          />
        </div>
      </div>
    </template>
  </UModal>
</template>
