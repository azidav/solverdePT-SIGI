<script setup lang="ts">
import { getPaginationRowModel } from '@tanstack/table-core'
import type { ColumnDef, Row, Table } from '@tanstack/table-core'
import type { IUser } from '~/types/permissions'

const UButton = resolveComponent('UButton')
const UBadge = resolveComponent('UBadge')
const UDropdownMenu = resolveComponent('UDropdownMenu')
const UCheckbox = resolveComponent('UCheckbox')
const UAvatar = resolveComponent('UAvatar')

const toast = useToast()

const loading = ref(false)
const allUsers = ref<IUser[]>([])
const usersTable = useTemplateRef('usersTable')
const rowSelection = ref({})
const pagination = ref({ pageIndex: 0, pageSize: 10 })

const showDeleteModal = ref(false)
const userToDelete = ref<{ id: number; name: string }>({ id: 0, name: '' })

// Only deactivated accounts (status 0); pending (2) shows in the main Users tab
const inactiveUsers = computed(() => allUsers.value.filter(u => u.status === 0))

async function loadUsers() {
  loading.value = true
  try {
    const data = await useApiFetch('/api/users')
    allUsers.value = (data as IUser[]).map(u => ({
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

async function toggleStatus(user: IUser) {
  try {
    await useApiFetch(`/api/users/${user.id}`, { method: 'PUT', body: { status: 1 } })
    toast.add({ title: 'Sucesso', description: 'Utilizador ativado com sucesso', color: 'success' })
    await loadUsers()
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao alterar estado do utilizador', color: 'error' })
  }
}

function confirmDelete(user: IUser) {
  userToDelete.value = { id: user.id, name: user.name }
  showDeleteModal.value = true
}

async function executeDelete() {
  try {
    await useApiFetch('/api/users', { method: 'DELETE', body: { id: userToDelete.value.id } })
    toast.add({ title: 'Sucesso', description: 'Utilizador eliminado com sucesso', color: 'success' })
    showDeleteModal.value = false
    await loadUsers()
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : 'Erro ao eliminar utilizador'
    toast.add({ title: 'Erro', description: msg, color: 'error' })
  }
}

function getRowItems(row: Row<IUser>) {
  return [
    { type: 'label' as const, label: 'Ações' },
    {
      label: 'Editar',
      icon: 'i-lucide-edit',
      onSelect: () => navigateTo(`/permissions/users/${row.original.id}`)
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
      label: 'Ativar',
      icon: 'i-lucide-user-check',
      color: 'success' as const,
      onSelect: () => toggleStatus(row.original)
    },
    {
      label: 'Eliminar',
      icon: 'i-lucide-trash-2',
      color: 'error' as const,
      onSelect: () => confirmDelete(row.original)
    }
  ]
}

const columns: ColumnDef<IUser>[] = [
  {
    id: 'select',
    header: ({ table }: { table: Table<IUser> }) =>
      h(UCheckbox, {
        'modelValue': table.getIsSomePageRowsSelected() ? 'indeterminate' : table.getIsAllPageRowsSelected(),
        'onUpdate:modelValue': (value: boolean | 'indeterminate') => table.toggleAllPageRowsSelected(!!value),
        'ariaLabel': 'Selecionar tudo'
      }),
    cell: ({ row }: { row: Row<IUser> }) =>
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
    cell: ({ row }: { row: Row<IUser> }) =>
      h('div', { class: 'flex items-center gap-3' }, [
        h(UAvatar, { size: 'sm', alt: row.original.name }),
        h('span', {
          class: 'font-medium text-highlighted cursor-pointer hover:underline',
          onClick: () => navigateTo(`/permissions/users/${row.original.id}`)
        }, row.original.username || row.original.email)
      ])
  },
  {
    accessorKey: 'first_name',
    header: 'Primeiro Nome',
    cell: ({ row }: { row: Row<IUser> }) => row.original.first_name || '-'
  },
  {
    accessorKey: 'last_name',
    header: 'Último Nome',
    cell: ({ row }: { row: Row<IUser> }) => row.original.last_name || '-'
  },
  {
    accessorKey: 'roles',
    header: 'Grupos',
    cell: ({ row }: { row: Row<IUser> }) => {
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
    cell: () => h(UBadge, { variant: 'subtle', color: 'error' }, () => 'Inativo')
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }: { row: Row<IUser> }) =>
      h('div', { class: 'text-right' },
        h(UDropdownMenu, { content: { align: 'end' }, items: getRowItems(row) },
          () => h(UButton, { icon: 'i-lucide-ellipsis-vertical', color: 'neutral', variant: 'ghost' })
        )
      )
  }
]

onMounted(loadUsers)
</script>

<template>
  <div class="space-y-4 pt-4">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <UInput
        :model-value="(usersTable?.tableApi?.getColumn('username')?.getFilterValue() as string)"
        class="max-w-sm"
        icon="i-lucide-search"
        placeholder="Pesquisar por username..."
        @update:model-value="usersTable?.tableApi?.getColumn('username')?.setFilterValue($event)"
      />
    </div>

    <UTable
      ref="usersTable"
      v-model:row-selection="rowSelection"
      v-model:pagination="pagination"
      :pagination-options="{ getPaginationRowModel: getPaginationRowModel() }"
      :data="inactiveUsers"
      :columns="columns"
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

  <UModal v-model:open="showDeleteModal" title="Eliminar Utilizador">
    <template #body>
      <div class="space-y-4">
        <p>
          Tem a certeza que deseja eliminar o utilizador
          <span class="font-semibold">{{ userToDelete.name }}</span>?
          O utilizador ficará na lista de eliminados e não poderá ser restaurado.
        </p>
        <div class="flex justify-end gap-2 pt-2">
          <UButton label="Cancelar" color="neutral" variant="subtle" @click="showDeleteModal = false" />
          <UButton label="Eliminar" color="error" icon="i-lucide-trash-2" @click="executeDelete" />
        </div>
      </div>
    </template>
  </UModal>
</template>
