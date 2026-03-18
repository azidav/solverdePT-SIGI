<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import { getPaginationRowModel } from '@tanstack/table-core'
import type { Row } from '@tanstack/table-core'
import { h } from 'vue'

// Resolve UI components used in render functions
const UButton = resolveComponent('UButton')
const UDropdownMenu = resolveComponent('UDropdownMenu')
const UCheckbox = resolveComponent('UCheckbox')

definePageMeta({ middleware: 'permissions' })

interface Role {
  id: number
  name: string
  date_creation: string
  subrole_count?: number
}

const toast = useToast()
const table = useTemplateRef('table')
const popupStore = usePopupStore()

const columnFilters = ref([{ id: 'name', value: '' }])
const columnVisibility = ref()
const rowSelection = ref({})
const pagination = ref({ pageIndex: 0, pageSize: 10 })

const data = ref<Role[]>([])
const status = ref<'pending' | 'success' | 'error'>('pending')

async function refreshRoles() {
  status.value = 'pending'
  try {
    const [rolesData, subrolesData] = await Promise.all([
      $fetch<Role[]>('/api/roles'),
      $fetch<Array<{ role_id: number }>>('/api/subroles')
    ])

    const roles = rolesData || []
    const subroles = subrolesData || []

    data.value = roles.map(role => ({
      ...role,
      subrole_count: subroles.filter(s => s.role_id === role.id).length
    }))
    status.value = 'success'
  } catch (error) {
    console.error('Error loading roles:', error)
    status.value = 'error'
    toast.add({
      title: 'Erro ao carregar dados',
      description: 'Não foi possível carregar os cargos.',
      color: 'error'
    })
  }
}

onMounted(refreshRoles)

function openDeleteModal(role: Role) {
  popupStore.open({
    type: 'delete',
    title: 'Eliminar Cargo',
    content: `Tem a certeza que deseja eliminar o cargo <strong>${role.name}</strong>?<br><span class="text-sm">Esta ação não pode ser revertida.</span>`,
    onAccept: async () => {
      try {
        await useApiFetch(`/api/roles/${role.id}`, { method: 'DELETE' })
        toast.add({
          title: 'Cargo eliminado',
          description: 'O cargo foi eliminado com sucesso.',
          color: 'success'
        })
        refreshRoles()
      } catch {
        toast.add({
          title: 'Erro ao eliminar',
          description: 'Não foi possível eliminar o cargo.',
          color: 'error'
        })
      }
    }
  })
}

const columns: TableColumn<Role>[] = [
  {
    id: 'select',
    header: ({ table }) =>
      h(UCheckbox, {
        'modelValue': table.getIsSomePageRowsSelected()
          ? 'indeterminate'
          : table.getIsAllPageRowsSelected(),
        'onUpdate:modelValue': (value: boolean | 'indeterminate') =>
          table.toggleAllPageRowsSelected(!!value),
        'ariaLabel': 'Selecionar todos'
      }),
    cell: ({ row }) =>
      h(UCheckbox, {
        'modelValue': row.getIsSelected(),
        'onUpdate:modelValue': (value: boolean | 'indeterminate') => row.toggleSelected(!!value),
        'ariaLabel': 'Selecionar linha'
      })
  },
  {
    accessorKey: 'id',
    header: 'ID'
  },
  {
    accessorKey: 'name',
    header: 'Nome',
    enableColumnFilter: true,
    filterFn: (row: Row<Role>, columnId: string, filterValue: string) => {
      if (!filterValue) return true
      const searchValue = filterValue.toLowerCase()
      const name = String(row.getValue(columnId) ?? '').toLowerCase()
      return name.includes(searchValue)
    },
    cell: ({ row }) => {
      return h('div', { class: 'flex items-center gap-3' }, [
        h('p', { class: 'font-medium text-highlighted' }, row.original.name),
        h('p', { class: 'text-sm text-muted' }, `${row.original.subrole_count ?? 0} sub-cargos`)
      ])
    }
  },
  {
    accessorKey: 'subrole_count',
    header: 'Sub-cargos',
    cell: ({ row }) => h('div', { class: 'flex items-center' }, [
      h(UButton, {
        'size': 'xs',
        'variant': 'soft',
        'color': 'neutral',
        'class': 'px-2',
        'label': 'Ver Sub-cargos',
        'icon': 'i-lucide-list',
        'to': `/users/roles/${row.original.id}/subroles`,
        'aria-label': `Ver sub-cargos de ${row.original.name}`
      })
    ])
  },
  {
    accessorKey: 'date_creation',
    header: 'Data de Criação',
    cell: ({ row }) => new Date(row.original.date_creation).toLocaleDateString('pt-PT')
  },
  {
    id: 'actions',
    cell: ({ row }) => {
      return h(
        'div',
        { class: 'text-right' },
        h(
          UDropdownMenu,
          {
            content: { align: 'end' },
            items: getRowItems(row)
          },
          () => h(UButton, {
            icon: 'i-lucide-ellipsis-vertical',
            color: 'neutral',
            variant: 'ghost',
            class: 'ml-auto'
          })
        )
      )
    }
  }
]

function getRowItems(row: Row<Role>) {
  return [
    { type: 'label', label: 'Ações' },
    { label: 'Editar', icon: 'i-lucide-pencil', to: `/users/roles/${row.original.id}` },
    { type: 'separator' },
    { label: 'Eliminar', icon: 'i-lucide-trash-2', color: 'error', onSelect: () => openDeleteModal(row.original) }
  ]
}

function openBulkDeleteModal() {
  const selected: Array<Row<Role>> = table?.value?.tableApi?.getFilteredSelectedRowModel().rows || []
  const items = selected.map((r: Row<Role>) => ({ id: r.original.id, name: r.original.name }))
  if (!items.length) return

  const itemsList = items.map(i => i.name).join(', ')
  popupStore.open({
    type: 'delete',
    title: 'Eliminar Cargos Selecionados',
    content: `Tem a certeza que deseja eliminar <strong>${items.length}</strong> cargo(s)?<br><span class="text-sm">${itemsList}</span>`,
    onAccept: async () => {
      const ids = items.map(i => i.id)
      try {
        const results = await Promise.allSettled(
          ids.map(id => useApiFetch(`/api/roles/${id}`, { method: 'DELETE' }))
        )
        const success = results.filter(r => r.status === 'fulfilled').length
        const failed = results.length - success
        if (success) {
          toast.add({
            title: 'Cargos eliminados',
            description: `${success} cargo(s) eliminado(s) com sucesso.`,
            color: 'success'
          })
        }
        if (failed) {
          toast.add({
            title: 'Algumas eliminações falharam',
            description: `${failed} cargo(s) não foram eliminados.`,
            color: 'warning'
          })
        }
        rowSelection.value = {}
        refreshRoles()
      } catch {
        toast.add({
          title: 'Erro',
          description: 'Erro ao eliminar cargos.',
          color: 'error'
        })
      }
    }
  })
}
</script>

<template>
  <UDashboardPanel id="roles">
    <template #header>
      <UDashboardNavbar title="Cargos">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>
        <template #right>
          <UButton label="Novo Cargo" icon="i-lucide-plus" to="/users/roles/new" />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="flex flex-wrap items-center justify-between gap-1.5 mb-4">
        <UInput
          :model-value="(table?.tableApi?.getColumn('name')?.getFilterValue() as string)"
          class="max-w-sm"
          icon="i-lucide-search"
          placeholder="Filtrar por nome..."
          @update:model-value="table?.tableApi?.getColumn('name')?.setFilterValue($event)"
        />

        <div class="flex flex-wrap items-center gap-1.5">
          <UButton
            v-if="table?.tableApi?.getFilteredSelectedRowModel().rows.length"
            label="Apagar"
            color="error"
            variant="subtle"
            icon="i-lucide-trash"
            @click="openBulkDeleteModal"
          >
            <template #trailing>
              <UKbd>
                {{ table?.tableApi?.getFilteredSelectedRowModel().rows.length }}
              </UKbd>
            </template>
          </UButton>

          <UDropdownMenu
            :items="
              table?.tableApi
                ?.getAllColumns()
                .filter((column: any) => column.getCanHide())
                .map((column: any) => ({
                  label: column.id,
                  type: 'checkbox' as const,
                  checked: column.getIsVisible(),
                  onUpdateChecked(checked: boolean) {
                    table?.tableApi?.getColumn(column.id)?.toggleVisibility(!!checked)
                  },
                  onSelect(e?: Event) { e?.preventDefault() }
                }))
            "
            :content="{ align: 'end' }"
          >
            <UButton
              label="Colunas"
              color="neutral"
              variant="outline"
              trailing-icon="i-lucide-settings-2"
            />
          </UDropdownMenu>
        </div>
      </div>

      <UTable
        ref="table"
        v-model:column-filters="columnFilters"
        v-model:column-visibility="columnVisibility"
        v-model:row-selection="rowSelection"
        v-model:pagination="pagination"
        :pagination-options="{ getPaginationRowModel: getPaginationRowModel() }"
        :data="data"
        :columns="columns"
        :loading="status === 'pending'"
        :ui="{
          base: 'table-fixed border-separate border-spacing-0',
          thead: '[&>tr]:bg-elevated/50 [&>tr]:after:content-none',
          tbody: '[&>tr]:last:[&>td]:border-b-0',
          th: 'py-2 first:rounded-l-lg last:rounded-r-lg border-y border-default first:border-l last:border-r',
          td: 'border-b border-default',
          separator: 'h-0'
        }"
      />

      <div class="flex items-center justify-between gap-3 border-t border-default pt-4 mt-4">
        <div class="text-sm text-muted">
          {{ table?.tableApi?.getFilteredSelectedRowModel().rows.length || 0 }} de
          {{ table?.tableApi?.getFilteredRowModel().rows.length || 0 }} linha(s) selecionada(s).
        </div>
        <UPagination
          :default-page="(table?.tableApi?.getState().pagination.pageIndex || 0) + 1"
          :items-per-page="table?.tableApi?.getState().pagination.pageSize"
          :total="table?.tableApi?.getFilteredRowModel().rows.length"
          @update:page="(p: number) => table?.tableApi?.setPageIndex(p - 1)"
        />
      </div>

      <!-- Universal Popup -->
      <UniversalPopup />
    </template>
  </UDashboardPanel>
</template>
