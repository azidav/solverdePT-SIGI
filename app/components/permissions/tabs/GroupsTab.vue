<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import { getPaginationRowModel } from '@tanstack/table-core'
import type { Row } from '@tanstack/table-core'
import type { IGroup } from '~/types/permissions'

const UButton = resolveComponent('UButton')
const UBadge = resolveComponent('UBadge')
const UDropdownMenu = resolveComponent('UDropdownMenu')

const toast = useToast()

const loading = ref(false)
const groups = ref<IGroup[]>([])
const groupsTable = useTemplateRef('groupsTable')
const pagination = ref({ pageIndex: 0, pageSize: 10 })

const showDeleteModal = ref(false)
const groupToDelete = ref<{ id: number; name: string; usersCount: number }>({ id: 0, name: '', usersCount: 0 })

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

function confirmDelete(group: IGroup) {
  groupToDelete.value = { id: group.id, name: group.name, usersCount: group.users_count || 0 }
  showDeleteModal.value = true
}

async function executeDelete() {
  if (groupToDelete.value.usersCount > 0) {
    toast.add({
      title: 'Não é possível eliminar',
      description: `Este grupo tem ${groupToDelete.value.usersCount} utilizador(es) associado(s). Remova-os primeiro.`,
      color: 'warning'
    })
    showDeleteModal.value = false
    return
  }
  try {
    await useApiFetch(`/api/roles/${groupToDelete.value.id}`, { method: 'DELETE' })
    toast.add({ title: 'Sucesso', description: 'Grupo eliminado com sucesso', color: 'success' })
    showDeleteModal.value = false
    await loadGroups()
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : 'Erro ao eliminar grupo'
    toast.add({ title: 'Erro', description: msg, color: 'error' })
  }
}

function formatDate(date: string | undefined) {
  if (!date) return '-'
  return new Date(date).toLocaleDateString('pt-PT', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

function getRowItems(row: Row<IGroup>) {
  return [
    { type: 'label' as const, label: 'Ações' },
    {
      label: 'Editar',
      icon: 'i-lucide-edit',
      onSelect: () => navigateTo(`/permissions/groups/${row.original.id}`)
    },
    { type: 'separator' as const },
    {
      label: 'Eliminar',
      icon: 'i-lucide-trash-2',
      color: 'error' as const,
      disabled: row.original.is_system,
      onSelect: () => confirmDelete(row.original)
    }
  ]
}

const columns: TableColumn<IGroup>[] = [
  {
    accessorKey: 'name',
    header: 'Nome',
    enableColumnFilter: true,
    filterFn: 'includesString',
    cell: ({ row }) =>
      h('div', { class: 'flex items-center gap-2' }, [
        h('span', {
          class: 'font-medium text-highlighted cursor-pointer hover:underline',
          onClick: () => navigateTo(`/permissions/groups/${row.original.id}`)
        }, row.original.name),
        row.original.is_system ? h(UBadge, { variant: 'subtle', color: 'info', size: 'xs' }, () => 'Sistema') : null
      ])
  },
  {
    accessorKey: 'description',
    header: 'Descrição',
    cell: ({ row }) => h('span', { class: 'text-muted' }, row.original.description || '-')
  },
  {
    accessorKey: 'users_count',
    header: 'Utilizadores',
    cell: ({ row }) => h(UBadge, { variant: 'subtle', color: 'neutral' }, () => row.original.users_count.toString())
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
    cell: ({ row }) =>
      h('div', { class: 'text-right' },
        h(UDropdownMenu, { content: { align: 'end' }, items: getRowItems(row) },
          () => h(UButton, { icon: 'i-lucide-ellipsis-vertical', color: 'neutral', variant: 'ghost' })
        )
      )
  }
]

onMounted(loadGroups)
</script>

<template>
  <div class="space-y-4 pt-4">
    <UInput
      :model-value="(groupsTable?.tableApi?.getColumn('name')?.getFilterValue() as string)"
      class="max-w-sm"
      icon="i-lucide-search"
      placeholder="Pesquisar por nome..."
      @update:model-value="groupsTable?.tableApi?.getColumn('name')?.setFilterValue($event)"
    />

    <UTable
      ref="groupsTable"
      v-model:pagination="pagination"
      :pagination-options="{ getPaginationRowModel: getPaginationRowModel() }"
      :data="groups"
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
        :default-page="(groupsTable?.tableApi?.getState().pagination.pageIndex || 0) + 1"
        :items-per-page="groupsTable?.tableApi?.getState().pagination.pageSize"
        :total="groupsTable?.tableApi?.getFilteredRowModel().rows.length"
        @update:page="(p: number) => groupsTable?.tableApi?.setPageIndex(p - 1)"
      />
    </div>
  </div>

  <UModal v-model:open="showDeleteModal" title="Confirmar Eliminação">
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
          <UButton label="Cancelar" color="neutral" variant="subtle" @click="showDeleteModal = false" />
          <UButton
            label="Eliminar"
            color="error"
            :disabled="groupToDelete.usersCount > 0"
            @click="executeDelete"
          />
        </div>
      </div>
    </template>
  </UModal>
</template>
