<script setup lang="ts">
definePageMeta({ title: 'Administração — Férias' })

interface Request {
  id: number
  type: string
  start_date: string
  end_date: string
  days_count: number
  status: string
  employee_name: string
  department: string | null
  created_at: string
  current_approval_step: number
}

const toast = useToast()
const { can, canApproveVacation } = useRbac()
const { STATUS_LABELS, STATUS_COLORS, TYPE_LABELS, formatDate } = useVacationUtils()

const requests = ref<Request[]>([])
const loading = ref(true)
const filterStatus = ref('pending')
const page = ref(1)
const total = ref(0)
const limit = 20

async function loadRequests() {
  loading.value = true
  try {
    const params = new URLSearchParams({
      page: String(page.value),
      limit: String(limit),
      ...(filterStatus.value ? { status: filterStatus.value } : {})
    })
    const res = await useApiFetch(`/api/vacation-requests?${params}`) as any
    requests.value = res.data ?? []
    total.value = res.pagination?.total ?? 0
  } catch {
    toast.add({ title: 'Erro ao carregar pedidos', color: 'error' })
  } finally {
    loading.value = false
  }
}

watch([filterStatus, page], loadRequests)

const STATUS_FILTER_OPTIONS = [
  ...Object.entries(STATUS_LABELS).map(([k, v]) => ({ key: k, label: v })),
  { key: '', label: 'Todos' }
]

onMounted(loadRequests)
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar title="Administração — Férias">
        <template #leading>
          <UDashboardSidebarCollapse />
          <UButton
            icon="i-lucide-arrow-left"
            variant="ghost"
            to="/ferias"
          />
        </template>
      </UDashboardNavbar>
    </template>

    <div class="p-4 space-y-4">
      <!-- Blackout Manager -->
      <VacationBlackoutManager v-if="can('VACATION:CONFIG_PERIODS')" />

      <!-- Requests list -->
      <UCard>
        <template #header>
          <div class="flex items-center justify-between flex-wrap gap-2">
            <h3 class="font-semibold">
              Pedidos de Férias
            </h3>
            <div class="flex gap-1 flex-wrap">
              <UButton
                v-for="opt in STATUS_FILTER_OPTIONS"
                :key="opt.key"
                size="xs"
                :variant="filterStatus === opt.key ? 'solid' : 'ghost'"
                :label="opt.label"
                @click="filterStatus = opt.key; page = 1"
              />
            </div>
          </div>
        </template>

        <div v-if="loading" class="flex justify-center py-8">
          <UIcon name="i-lucide-loader-2" class="size-5 animate-spin text-muted" />
        </div>
        <div v-else-if="requests.length === 0" class="text-center py-8 text-sm text-muted">
          Sem pedidos.
        </div>
        <div v-else class="space-y-2">
          <div
            v-for="r in requests"
            :key="r.id"
            class="flex items-center justify-between gap-3 p-3 rounded-lg border border-default hover:bg-elevated/50 transition-colors cursor-pointer"
            @click="navigateTo(`/ferias/${r.id}`)"
          >
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 flex-wrap">
                <span class="font-medium text-sm">{{ r.employee_name }}</span>
                <UBadge
                  :label="STATUS_LABELS[r.status] || r.status"
                  :color="STATUS_COLORS[r.status]"
                  variant="subtle"
                  size="sm"
                />
              </div>
              <p class="text-xs text-muted mt-0.5">
                {{ TYPE_LABELS[r.type] || r.type }} ·
                {{ formatDate(r.start_date) }} → {{ formatDate(r.end_date) }}
                ({{ r.days_count }} dia{{ r.days_count !== 1 ? 's' : '' }})
              </p>
            </div>
            <UIcon name="i-lucide-chevron-right" class="size-4 text-muted shrink-0" />
          </div>
        </div>

        <template v-if="total > limit" #footer>
          <div class="flex justify-center">
            <UPagination
              v-model:page="page"
              :total="total"
              :page-size="limit"
            />
          </div>
        </template>
      </UCard>

      <!-- Team Calendar -->
      <VacationTeamCalendar v-if="canApproveVacation" />
    </div>
  </UDashboardPanel>
</template>
