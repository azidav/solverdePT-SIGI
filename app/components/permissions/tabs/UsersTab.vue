<script setup lang="ts">
import { getPaginationRowModel } from '@tanstack/table-core'
import type { ColumnDef, Row } from '@tanstack/table-core'
import type { IUser } from '~/types/permissions'

const UButton = resolveComponent('UButton')
const UBadge = resolveComponent('UBadge')
const UDropdownMenu = resolveComponent('UDropdownMenu')
const UAvatar = resolveComponent('UAvatar')

const toast = useToast()

const loading = ref(false)
const allUsers = ref<IUser[]>([])
const usersTable = useTemplateRef('usersTable')
const pagination = ref({ pageIndex: 0, pageSize: 10 })

// Active (1) + Pending activation (2)
const activeUsers = computed(() => allUsers.value.filter(u => u.status >= 1))

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

async function resendActivation(user: IUser) {
  try {
    await useApiFetch(`/api/users/${user.id}/resend-activation`, { method: 'POST' })
    toast.add({ title: 'Email enviado', description: `Email de ativação reenviado para ${user.email}`, color: 'success' })
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao reenviar email de ativação', color: 'error' })
  }
}

async function toggleStatus(user: IUser) {
  // Active (1) or Pending (2) → Deactivate (0); Inactive (0) → Activate (1)
  const newStatus = user.status >= 1 ? 0 : 1
  try {
    await useApiFetch(`/api/users/${user.id}`, { method: 'PUT', body: { status: newStatus } })
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

function getRowItems(row: Row<IUser>) {
  const canDeactivate = row.original.status >= 1
  const isPending = row.original.status === 2

  const items: object[] = [
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
    }
  ]

  if (isPending) {
    items.push({ type: 'separator' as const })
    items.push({
      label: 'Reenviar email de ativação',
      icon: 'i-lucide-mail',
      onSelect: () => resendActivation(row.original)
    })
  }

  items.push({ type: 'separator' as const })
  items.push({
    label: canDeactivate ? 'Desativar' : 'Ativar',
    icon: canDeactivate ? 'i-lucide-user-x' : 'i-lucide-user-check',
    color: canDeactivate ? 'warning' as const : 'success' as const,
    onSelect: () => toggleStatus(row.original)
  })

  return items
}

const statusMap: Record<number, { label: string; color: 'success' | 'warning' | 'error' }> = {
  1: { label: 'Ativo', color: 'success' },
  2: { label: 'Pendente', color: 'warning' },
  0: { label: 'Inativo', color: 'error' },
}

const columns: ColumnDef<IUser>[] = [
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
    cell: ({ row }: { row: Row<IUser> }) => {
      const s = statusMap[row.original.status] || { label: 'Desconhecido', color: 'neutral' as const }
      return h(UBadge, { variant: 'subtle', color: s.color }, () => s.label)
    }
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
      <UButton
        label="Adicionar Utilizador"
        icon="i-lucide-plus"
        color="primary"
        @click="navigateTo('/permissions/users/new')"
      />
    </div>

    <UTable
      ref="usersTable"
      v-model:pagination="pagination"
      :pagination-options="{ getPaginationRowModel: getPaginationRowModel() }"
      :data="activeUsers"
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
</template>
