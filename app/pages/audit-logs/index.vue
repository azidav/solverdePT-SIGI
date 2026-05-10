<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'

definePageMeta({ title: 'Audit Logs' })

const UBadge = resolveComponent('UBadge')

interface IAuditLog {
  id: number
  user_id: number | null
  user_name: string | null
  action: string
  entity_type: string
  entity_id: number | null
  entity_name: string | null
  ip_address: string
  user_agent: string
  created_at: string
}

interface IPagination {
  page: number
  limit: number
  total: number
  totalPages: number
}

const toast = useToast()
const loading = ref(false)
const logs = ref<IAuditLog[]>([])
const pagination = ref<IPagination>({ page: 1, limit: 50, total: 0, totalPages: 0 })

const today = new Date().toISOString().split('T')[0]
const startDate = ref(today)
const endDate = ref(today)
const selectedAction = ref<string | null>(null)

const actionOptions = [
  { label: 'Todas as ações', value: null },
  { label: 'Criar', value: 'CREATE' },
  { label: 'Atualizar', value: 'UPDATE' },
  { label: 'Eliminar', value: 'DELETE' },
  { label: 'Login', value: 'LOGIN' },
  { label: 'Logout', value: 'LOGOUT' },
  { label: 'Atribuir', value: 'ASSIGN' },
  { label: 'Remover', value: 'UNASSIGN' }
]

const ACTION_COLORS: Record<string, string> = {
  CREATE: 'success',
  UPDATE: 'info',
  DELETE: 'error',
  LOGIN: 'primary',
  LOGOUT: 'neutral',
  ASSIGN: 'success',
  UNASSIGN: 'warning'
}

const ACTION_LABELS: Record<string, string> = {
  CREATE: 'Criar',
  UPDATE: 'Atualizar',
  DELETE: 'Eliminar',
  LOGIN: 'Login',
  LOGOUT: 'Logout',
  ASSIGN: 'Atribuir',
  UNASSIGN: 'Remover'
}

const ENTITY_LABELS: Record<string, string> = {
  USER: 'Utilizador',
  ROLE: 'Grupo',
  PERMISSION: 'Permissão',
  USER_ROLE: 'Atribuição',
  SESSION: 'Sessão'
}

function formatDateTime(d: string) {
  if (!d) return '-'
  try {
    return new Date(d).toLocaleString('pt-PT', {
      day: '2-digit', month: '2-digit', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    })
  } catch { return d }
}

const columns: TableColumn<IAuditLog>[] = [
  {
    accessorKey: 'created_at',
    header: 'Data/Hora',
    cell: ({ row }) => formatDateTime(row.original.created_at)
  },
  {
    accessorKey: 'user_name',
    header: 'Utilizador',
    cell: ({ row }) => row.original.user_name || 'Sistema'
  },
  {
    accessorKey: 'action',
    header: 'Ação',
    cell: ({ row }) =>
      h(UBadge, {
        color: ACTION_COLORS[row.original.action] || 'neutral',
        variant: 'subtle',
        size: 'sm'
      }, () => ACTION_LABELS[row.original.action] || row.original.action)
  },
  {
    accessorKey: 'entity_type',
    header: 'Tipo',
    cell: ({ row }) =>
      h(UBadge, { color: 'neutral', variant: 'outline', size: 'sm' },
        () => ENTITY_LABELS[row.original.entity_type] || row.original.entity_type)
  },
  {
    accessorKey: 'entity_name',
    header: 'Entidade',
    cell: ({ row }) => row.original.entity_name || '-'
  },
  {
    accessorKey: 'ip_address',
    header: 'IP',
    cell: ({ row }) =>
      h('code', { class: 'text-xs bg-muted/30 px-1.5 py-0.5 rounded font-mono' },
        row.original.ip_address || '-')
  }
]

async function fetchLogs(page = 1) {
  loading.value = true
  try {
    const params = new URLSearchParams({ page: String(page), limit: '50' })
    if (startDate.value) params.append('start_date', startDate.value)
    if (endDate.value) params.append('end_date', endDate.value)
    if (selectedAction.value != null) params.append('action', selectedAction.value)

    const result = await useApiFetch(`/api/audit-logs?${params}`) as any
    logs.value = result?.data || []
    if (result?.pagination) pagination.value = result.pagination
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar audit logs', color: 'error' })
  } finally {
    loading.value = false
  }
}

function clearFilters() {
  startDate.value = ''
  endDate.value = ''
  selectedAction.value = null
  fetchLogs(1)
}

onMounted(() => fetchLogs())
</script>

<template>
  <UDashboardPanel id="audit-logs">
    <template #header>
      <UDashboardNavbar title="Audit Logs" icon="i-lucide-scroll-text">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>
        <template #right>
          <UBadge color="neutral" variant="subtle" size="lg">
            {{ pagination.total }} registos
          </UBadge>
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="space-y-4 p-4">
        <!-- Filtros -->
        <UCard>
          <template #header>
            <div class="flex items-center gap-2">
              <UIcon name="i-lucide-filter" class="size-4 text-muted" />
              <span class="font-medium text-sm">Filtros</span>
            </div>
          </template>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <UFormField label="Data Início">
              <UInput v-model="startDate" type="date" class="w-full" />
            </UFormField>

            <UFormField label="Data Fim">
              <UInput v-model="endDate" type="date" class="w-full" />
            </UFormField>

            <UFormField label="Ação">
              <USelect
                v-model="selectedAction"
                :items="actionOptions"
                class="w-full"
              />
            </UFormField>
          </div>

          <template #footer>
            <div class="flex justify-end gap-2">
              <UButton label="Limpar" color="neutral" variant="subtle" @click="clearFilters" />
              <UButton label="Filtrar" color="primary" icon="i-lucide-search" @click="fetchLogs(1)" />
            </div>
          </template>
        </UCard>

        <!-- Tabela -->
        <UCard>
          <UTable
            :columns="columns"
            :data="logs"
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

          <template v-if="!loading && logs.length === 0" #footer>
            <div class="flex flex-col items-center gap-2 py-10 text-muted">
              <UIcon name="i-lucide-inbox" class="size-10 opacity-40" />
              <p class="text-sm">Nenhum registo encontrado</p>
            </div>
          </template>

          <template v-if="pagination.totalPages > 1" #footer>
            <div class="flex items-center justify-between">
              <p class="text-sm text-muted">
                Página {{ pagination.page }} de {{ pagination.totalPages }}
              </p>
              <UPagination
                :default-page="pagination.page"
                :total="pagination.total"
                :items-per-page="pagination.limit"
                @update:page="fetchLogs"
              />
            </div>
          </template>
        </UCard>
      </div>
    </template>
  </UDashboardPanel>
</template>
