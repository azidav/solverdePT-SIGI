<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import { upperFirst } from 'scule'
import { getPaginationRowModel } from '@tanstack/table-core'
import type { Row } from '@tanstack/table-core'
import type { User } from '~/types'
import { useApiFetch } from '~/composables/useApiFetch'
import useAuth from '/composables/useAuth'

const UAvatar = resolveComponent('UAvatar')
const UButton = resolveComponent('UButton')
const UBadge = resolveComponent('UBadge')
const UDropdownMenu = resolveComponent('UDropdownMenu')
const UCheckbox = resolveComponent('UCheckbox')

const toast = useToast()
const table = useTemplateRef('table')
const auth = useAuth()


const columnFilters = ref([
  {
    id: 'email',
    value: ''
  }
])
const columnVisibility = ref()
const rowSelection = ref({ })
// const rowSelection = ref({ 1: true })

const data = ref<User[]>([])
const status = ref<'pending' | 'success' | 'error'>('pending')

async function refreshUsers() {
  status.value = 'pending'
  try {
    const atualID = auth.user?.value.id ?? 0
    const resp = await useApiFetch(`/api/users?filter=${atualID}`, { method: 'GET' }) as User[]
    data.value = resp
    status.value = 'success'
  } catch (e) {
    status.value = 'error'
  }
}

await refreshUsers()

function getRowItems(row: Row<User>) {
  return [
    {
      type: 'label',
      label: 'Ações'
    },
    {
      label: 'Editar',
      icon: 'i-ic-baseline-edit',
      kbds: ['meta', 'e'],
      to: `/users/accounts/${row.original.id}`
    },
    {
      label: 'Copiar Email',
      icon: 'i-lucide-copy',
      onSelect() {
        navigator.clipboard.writeText(row.original.email.toString())
        toast.add({
          title: 'Copiado',
          description: 'Email copiado para a clipboard'
        })
      }
    },
    {
      type: 'separator'
    },
    {
      label: 'Ver Consultas',
      icon: 'i-lucide-list'
    },
    /*{
      type: 'separator'
    },
    {
      label: 'Delete customer',
      icon: 'i-lucide-trash',
      color: 'error',
      onSelect() {
        toast.add({
          title: 'Customer deleted',
          description: 'The customer has been deleted.'
        })
      }
    }*/
  ]
}

const columns: TableColumn<User>[] = [
  {
    id: 'select',
    header: ({ table }) =>
      h(UCheckbox, {
        'modelValue': table.getIsSomePageRowsSelected()
          ? 'indeterminate'
          : table.getIsAllPageRowsSelected(),
        'onUpdate:modelValue': (value: boolean | 'indeterminate') =>
          table.toggleAllPageRowsSelected(!!value),
        'ariaLabel': 'Select all'
      }),
    cell: ({ row }) =>
      h(UCheckbox, {
        'modelValue': row.getIsSelected(),
        'onUpdate:modelValue': (value: boolean | 'indeterminate') => row.toggleSelected(!!value),
        'ariaLabel': 'Select row'
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
    filterFn: (row: any, columnId: string, filterValue: string) => {
      if (!filterValue) return true
      const searchValue = filterValue.toLowerCase()
      const name = row.getValue(columnId)?.toLowerCase() || ''
      const role = row.original.role_name?.toLowerCase() || ''
      const subrole = row.original.subrole_name?.toLowerCase() || ''
      return name.includes(searchValue) || role.includes(searchValue) || subrole.includes(searchValue)
    },
    cell: ({ row }) => {
      // console.warn(row.original)
      return h('div', { class: 'flex items-center gap-3' }, [
        h(UAvatar, {
          ...row.original.avatar,
          size: 'lg'
        }),
        h('div', undefined, [
          h('p', { class: 'font-medium text-highlighted' }, row.original.name),
          h('p', { class: '' }, `${row.original?.role_name ?? ''}${row.original?.subrole_name ? ' (' + row.original.subrole_name + ')' : ''}`)
        ])
      ])
    }
  },
  {
    accessorKey: 'email',
    enableColumnFilter: true,
    filterFn: 'includesString',
    header: ({ column }) => {
      const isSorted = column.getIsSorted()

      return h(UButton, {
        color: 'neutral',
        variant: 'ghost',
        label: 'Email',
        icon: isSorted
          ? isSorted === 'asc'
            ? 'i-lucide-arrow-up-narrow-wide'
            : 'i-lucide-arrow-down-wide-narrow'
          : 'i-lucide-arrow-up-down',
        class: '-mx-2.5',
        onClick: () => column.toggleSorting(column.getIsSorted() === 'asc')
      })
    }
  },
  {
    accessorKey: 'status',
    header: 'Estado',
    filterFn: 'equals',
    cell: ({ row }) => {
      const color = {
        1: 'success' as const,
        '-1': 'error' as const,
        0: 'warning' as const
      }[row.original.status]

      return h(UBadge, { class: 'capitalize', variant: 'subtle', color }, () =>
        row.original.status_text
      )
    }
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
            content: {
              align: 'end'
            },
            items: getRowItems(row)
          },
          () =>
            h(UButton, {
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

const statusFilter = ref('all')

watch(() => statusFilter.value, (newVal) => {
  if (!table?.value?.tableApi) return

  const statusColumn = table.value.tableApi.getColumn('status')
  if (!statusColumn) return

  if (newVal === 'all') {
    statusColumn.setFilterValue(undefined)
  } else {
    statusColumn.setFilterValue(newVal)
  }
})

const pagination = ref({
  pageIndex: 0,
  pageSize: 10
})
</script>

<template>
  <UDashboardPanel id="customers">
    <template #header>
      <UDashboardNavbar title="Utilizador">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>

        <template #right>
          <UButton label="Novo Utilizador" icon="i-lucide-plus" to="/users/accounts/new" />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="flex flex-wrap items-center justify-between gap-1.5">
        <UInput
          :model-value="(table?.tableApi?.getColumn('name')?.getFilterValue() as string)"
          class="max-w-sm"
          icon="i-lucide-search"
          placeholder="Filtrar por nome, cargo ou sub-cargo..."
          @update:model-value="table?.tableApi?.getColumn('name')?.setFilterValue($event)"
        />

        <div class="flex flex-wrap items-center gap-1.5">
          <UsersDeleteModal
            :count="table?.tableApi?.getFilteredSelectedRowModel().rows.length"
            :user-id="table?.tableApi?.getFilteredSelectedRowModel().rows[0]?.original.id"
            @deleted="refreshUsers"
          >
            <UButton
              v-if="table?.tableApi?.getFilteredSelectedRowModel().rows.length"
              label="Apagar"
              color="error"
              variant="subtle"
              icon="i-lucide-trash"
            >
              <template #trailing>
                <UKbd>
                  {{ table?.tableApi?.getFilteredSelectedRowModel().rows.length }}
                </UKbd>
              </template>
            </UButton>
          </UsersDeleteModal>

          <USelect
            v-model="statusFilter"
            :items="[
              { label: 'Todos', value: 'all' },
              { label: 'Ativos', value: 1 },
              { label: 'Pendentes', value: 0 }
            ]"
            :ui="{ trailingIcon: 'group-data-[state=open]:rotate-180 transition-transform duration-200' }"
            placeholder="Filtrar Estados"
            class="min-w-28"
          />
          <UDropdownMenu
            :items="
              table?.tableApi
                ?.getAllColumns()
                .filter((column: any) => column.getCanHide())
                .map((column: any) => ({
                  label: upperFirst(column.id),
                  type: 'checkbox' as const,
                  checked: column.getIsVisible(),
                  onUpdateChecked(checked: boolean) {
                    table?.tableApi?.getColumn(column.id)?.toggleVisibility(!!checked)
                  },
                  onSelect(e?: Event) {
                    e?.preventDefault()
                  }
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
        :pagination-options="{
          getPaginationRowModel: getPaginationRowModel()
        }"
        class="shrink-0"
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

      <div class="flex items-center justify-between gap-3 border-t border-default pt-4 mt-auto">
        <div class="text-sm text-muted">
          {{ table?.tableApi?.getFilteredSelectedRowModel().rows.length || 0 }} de
          {{ table?.tableApi?.getFilteredRowModel().rows.length || 0 }} linha(s) selecionada(s).
        </div>

        <div class="flex items-center gap-1.5">
          <UPagination
            :default-page="(table?.tableApi?.getState().pagination.pageIndex || 0) + 1"
            :items-per-page="table?.tableApi?.getState().pagination.pageSize"
            :total="table?.tableApi?.getFilteredRowModel().rows.length"
            @update:page="(p: number) => table?.tableApi?.setPageIndex(p - 1)"
          />
        </div>
      </div>
    </template>
  </UDashboardPanel>
</template>
