<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import { getPaginationRowModel } from '@tanstack/table-core'
import type { Row } from '@tanstack/table-core'
import type { IUser } from '~/types/permissions'

const UButton = resolveComponent('UButton')
const UDropdownMenu = resolveComponent('UDropdownMenu')
const UAvatar = resolveComponent('UAvatar')

const toast = useToast()

const loading = ref(false)
const deletedUsers = ref<IUser[]>([])
const usersTable = useTemplateRef('usersTable')
const pagination = ref({ pageIndex: 0, pageSize: 10 })

const showDeleteModal = ref(false)
const userToDelete = ref<{ id: number; name: string }>({ id: 0, name: '' })

async function loadDeletedUsers() {
  loading.value = true
  try {
    const data = await useApiFetch('/api/users/deleted')
    deletedUsers.value = (data as IUser[]).map(u => ({
      ...u,
      first_name: u.name?.split(' ')[0] || '',
      last_name: u.name?.split(' ').slice(1).join(' ') || '',
      modified_at: u.updated_at || '',
      modified_by: '',
      roles: u.roles || []
    }))
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar utilizadores eliminados', color: 'error' })
  } finally {
    loading.value = false
  }
}

function confirmDelete(user: IUser) {
  userToDelete.value = { id: user.id, name: user.name }
  showDeleteModal.value = true
}

async function executeDelete() {
  try {
    await useApiFetch(`/api/users/${userToDelete.value.id}`, { method: 'DELETE' })
    toast.add({ title: 'Sucesso', description: 'Utilizador eliminado permanentemente', color: 'success' })
    showDeleteModal.value = false
    await loadDeletedUsers()
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : 'Erro ao eliminar utilizador'
    toast.add({ title: 'Erro', description: msg, color: 'error' })
  }
}

function formatDate(date: string | undefined) {
  if (!date) return '-'
  return new Date(date).toLocaleDateString('pt-PT', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

function getRowItems(row: Row<IUser>) {
  return [
    { type: 'label' as const, label: 'Ações' },
    {
      label: 'Eliminar Permanentemente',
      icon: 'i-lucide-trash-2',
      color: 'error' as const,
      onSelect: () => confirmDelete(row.original)
    }
  ]
}

const columns: TableColumn<IUser>[] = [
  {
    accessorKey: 'username',
    header: 'Username',
    enableColumnFilter: true,
    filterFn: 'includesString',
    cell: ({ row }) =>
      h('div', { class: 'flex items-center gap-3' }, [
        h(UAvatar, { size: 'sm', alt: row.original.name }),
        h('span', { class: 'font-medium text-highlighted' }, row.original.username || row.original.email)
      ])
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
    accessorKey: 'email',
    header: 'Email',
    cell: ({ row }) => h('span', { class: 'text-muted' }, row.original.email)
  },
  {
    accessorKey: 'modified_at',
    header: 'Eliminado em',
    cell: ({ row }) => formatDate(row.original.modified_at)
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }) =>
      h('div', { class: 'text-right' },
        h(UDropdownMenu, { content: { align: 'end' }, items: getRowItems(row) },
          () => h(UButton, { icon: 'i-lucide-ellipsis-vertical', color: 'neutral', variant: 'ghost' })
        )
      )
  }
]

onMounted(loadDeletedUsers)
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
      v-model:pagination="pagination"
      :pagination-options="{ getPaginationRowModel: getPaginationRowModel() }"
      :data="deletedUsers"
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

    <div class="flex justify-end border-t border-default pt-4">
      <UPagination
        :default-page="(usersTable?.tableApi?.getState().pagination.pageIndex || 0) + 1"
        :items-per-page="usersTable?.tableApi?.getState().pagination.pageSize"
        :total="usersTable?.tableApi?.getFilteredRowModel().rows.length"
        @update:page="(p: number) => usersTable?.tableApi?.setPageIndex(p - 1)"
      />
    </div>
  </div>

  <UModal v-model:open="showDeleteModal" title="Eliminar Permanentemente">
    <template #body>
      <div class="space-y-4">
        <p>
          Tem a certeza que deseja eliminar permanentemente o utilizador
          <span class="font-semibold">{{ userToDelete.name }}</span>?
        </p>
        <div class="p-3 bg-error-50 dark:bg-error-900/20 rounded-lg border border-error-200 dark:border-error-800">
          <p class="text-sm text-error-700 dark:text-error-300 flex items-center gap-2">
            <UIcon name="i-lucide-alert-triangle" class="size-4" />
            Esta ação é irreversível. Todos os dados do utilizador serão eliminados definitivamente.
          </p>
        </div>
        <div class="flex justify-end gap-2 pt-4">
          <UButton label="Cancelar" color="neutral" variant="subtle" @click="showDeleteModal = false" />
          <UButton label="Eliminar Permanentemente" color="error" @click="executeDelete" />
        </div>
      </div>
    </template>
  </UModal>
</template>
