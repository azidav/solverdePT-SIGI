<script setup lang="ts">
definePageMeta({ title: 'As Minhas Férias' })

interface Request {
  id: number
  type: string
  start_date: string
  end_date: string
  days_count: number
  status: string
  reason: string | null
  created_at: string
}

interface Balance {
  base_days: number
  birthday_bonus: number
  carryover_days: number
  used_days: number
  pending_days: number
}

const toast = useToast()
const { can, canApproveVacation } = useRbac()
const { STATUS_LABELS, STATUS_COLORS, TYPE_LABELS, formatDate, formatDaysLabel } = useVacationUtils()

const requests = ref<Request[]>([])
const balance = ref<Balance | null>(null)
const loading = ref(true)
const filterStatus = ref('')
const now = new Date()
const selectedYear = ref(now.getFullYear())

// Cancel confirmation
const showCancelModal = ref(false)
const cancelTargetId = ref<number | null>(null)
const cancelling = ref(false)

const totalAllowed = computed(() =>
  Number(balance.value?.base_days ?? 0) +
  Number(balance.value?.birthday_bonus ?? 0) +
  Number(balance.value?.carryover_days ?? 0)
)

const availableDays = computed(() =>
  totalAllowed.value -
  Number(balance.value?.used_days ?? 0) -
  Number(balance.value?.pending_days ?? 0)
)

const filteredRequests = computed(() =>
  filterStatus.value
    ? requests.value.filter((r) => r.status === filterStatus.value)
    : requests.value
)

async function loadData() {
  loading.value = true
  try {
    const [reqs, bal] = await Promise.all([
      useApiFetch(`/api/vacation-requests?limit=100&year=${selectedYear.value}`),
      useApiFetch(`/api/vacation-requests/balance?year=${selectedYear.value}`)
    ])
    requests.value = (reqs as any).data ?? []
    balance.value = bal as Balance
  } catch {
    toast.add({ title: 'Erro ao carregar dados', color: 'error' })
  } finally {
    loading.value = false
  }
}

watch(selectedYear, () => {
  filterStatus.value = ''
  loadData()
})

function confirmCancel(id: number) {
  cancelTargetId.value = id
  showCancelModal.value = true
}

async function cancelRequest() {
  if (!cancelTargetId.value) return
  cancelling.value = true
  try {
    await useApiFetch(`/api/vacation-requests/${cancelTargetId.value}`, { method: 'DELETE' })
    toast.add({ title: 'Pedido cancelado com sucesso', color: 'success' })
    showCancelModal.value = false
    await loadData()
  } catch (e: unknown) {
    toast.add({ title: (e as { data?: { message?: string } })?.data?.message || 'Erro ao cancelar pedido', color: 'error' })
  } finally {
    cancelling.value = false
    cancelTargetId.value = null
  }
}

const STATUS_FILTER_OPTIONS = Object.entries(STATUS_LABELS).map(([k, v]) => ({ key: k, label: v }))

onMounted(loadData)
</script>

<template>
  <div class="p-4 space-y-4">
      <!-- Year selector -->
      <div class="flex items-center gap-1">
        <UButton
          icon="i-lucide-chevron-left"
          variant="ghost"
          size="sm"
          @click="selectedYear--"
        />
        <span class="font-semibold text-sm w-12 text-center">{{ selectedYear }}</span>
        <UButton
          icon="i-lucide-chevron-right"
          variant="ghost"
          size="sm"
          @click="selectedYear++"
        />
      </div>

      <!-- Balance summary -->
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <UCard>
          <div class="text-center">
            <p class="text-2xl font-bold text-primary">
              {{ totalAllowed }}
            </p>
            <p class="text-xs text-muted">
              Total {{ selectedYear }}
            </p>
          </div>
        </UCard>
        <UCard>
          <div class="text-center">
            <p class="text-2xl font-bold text-green-500">
              {{ availableDays }}
            </p>
            <p class="text-xs text-muted">
              Disponíveis
            </p>
          </div>
        </UCard>
        <UCard>
          <div class="text-center">
            <p class="text-2xl font-bold text-yellow-500">
              {{ balance?.pending_days ?? 0 }}
            </p>
            <p class="text-xs text-muted">
              Em aprovação
            </p>
          </div>
        </UCard>
        <UCard>
          <div class="text-center">
            <p class="text-2xl font-bold text-muted">
              {{ balance?.used_days ?? 0 }}
            </p>
            <p class="text-xs text-muted">
              Utilizados
            </p>
          </div>
        </UCard>
      </div>

      <!-- Birthday / carryover bonuses -->
      <div
        v-if="balance && (balance.birthday_bonus > 0 || balance.carryover_days > 0)"
        class="flex gap-2 flex-wrap"
      >
        <UBadge
          v-if="balance.birthday_bonus > 0"
          icon="i-lucide-cake"
          label="+1 dia de aniversário"
          color="info"
          variant="subtle"
        />
        <UBadge
          v-if="balance.carryover_days > 0"
          icon="i-lucide-arrow-right"
          :label="`+${balance.carryover_days} dia${balance.carryover_days > 1 ? 's' : ''} transitados de ${selectedYear - 1}`"
          color="warning"
          variant="subtle"
        />
      </div>

      <!-- Status filter + new request button -->
      <div class="flex items-center justify-between gap-3 flex-wrap">
        <UButton
          v-if="can('VACATION:CREATE')"
          label="Novo Pedido"
          icon="i-lucide-plus"
          color="primary"
          to="/ferias/nova"
        />
      </div>

      <div class="flex gap-1.5 flex-wrap">
        <UButton
          size="sm"
          :variant="filterStatus === '' ? 'solid' : 'ghost'"
          label="Todos"
          @click="filterStatus = ''"
        />
        <UButton
          v-for="opt in STATUS_FILTER_OPTIONS"
          :key="opt.key"
          size="sm"
          :variant="filterStatus === opt.key ? 'solid' : 'ghost'"
          :label="opt.label"
          @click="filterStatus = opt.key"
        />
      </div>

      <!-- List -->
      <div v-if="loading" class="flex justify-center py-10">
        <UIcon name="i-lucide-loader-2" class="size-5 animate-spin text-muted" />
      </div>

      <div v-else-if="filteredRequests.length === 0" class="text-center py-10">
        <UIcon name="i-lucide-calendar-off" class="size-8 text-muted mx-auto mb-2" />
        <p class="text-sm text-muted">
          Sem pedidos de férias.
        </p>
        <UButton
          v-if="can('VACATION:CREATE')"
          label="Fazer primeiro pedido"
          size="sm"
          color="primary"
          variant="soft"
          class="mt-3"
          to="/ferias/nova"
        />
      </div>

      <div v-else class="space-y-2">
        <UCard
          v-for="r in filteredRequests"
          :key="r.id"
          class="hover:bg-elevated/50 transition-colors"
        >
          <div class="flex items-center justify-between gap-3">
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 flex-wrap">
                <span class="font-medium text-sm">{{ TYPE_LABELS[r.type] || r.type }}</span>
                <UBadge
                  :label="STATUS_LABELS[r.status] || r.status"
                  :color="STATUS_COLORS[r.status]"
                  variant="subtle"
                  size="sm"
                />
              </div>
              <p class="text-sm text-muted mt-0.5">
                {{ formatDate(r.start_date) }} → {{ formatDate(r.end_date) }}
                <span class="ml-1 text-xs">({{ formatDaysLabel(r.days_count) }})</span>
              </p>
            </div>
            <div class="flex gap-1 shrink-0">
              <UButton
                icon="i-lucide-eye"
                variant="ghost"
                size="sm"
                :to="`/ferias/${r.id}`"
              />
              <UButton
                v-if="r.status === 'pending'"
                icon="i-lucide-x"
                variant="ghost"
                color="error"
                size="sm"
                @click="confirmCancel(r.id)"
              />
            </div>
          </div>
        </UCard>
      </div>
  </div>

  <!-- Cancel confirmation modal -->
  <UModal
    v-model:open="showCancelModal"
    title="Cancelar Pedido"
    :ui="{ content: 'max-w-sm' }"
  >
    <template #body>
      <div class="space-y-4">
        <p class="text-sm">
          Tem a certeza que pretende cancelar este pedido? Esta ação não pode ser desfeita.
        </p>
        <div class="flex justify-end gap-2">
          <UButton
            label="Não, manter"
            color="neutral"
            variant="subtle"
            @click="showCancelModal = false"
          />
          <UButton
            label="Sim, cancelar"
            color="error"
            icon="i-lucide-x"
            :loading="cancelling"
            @click="cancelRequest"
          />
        </div>
      </div>
    </template>
  </UModal>
</template>
