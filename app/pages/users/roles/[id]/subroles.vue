<script setup lang="ts">
import type { Row } from '@tanstack/table-core'
import type { TableColumn } from '@nuxt/ui'

definePageMeta({
  middleware: 'permissions'
})

interface Subrole {
  id: number
  role_id: number
  name: string
  date_creation: string
}

interface Role {
  id: number
  name: string
}

const toast = useToast()
const route = useRoute()
const router = useRouter()

const roleId = computed(() => Number(route.params.id))
const role = ref<Role | null>(null)
const data = ref<Subrole[]>([])
const status = ref<'pending' | 'success' | 'error'>('pending')
const showDeleteModal = ref(false)
const subroleToDelete = ref<Subrole | null>(null)

async function refreshSubroles() {
  status.value = 'pending'
  try {
    const [rolesData, subrolesData] = await Promise.all([
      useApiFetch('/api/roles', { method: 'GET' }),
      useApiFetch(`/api/subroles?role_id=${roleId.value}`, { method: 'GET' })
    ])

    const roles = rolesData as Role[]
    role.value = roles.find(r => r.id === roleId.value) || null

    if (!role.value) {
      toast.add({
        title: 'Erro',
        description: 'Cargo não encontrado',
        color: 'error'
      })
      router.push('/users/roles')
      return
    }

    data.value = (subrolesData as Subrole[]) || []
    status.value = 'success'
  } catch {
    status.value = 'error'
    toast.add({
      title: 'Erro ao carregar dados',
      description: 'Não foi possível carregar os sub-cargos.',
      color: 'error'
    })
  }
}

await refreshSubroles()

function openDeleteModal(subrole: Subrole) {
  subroleToDelete.value = subrole
  showDeleteModal.value = true
}

async function confirmDelete() {
  if (!subroleToDelete.value) return

  try {
    await useApiFetch(`/api/subroles/${subroleToDelete.value.id}`, { method: 'DELETE' })
    toast.add({
      title: 'Sub-cargo eliminado',
      description: 'O sub-cargo foi eliminado com sucesso.',
      color: 'success'
    })
    await refreshSubroles()
  } catch {
    toast.add({
      title: 'Erro ao eliminar',
      description: 'Não foi possível eliminar o sub-cargo.',
      color: 'error'
    })
  } finally {
    showDeleteModal.value = false
    subroleToDelete.value = null
  }
}

const columns: TableColumn<Subrole>[] = [
  {
    accessorKey: 'id',
    header: 'ID'
  },
  {
    accessorKey: 'name',
    header: 'Nome',
    cell: ({ row }) => h('div', { class: 'font-medium' }, row.original.name)
  },
  {
    accessorKey: 'date_creation',
    header: 'Data de Criação',
    cell: ({ row }) => new Date(row.original.date_creation).toLocaleDateString('pt-PT')
  },
  {
    id: 'actions',
    cell: ({ row }) => h(
      'div',
      { class: 'text-right' },
      h(
        UDropdownMenu,
        { items: [getRowItems(row as Row<Subrole>)] },
        () => h(UButton, { icon: 'i-lucide-ellipsis-vertical', color: 'neutral', variant: 'ghost', class: 'ml-auto' })
      )
    )
  }
]

function getRowItems(row: Row<Subrole>) {
  return [
    {
      label: 'Editar',
      icon: 'i-lucide-pencil',
      to: `/users/roles/${roleId.value}/subroles/${row.original.id}`
    },
    {
      type: 'separator'
    },
    {
      label: 'Eliminar',
      icon: 'i-lucide-trash-2',
      color: 'error',
      onSelect: () => openDeleteModal(row.original)
    }
  ]
}
</script>

<template>
  <UDashboardPanelContent class="p-6">
    <UDashboardNavbar :title="`Sub-cargos de ${role?.name || ''}`">
      <template #left>
        <UButton
          icon="i-lucide-arrow-left"
          variant="ghost"
          size="sm"
          to="/users/roles"
        />
      </template>
      <template #right>
        <UButton
          icon="i-lucide-plus"
          label="Novo Sub-cargo"
          :to="`/users/roles/${roleId}/subroles/new`"
        />
      </template>
    </UDashboardNavbar>

    <UTable
      :columns="columns"
      :data="data"
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

    <!-- Delete Confirmation Modal -->
    <UModal v-model:open="showDeleteModal">
      <UCard>
        <template #header>
          <div class="flex items-center gap-2">
            <UIcon name="i-lucide-alert-triangle" class="w-5 h-5 text-error" />
            <h3 class="text-lg font-semibold">
              Eliminar Sub-cargo
            </h3>
          </div>
        </template>

        <p class="text-muted">
          Tem a certeza que deseja eliminar o sub-cargo <strong>{{ subroleToDelete?.name }}</strong>?
        </p>
        <p class="text-sm text-muted mt-2">
          Esta ação não pode ser revertida.
        </p>

        <template #footer>
          <div class="flex justify-end gap-3">
            <UButton
              label="Cancelar"
              color="neutral"
              variant="subtle"
              @click="showDeleteModal = false"
            />
            <UButton
              label="Eliminar"
              color="error"
              @click="confirmDelete"
            />
          </div>
        </template>
      </UCard>
    </UModal>
  </UDashboardPanelContent>
</template>
