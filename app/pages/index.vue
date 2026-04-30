<script setup lang="ts">
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

const reservations = ref<Reservation[]>([])
const loadingReservations = ref(false)

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

onMounted(loadReservations)
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
    </template>
  </UDashboardPanel>
</template>
