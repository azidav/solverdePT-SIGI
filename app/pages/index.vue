<script setup lang="ts">
interface VacationRequest {
  id: number
  type: string
  start_date: string
  end_date: string
  days_count: number
  status: string
}

interface Reservation {
  id: number
  meeting_title: string
  description: string | null
  start_time: string
  end_time: string
  room_name: string
}

const auth = useAuth()
const userName = computed(() => auth.user.value?.name || auth.user.value?.username || '')
const { STATUS_LABELS, STATUS_COLORS, TYPE_LABELS, formatDate } = useVacationUtils()
const { can } = useRbac()

const vacationRequests = ref<VacationRequest[]>([])
const loadingVacations = ref(false)

interface PendingApproval {
  id: number
  type: string
  start_date: string
  end_date: string
  days_count: number
  employee_name: string
  level_name: string
  created_at: string
}

const pendingApprovals = ref<PendingApproval[]>([])
const loadingPending = ref(false)

const reservations = ref<Reservation[]>([])
const loadingReservations = ref(false)

interface UnprocessedRequest {
  id: number
  type: string
  start_date: string
  end_date: string
  days_count: number
  employee_name: string
}

const unprocessedRequests = ref<UnprocessedRequest[]>([])
const loadingUnprocessed = ref(false)

async function loadUnprocessed() {
  loadingUnprocessed.value = true
  try {
    const res = await useApiFetch('/api/vacation-requests?unprocessed=1&limit=5') as { data: UnprocessedRequest[] }
    unprocessedRequests.value = res.data ?? []
  } catch {
    unprocessedRequests.value = []
  } finally {
    loadingUnprocessed.value = false
  }
}

async function loadPendingApprovals() {
  loadingPending.value = true
  try {
    pendingApprovals.value = await useApiFetch('/api/vacation-requests/pending-my-action') as PendingApproval[]
  } catch {
    pendingApprovals.value = []
  } finally {
    loadingPending.value = false
  }
}

async function loadVacations() {
  loadingVacations.value = true
  try {
    const res = await useApiFetch('/api/vacation-requests?limit=5') as { data: VacationRequest[] }
    vacationRequests.value = res.data ?? []
  } catch {
    vacationRequests.value = []
  } finally {
    loadingVacations.value = false
  }
}

async function loadReservations() {
  loadingReservations.value = true
  try {
    reservations.value = await useApiFetch('/api/room-reservations/upcoming') as Reservation[]
  } catch {
    reservations.value = []
  } finally {
    loadingReservations.value = false
  }
}

function fmtDate(iso: string) {
  const d = new Date(iso)
  const today = new Date()
  const tomorrow = new Date(today)
  tomorrow.setDate(today.getDate() + 1)

  if (d.toDateString() === today.toDateString()) return 'Hoje'
  if (d.toDateString() === tomorrow.toDateString()) return 'Amanhã'
  return d.toLocaleDateString('pt-PT', { weekday: 'short', day: 'numeric', month: 'short' })
}

function fmtTime(iso: string) {
  return new Date(iso).toLocaleTimeString('pt-PT', { hour: '2-digit', minute: '2-digit' })
}

function isToday(iso: string) {
  return new Date(iso).toDateString() === new Date().toDateString()
}

onMounted(() => {
  loadPendingApprovals()
  loadVacations()
  loadReservations()
  loadUnprocessed()
})
</script>

<template>
  <UDashboardPanel id="home">
    <template #header>
      <UDashboardNavbar title="Início">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="p-6 space-y-6">
        <!-- Welcome -->
        <div>
          <h1 class="text-2xl font-bold">
            Olá, {{ userName }} 👋
          </h1>
          <p class="text-muted text-sm mt-1">
            Bem-vindo ao sistema de gestão SolverdePT.
          </p>
        </div>

        <!-- Pending approvals (full width, only shown when there are requests) -->
        <UCard
          v-if="loadingPending || pendingApprovals.length > 0"
          class="border-warning-200 dark:border-warning-800"
        >
          <template #header>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-clock" class="size-4 text-warning-500" />
                <h2 class="font-semibold text-sm">
                  Pedidos a aguardar a minha aprovação
                </h2>
                <UBadge
                  v-if="pendingApprovals.length > 0"
                  :label="String(pendingApprovals.length)"
                  color="warning"
                  variant="solid"
                  size="xs"
                />
              </div>
              <UButton
                label="Ver tudo"
                icon="i-lucide-arrow-right"
                trailing
                size="xs"
                color="neutral"
                variant="ghost"
                to="/ferias/admin"
              />
            </div>
          </template>

          <div v-if="loadingPending" class="flex justify-center py-6">
            <UIcon name="i-lucide-loader-2" class="size-5 animate-spin text-muted" />
          </div>

          <div v-else class="divide-y divide-default">
            <div
              v-for="r in pendingApprovals"
              :key="r.id"
              class="flex items-center gap-3 py-3 first:pt-0 last:pb-0 cursor-pointer hover:bg-elevated/40 -mx-4 px-4 transition-colors rounded"
              @click="navigateTo(`/ferias/${r.id}`)"
            >
              <UIcon name="i-lucide-user" class="size-4 text-muted shrink-0" />
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium">
                  {{ r.employee_name }}
                </p>
                <p class="text-xs text-muted mt-0.5">
                  {{ TYPE_LABELS[r.type] || r.type }} · {{ formatDate(r.start_date) }} → {{ formatDate(r.end_date) }}
                  <span class="ml-1">({{ r.days_count }} dia{{ r.days_count !== 1 ? 's' : '' }})</span>
                </p>
              </div>
              <UBadge
                :label="r.level_name"
                color="neutral"
                variant="subtle"
                size="xs"
                class="shrink-0 hidden sm:flex"
              />
              <UIcon name="i-lucide-chevron-right" class="size-4 text-muted shrink-0" />
            </div>
          </div>
        </UCard>

        <!-- RH: unprocessed approved requests -->
        <UCard
          v-if="can('VACATION:RH')"
          class="border-warning-200 dark:border-warning-800"
        >
          <template #header>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-clock-alert" class="size-4 text-warning-500" />
                <h2 class="font-semibold text-sm">
                  Férias aprovadas por processar
                </h2>
                <UBadge
                  v-if="unprocessedRequests.length > 0"
                  :label="String(unprocessedRequests.length)"
                  color="warning"
                  variant="solid"
                  size="xs"
                />
              </div>
              <UButton
                label="Ver tudo"
                icon="i-lucide-arrow-right"
                trailing
                size="xs"
                color="neutral"
                variant="ghost"
                to="/ferias/admin"
              />
            </div>
          </template>

          <div v-if="loadingUnprocessed" class="flex justify-center py-6">
            <UIcon name="i-lucide-loader-2" class="size-5 animate-spin text-muted" />
          </div>

          <div v-else-if="unprocessedRequests.length === 0" class="py-6 text-center text-sm text-muted">
            Nenhum pedido por processar.
          </div>

          <div v-else class="divide-y divide-default">
            <div
              v-for="r in unprocessedRequests"
              :key="r.id"
              class="flex items-center gap-3 py-3 first:pt-0 last:pb-0 cursor-pointer hover:bg-elevated/40 -mx-4 px-4 transition-colors rounded"
              @click="navigateTo(`/ferias/${r.id}`)"
            >
              <UIcon name="i-lucide-user" class="size-4 text-muted shrink-0" />
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium">
                  {{ r.employee_name }}
                </p>
                <p class="text-xs text-muted mt-0.5">
                  {{ TYPE_LABELS[r.type] || r.type }} · {{ formatDate(r.start_date) }} → {{ formatDate(r.end_date) }}
                  <span class="ml-1">({{ r.days_count }} dia{{ r.days_count !== 1 ? 's' : '' }})</span>
                </p>
              </div>
              <UIcon name="i-lucide-chevron-right" class="size-4 text-muted shrink-0" />
            </div>
          </div>
        </UCard>

        <!-- Vacation + Reservations side by side -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 items-start">

        <!-- Vacation requests -->
        <UCard>
          <template #header>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-calendar-days" class="size-4 text-primary" />
                <h2 class="font-semibold text-sm">
                  Os meus pedidos de férias
                </h2>
              </div>
              <UButton
                label="Ver tudo"
                icon="i-lucide-arrow-right"
                trailing
                size="xs"
                color="neutral"
                variant="ghost"
                to="/ferias"
              />
            </div>
          </template>

          <div v-if="loadingVacations" class="flex justify-center py-8">
            <UIcon name="i-lucide-loader-2" class="size-5 animate-spin text-muted" />
          </div>

          <div v-else-if="vacationRequests.length === 0" class="py-8 text-center">
            <UIcon name="i-lucide-palm-tree" class="size-8 text-muted mx-auto mb-2" />
            <p class="text-sm text-muted">
              Ainda não tens pedidos de férias.
            </p>
            <UButton
              label="Fazer pedido"
              size="sm"
              color="primary"
              variant="soft"
              class="mt-3"
              to="/ferias/nova"
            />
          </div>

          <div v-else class="divide-y divide-default">
            <div
              v-for="r in vacationRequests"
              :key="r.id"
              class="flex items-center gap-3 py-3 first:pt-0 last:pb-0 cursor-pointer hover:bg-elevated/40 -mx-4 px-4 transition-colors rounded"
              @click="navigateTo(`/ferias/${r.id}`)"
            >
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium">
                  {{ TYPE_LABELS[r.type] || r.type }}
                </p>
                <p class="text-xs text-muted mt-0.5">
                  {{ formatDate(r.start_date) }} → {{ formatDate(r.end_date) }}
                  <span class="ml-1">({{ r.days_count }} dia{{ r.days_count !== 1 ? 's' : '' }})</span>
                </p>
              </div>
              <UBadge
                :label="STATUS_LABELS[r.status] || r.status"
                :color="STATUS_COLORS[r.status]"
                variant="subtle"
                size="sm"
              />
            </div>
          </div>
        </UCard>

        <!-- Room reservations -->

        <UCard>
          <template #header>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-door-open" class="size-4 text-primary" />
                <h2 class="font-semibold text-sm">
                  As minhas reservas de sala
                </h2>
              </div>
              <UButton
                label="Ver tudo"
                icon="i-lucide-arrow-right"
                trailing
                size="xs"
                color="neutral"
                variant="ghost"
                to="/meeting-rooms"
              />
            </div>
          </template>

          <!-- Loading -->
          <div v-if="loadingReservations" class="flex justify-center py-8">
            <UIcon name="i-lucide-loader-2" class="size-5 animate-spin text-muted" />
          </div>

          <!-- Empty state -->
          <div v-else-if="reservations.length === 0" class="py-8 text-center">
            <UIcon name="i-lucide-calendar-x" class="size-8 text-muted mx-auto mb-2" />
            <p class="text-sm text-muted">
              Não tens reservas de sala próximas.
            </p>
            <UButton
              label="Reservar uma sala"
              size="sm"
              color="primary"
              variant="soft"
              class="mt-3"
              to="/meeting-rooms"
            />
          </div>

          <!-- Reservations list -->
          <div v-else class="divide-y divide-default">
            <div
              v-for="r in reservations"
              :key="r.id"
              class="flex items-start gap-4 py-3 first:pt-0 last:pb-0"
            >
              <!-- Date badge -->
              <div
                class="shrink-0 w-14 text-center rounded-lg py-1.5"
                :class="isToday(r.start_time) ? 'bg-primary/10' : 'bg-elevated'"
              >
                <p
                  class="text-xs font-semibold"
                  :class="isToday(r.start_time) ? 'text-primary' : 'text-muted'"
                >
                  {{ fmtDate(r.start_time) }}
                </p>
                <p
                  class="text-xs"
                  :class="isToday(r.start_time) ? 'text-primary' : 'text-muted'"
                >
                  {{ fmtTime(r.start_time) }}
                </p>
              </div>

              <!-- Details -->
              <div class="flex-1 min-w-0">
                <p class="font-medium text-sm truncate">
                  {{ r.meeting_title }}
                </p>
                <p
                  v-if="r.description"
                  class="text-xs text-muted truncate mt-0.5"
                >
                  {{ r.description }}
                </p>
                <div class="flex items-center gap-2 mt-1">
                  <UBadge color="neutral" variant="subtle" size="xs">
                    {{ r.room_name }}
                  </UBadge>
                  <span class="text-xs text-muted">
                    {{ fmtTime(r.start_time) }} – {{ fmtTime(r.end_time) }}
                  </span>
                </div>
              </div>

              <!-- Today indicator -->
              <UBadge
                v-if="isToday(r.start_time)"
                color="primary"
                variant="subtle"
                size="xs"
                class="shrink-0"
              >
                Hoje
              </UBadge>
            </div>
          </div>
        </UCard>

        </div>
      </div>
    </template>
  </UDashboardPanel>
</template>
