<script setup lang="ts">
// Painel público de sala (tablet à entrada) — reservas do dia com linha da hora atual
definePageMeta({ layout: false, title: 'Painel de Sala' })

interface Room {
  id: number
  name: string
  capacity: number
  location: string | null
}

interface Reservation {
  id: number
  meeting_title: string
  booker_name: string | null
  start_time: string
  end_time: string
}

interface RoomsConfig {
  slot_duration: number
  booking_start: string
  booking_end: string
}

const route = useRoute()
const roomId = computed(() => Number(route.params.id))

function localDateStr(d = new Date()) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

const selectedDate = ref(localDateStr())
const now = ref(new Date())

const { data: room, error: roomError } = useFetch<Room>(`/api/meeting-rooms/${roomId.value}`)
const { data: config } = useFetch<RoomsConfig>('/api/rooms-config', {
  default: () => ({ slot_duration: 30, booking_start: '08:00', booking_end: '22:00' })
})
const { data: reservations, refresh } = useFetch<Reservation[]>('/api/room-reservations', {
  query: { room_id: roomId, date: selectedDate },
  default: () => []
})

const isToday = computed(() => selectedDate.value === localDateStr(now.value))

const dateLabel = computed(() => {
  const d = new Date(selectedDate.value + 'T00:00:00')
  const label = new Intl.DateTimeFormat('pt-PT', { weekday: 'long', day: 'numeric', month: 'long' }).format(d)
  return label.charAt(0).toUpperCase() + label.slice(1)
})

function shiftDay(delta: number) {
  const d = new Date(selectedDate.value + 'T00:00:00')
  d.setDate(d.getDate() + delta)
  selectedDate.value = localDateStr(d)
}

function goToday() {
  selectedDate.value = localDateStr()
}

const fmtTime = new Intl.DateTimeFormat('pt-PT', { hour: '2-digit', minute: '2-digit' })

// Estado atual da sala (apenas relevante para hoje)
const roomStatus = computed(() => {
  if (!isToday.value) return null
  const nowMs = now.value.getTime()
  const current = reservations.value.find(r =>
    new Date(r.start_time).getTime() <= nowMs && nowMs < new Date(r.end_time).getTime()
  )
  if (current) {
    return {
      color: 'error' as const,
      icon: 'i-lucide-circle-slash',
      label: `Ocupada até ${fmtTime.format(new Date(current.end_time))}`,
      detail: current.meeting_title
    }
  }
  const next = reservations.value
    .filter(r => new Date(r.start_time).getTime() > nowMs)
    .sort((a, b) => new Date(a.start_time).getTime() - new Date(b.start_time).getTime())[0]
  if (next) {
    return {
      color: 'success' as const,
      icon: 'i-lucide-check-circle',
      label: 'Disponível',
      detail: `Próxima reunião às ${fmtTime.format(new Date(next.start_time))} — ${next.meeting_title}`
    }
  }
  return {
    color: 'success' as const,
    icon: 'i-lucide-check-circle',
    label: 'Disponível',
    detail: 'Sem mais reuniões hoje'
  }
})

// Relógio (30s) + refresh dos dados (60s) + refresh ao acordar o tablet
let clockTimer: ReturnType<typeof setInterval> | null = null
let dataTimer: ReturnType<typeof setInterval> | null = null

function onVisibility() {
  if (document.visibilityState === 'visible') {
    now.value = new Date()
    refresh()
  }
}

onMounted(() => {
  clockTimer = setInterval(() => {
    now.value = new Date()
  }, 30_000)
  dataTimer = setInterval(() => refresh(), 60_000)
  document.addEventListener('visibilitychange', onVisibility)
})

onUnmounted(() => {
  if (clockTimer) clearInterval(clockTimer)
  if (dataTimer) clearInterval(dataTimer)
  document.removeEventListener('visibilitychange', onVisibility)
})
</script>

<template>
  <div class="min-h-screen bg-default">
    <!-- Sala não encontrada -->
    <div v-if="roomError || (room === null && !roomError)" class="flex items-center justify-center min-h-screen p-6">
      <UCard v-if="roomError" class="max-w-md text-center">
        <div class="space-y-3 py-4">
          <UIcon name="i-lucide-door-closed" class="size-10 text-muted mx-auto" />
          <p class="font-semibold">
            Sala não encontrada
          </p>
          <UButton label="Escolher outra sala" to="/painel-salas" variant="soft" />
        </div>
      </UCard>
      <UIcon v-else name="i-lucide-loader-2" class="size-8 animate-spin text-muted" />
    </div>

    <div v-else class="max-w-3xl mx-auto p-4 sm:p-6 space-y-4">
      <!-- Cabeçalho -->
      <div class="flex items-start justify-between gap-3 flex-wrap">
        <div>
          <h1 class="text-3xl font-bold">
            {{ room?.name }}
          </h1>
          <p class="text-muted">
            <span v-if="room?.location">{{ room.location }} · </span>{{ room?.capacity }} lugares
          </p>
        </div>
        <div class="text-right">
          <p class="text-lg font-semibold">
            {{ dateLabel }}
          </p>
          <div class="flex items-center gap-1 justify-end mt-1">
            <UButton
              icon="i-lucide-chevron-left"
              variant="ghost"
              size="sm"
              @click="shiftDay(-1)"
            />
            <UButton
              label="Hoje"
              variant="soft"
              size="sm"
              :disabled="isToday"
              @click="goToday"
            />
            <UButton
              icon="i-lucide-chevron-right"
              variant="ghost"
              size="sm"
              @click="shiftDay(1)"
            />
          </div>
        </div>
      </div>

      <!-- Banner de estado (só hoje) -->
      <UAlert
        v-if="roomStatus"
        :color="roomStatus.color"
        variant="subtle"
        :icon="roomStatus.icon"
      >
        <template #title>
          <span class="text-lg font-bold">{{ roomStatus.label }}</span>
        </template>
        <template #description>
          {{ roomStatus.detail }}
        </template>
      </UAlert>

      <!-- Timeline do dia -->
      <UCard :ui="{ body: 'p-2 sm:p-4' }">
        <RoomsDisplayDayTimeline
          :reservations="reservations"
          :day-start="config.booking_start"
          :day-end="config.booking_end"
          :now="now"
          :is-today="isToday"
        />
      </UCard>
    </div>
  </div>
</template>
