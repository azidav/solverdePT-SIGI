<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import { h } from 'vue'

const UBadge = resolveComponent('UBadge')

definePageMeta({
  layout: 'default'
})

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

const loading = ref(false)
const logs = ref<IAuditLog[]>([])
const pagination = ref<IPagination>({
  page: 1,
  limit: 50,
  total: 0,
  totalPages: 0
})

// Filtros
const startDate = ref<string>('')
const endDate = ref<string>('')
const selectedAction = ref<string>('')

// Opções para filtros
const actionOptions = [
  { label: 'Criar', value: 'CREATE' },
  { label: 'Atualizar', value: 'UPDATE' },
  { label: 'Eliminar', value: 'DELETE' },
  { label: 'Login', value: 'LOGIN' },
  { label: 'Logout', value: 'LOGOUT' },
  { label: 'Atribuir', value: 'ASSIGN' },
  { label: 'Remover', value: 'UNASSIGN' }
]

// Formatar data/hora
function formatDateTime(dateStr: string) {
  if (!dateStr) return '-'
  try {
    const date = new Date(dateStr)
    if (isNaN(date.getTime())) return dateStr
    return date.toLocaleString('pt-PT', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  } catch {
    return dateStr
  }
}

// Traduzir ação
function translateAction(action: string) {
  const translations: Record<string, string> = {
    CREATE: 'Criar',
    UPDATE: 'Atualizar',
    DELETE: 'Eliminar',
    LOGIN: 'Login',
    LOGOUT: 'Logout',
    ASSIGN: 'Atribuir',
    UNASSIGN: 'Remover'
  }
  return translations[action] || action
}

// Cor do badge de ação
function getActionColor(action: string) {
  const colors: Record<string, string> = {
    CREATE: 'success',
    UPDATE: 'info',
    DELETE: 'error',
    LOGIN: 'primary',
    LOGOUT: 'neutral',
    ASSIGN: 'success',
    UNASSIGN: 'warning'
  }
  return colors[action] || 'neutral'
}

// Colunas da tabela
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
    cell: ({ row }) => h(UBadge, {
      color: getActionColor(row.original.action),
      variant: 'subtle',
      size: 'sm'
    }, () => translateAction(row.original.action))
  },
  {
    accessorKey: 'entity_name',
    header: 'Entidade',
    cell: ({ row }) => row.original.entity_name || '-'
  },
  {
    accessorKey: 'ip_address',
    header: 'IP',
    cell: ({ row }) => h('code', { class: 'text-xs bg-muted/20 px-1 py-0.5 rounded' }, row.original.ip_address)
  }
]

// Fetch logs
async function fetchLogs(page = 1) {
  loading.value = true
  try {
    const params = new URLSearchParams()
    params.append('page', page.toString())
    params.append('limit', '50')

    if (startDate.value) params.append('start_date', startDate.value)
    if (endDate.value) params.append('end_date', endDate.value)
    if (selectedAction.value) params.append('action', selectedAction.value)

    const result = await useApiFetch(`/api/audit-logs?${params.toString()}`)

    logs.value = result?.data || result || []
    pagination.value = result?.pagination || pagination.value
  } catch (error) {
    console.error('Error fetching audit logs:', error)
  } finally {
    loading.value = false
  }
}

// Aplicar filtros
function applyFilters() {
  fetchLogs(1)
}

// Limpar filtros
function clearFilters() {
  startDate.value = ''
  endDate.value = ''
  selectedAction.value = ''
  fetchLogs(1)
}

// Paginação
function goToPage(page: number) {
  if (page >= 1 && page <= pagination.value.totalPages) {
    fetchLogs(page)
  }
}

// Fetch inicial
onMounted(() => {
  fetchLogs()
})
</script>

<template>
  <div class="p-6 space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold">Audit Logs</h1>
        <p class="text-muted text-sm mt-1">
          Histórico de alterações e ações no sistema
        </p>
      </div>
    </div>

    <!-- Filtros -->
    <UCard>
      <template #header>
        <div class="flex items-center gap-2">
          <UIcon name="i-lucide-filter" class="size-4" />
          <span class="font-medium">Filtros</span>
        </div>
      </template>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div>
          <label class="block text-sm font-medium mb-1">Data Início</label>
          <UInput
            v-model="startDate"
            type="date"
          />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">Data Fim</label>
          <UInput
            v-model="endDate"
            type="date"
          />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">Ação</label>
          <USelect
            v-model="selectedAction"
            :items="actionOptions"
            value-key="value"
            placeholder="Selecione uma ação"
            clearable
            searchable
          />
        </div>
      </div>

      <template #footer>
        <div class="flex justify-end gap-2">
          <UButton
            label="Limpar"
            color="neutral"
            variant="subtle"
            @click="clearFilters"
          />
          <UButton
            label="Filtrar"
            color="primary"
            icon="i-lucide-search"
            @click="applyFilters"
          />
        </div>
      </template>
    </UCard>

    <!-- Tabela de Logs -->
    <UCard>
      <template #header>
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <UIcon name="i-lucide-history" class="size-4" />
            <span class="font-medium">Registos de Auditoria</span>
          </div>
          <UBadge color="neutral" variant="subtle">
            {{ pagination.total }} registos
          </UBadge>
        </div>
      </template>

      <UTable
        :columns="columns"
        :data="logs"
        :loading="loading"
        class="min-h-[300px]"
      >
        <template #empty>
          <div class="text-center py-8 text-muted">
            <UIcon name="i-lucide-inbox" class="size-12 mx-auto mb-2 opacity-50" />
            <p>Nenhum registo encontrado</p>
          </div>
        </template>
      </UTable>

      <!-- Paginação -->
      <template v-if="pagination.totalPages > 1" #footer>
        <div class="flex items-center justify-between">
          <p class="text-sm text-muted">
            Página {{ pagination.page }} de {{ pagination.totalPages }}
          </p>
          <div class="flex gap-1">
            <UButton
              icon="i-lucide-chevrons-left"
              color="neutral"
              variant="ghost"
              size="sm"
              :disabled="pagination.page === 1"
              @click="goToPage(1)"
            />
            <UButton
              icon="i-lucide-chevron-left"
              color="neutral"
              variant="ghost"
              size="sm"
              :disabled="pagination.page === 1"
              @click="goToPage(pagination.page - 1)"
            />
            <UButton
              icon="i-lucide-chevron-right"
              color="neutral"
              variant="ghost"
              size="sm"
              :disabled="pagination.page === pagination.totalPages"
              @click="goToPage(pagination.page + 1)"
            />
            <UButton
              icon="i-lucide-chevrons-right"
              color="neutral"
              variant="ghost"
              size="sm"
              :disabled="pagination.page === pagination.totalPages"
              @click="goToPage(pagination.totalPages)"
            />
          </div>
        </div>
      </template>
    </UCard>
  </div>
</template>
