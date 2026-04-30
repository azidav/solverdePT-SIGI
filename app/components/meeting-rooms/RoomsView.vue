<script setup lang="ts">
interface Room {
  id: number
  name: string
  description: string | null
  image_url: string | null
  capacity: number
  location: string | null
  amenities: string | null
  is_occupied: boolean
  current_reservation: { id: number, meeting_title: string, booker_name: string, end_time: string } | null
}

interface Reservation {
  id: number
  room_id: number
  room_name: string
  meeting_title: string
  description: string | null
  start_time: string
  end_time: string
  booker_name: string
  user_id: number | null
  is_guest: boolean
  booking_token: string | null
  token_expires_at: string | null
}

const props = defineProps<{
  rooms: Room[]
  selectedRoom: Room | null
  roomReservations: Reservation[]
  loadingRooms: boolean
  loadingReservations: boolean
  isAuthenticated: boolean
  canCancelAny: boolean
  authUserId: number | null
  myTokenIds: number[]
  isPastDate: boolean
  outlookDefaultBody: string
}>()

const emit = defineEmits<{
  'update:selectedRoom': [room: Room]
  openBooking: []
  cancelReservation: [r: Reservation]
}>()

// Cancel confirmation
const pendingCancel = ref<Reservation | null>(null)

function canCancelReservation(r: Reservation): boolean {
  if (props.canCancelAny) return true
  if (props.isAuthenticated && props.authUserId && r.user_id === props.authUserId) return true
  if (!props.isAuthenticated && props.myTokenIds.includes(r.id)) return true
  return false
}

function requestCancel(r: Reservation) {
  pendingCancel.value = r
}

function confirmCancel() {
  if (pendingCancel.value) {
    emit('cancelReservation', pendingCancel.value)
    pendingCancel.value = null
  }
}

function fmt(iso: string) {
  return new Date(iso).toLocaleTimeString('pt-PT', { hour: '2-digit', minute: '2-digit' })
}

function toOutlookDt(iso: string) {
  const d = new Date(iso)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:00`
}

function outlookUrl(r: Reservation) {
  const body = r.description?.trim() || props.outlookDefaultBody
  const params = new URLSearchParams({
    subject: r.meeting_title,
    body,
    startdt: toOutlookDt(r.start_time),
    enddt: toOutlookDt(r.end_time),
    location: r.room_name
  })
  return `https://outlook.office.com/calendar/0/deeplink/compose?${params.toString()}`
}

function getReservationItems(r: Reservation) {
  const items: { label: string, icon: string, color?: 'error', onSelect: () => void }[] = []

  if (props.isAuthenticated && r.user_id === props.authUserId) {
    items.push({
      label: 'Adicionar ao Outlook',
      icon: 'i-simple-icons-microsoftoutlook',
      onSelect: () => { if (import.meta.client) window.open(outlookUrl(r), '_blank') }
    })
  }

  if (canCancelReservation(r)) {
    items.push({
      label: 'Cancelar Reserva',
      icon: 'i-lucide-calendar-x',
      color: 'error' as const,
      onSelect: () => requestCancel(r)
    })
  }

  return items
}
</script>

<template>
  <div class="flex flex-col gap-4 sm:flex-row sm:min-h-[520px]">

    <!-- Left: Room list -->
    <div class="sm:w-64 sm:shrink-0">
      <p class="hidden sm:block text-xs font-semibold text-muted uppercase tracking-wide px-1 mb-2">
        Salas
      </p>

      <!-- Skeletons -->
      <div v-if="loadingRooms" class="flex gap-2 overflow-x-auto pb-1 sm:flex-col sm:overflow-visible sm:pb-0">
        <div
          v-for="i in 3"
          :key="i"
          class="shrink-0 h-16 w-40 rounded-lg bg-elevated animate-pulse sm:h-24 sm:w-full"
        />
      </div>

      <div
        v-else
        class="flex flex-row gap-2 overflow-x-auto pb-1 sm:flex-col sm:overflow-visible sm:gap-0 sm:space-y-2 sm:pb-0"
      >
        <button
          v-for="room in rooms"
          :key="room.id"
          class="shrink-0 min-w-40 text-left rounded-xl border transition-all p-2.5 space-y-1.5 sm:shrink-0 sm:min-w-0 sm:w-full sm:p-3"
          :class="selectedRoom?.id === room.id
            ? 'border-primary bg-primary/5 ring-1 ring-primary'
            : 'border-default bg-default hover:bg-elevated/60'"
          @click="emit('update:selectedRoom', room)"
        >
          <div class="flex items-start justify-between gap-2">
            <span class="font-medium text-sm leading-tight">{{ room.name }}</span>
            <UBadge
              :color="room.is_occupied ? 'error' : 'success'"
              variant="subtle"
              size="xs"
              class="shrink-0"
            >
              {{ room.is_occupied ? 'Ocupada' : 'Livre' }}
            </UBadge>
          </div>
          <p
            v-if="room.description"
            class="hidden sm:block text-xs text-muted leading-relaxed line-clamp-2"
          >
            {{ room.description }}
          </p>
          <div class="flex items-center gap-2 text-xs text-muted">
            <span class="flex items-center gap-0.5">
              <UIcon name="i-lucide-users" class="size-3" />{{ room.capacity }} pax
            </span>
          </div>
          <p
            v-if="room.amenities"
            class="hidden sm:flex items-center gap-1 text-xs text-muted truncate"
          >
            <UIcon name="i-lucide-monitor" class="size-3 shrink-0" />{{ room.amenities }}
          </p>
          <p
            v-if="room.is_occupied && room.current_reservation"
            class="hidden sm:block text-xs text-error-500 truncate"
          >
            {{ room.current_reservation.booker_name }} · até {{ fmt(room.current_reservation.end_time) }}
          </p>
        </button>
      </div>
    </div>

    <!-- Right: Selected room detail -->
    <div class="flex-1 min-w-0">
      <div
        v-if="!selectedRoom"
        class="flex items-center justify-center h-full text-muted"
      >
        <div class="text-center">
          <UIcon name="i-lucide-door-open" class="size-10 mx-auto mb-2" />
          <p class="text-sm">
            Selecione uma sala
          </p>
        </div>
      </div>

      <div v-else class="space-y-4">
        <!-- Room header card -->
        <UCard>
          <div class="flex flex-wrap items-start justify-between gap-4">
            <div class="space-y-1 min-w-0">
              <div class="flex items-center gap-2 flex-wrap">
                <h2 class="text-lg font-semibold">
                  {{ selectedRoom.name }}
                </h2>
                <UBadge
                  :color="selectedRoom.is_occupied ? 'error' : 'success'"
                  variant="subtle"
                >
                  {{ selectedRoom.is_occupied ? 'Ocupada agora' : 'Disponível' }}
                </UBadge>
              </div>
              <p
                v-if="selectedRoom.description"
                class="text-sm text-muted"
              >
                {{ selectedRoom.description }}
              </p>
              <div class="flex flex-wrap gap-3 text-xs text-muted pt-0.5">
                <span class="flex items-center gap-1">
                  <UIcon name="i-lucide-users" class="size-3" /> {{ selectedRoom.capacity }} pessoas
                </span>
                <span v-if="selectedRoom.amenities" class="flex items-center gap-1">
                  <UIcon name="i-lucide-monitor" class="size-3" /> {{ selectedRoom.amenities }}
                </span>
              </div>
            </div>
            <UButton
              label="Reservar"
              icon="i-lucide-calendar-plus"
              color="primary"
              :disabled="isPastDate"
              @click="emit('openBooking')"
            />
          </div>
        </UCard>

        <!-- Schedule -->
        <UCard>
          <template #header>
            <div class="flex items-center gap-2">
              <UIcon name="i-lucide-clock" class="size-4 text-primary" />
              <h3 class="font-semibold text-sm">
                Reservas do dia
              </h3>
            </div>
          </template>

          <div v-if="loadingReservations" class="py-6 flex justify-center">
            <UIcon name="i-lucide-loader-2" class="size-5 animate-spin text-muted" />
          </div>

          <div v-else-if="roomReservations.length === 0" class="py-8 text-center">
            <UIcon name="i-lucide-calendar-check" class="size-8 text-muted mx-auto mb-2" />
            <p class="text-sm text-muted">
              Sem reservas para este dia
            </p>
            <UButton
              label="Fazer primeira reserva"
              size="sm"
              color="primary"
              variant="soft"
              class="mt-3"
              :disabled="isPastDate"
              @click="emit('openBooking')"
            />
          </div>

          <div v-else class="space-y-2">
            <div
              v-for="r in roomReservations"
              :key="r.id"
              class="flex items-start gap-3 rounded-lg border border-default p-3"
            >
              <div class="shrink-0 text-center min-w-[52px]">
                <p class="text-sm font-semibold text-primary">
                  {{ fmt(r.start_time) }}
                </p>
                <p class="text-xs text-muted">
                  {{ fmt(r.end_time) }}
                </p>
              </div>
              <div class="flex-1 min-w-0">
                <p class="font-medium text-sm truncate">
                  {{ r.meeting_title }}
                </p>
                <p
                  v-if="r.description"
                  class="text-xs text-muted truncate"
                >
                  {{ r.description }}
                </p>
                <p class="text-xs text-muted mt-0.5 flex items-center gap-1">
                  <UIcon
                    :name="r.is_guest ? 'i-lucide-user' : 'i-lucide-user-check'"
                    class="size-3"
                  />
                  {{ r.booker_name }}
                  <UBadge
                    v-if="r.is_guest"
                    color="neutral"
                    variant="subtle"
                    size="xs"
                  >
                    visitante
                  </UBadge>
                </p>
              </div>
              <UDropdownMenu
                v-if="getReservationItems(r).length > 0"
                :content="{ align: 'end' }"
                :items="getReservationItems(r)"
              >
                <UButton
                  icon="i-lucide-ellipsis-vertical"
                  size="xs"
                  color="neutral"
                  variant="ghost"
                />
              </UDropdownMenu>
            </div>
          </div>
        </UCard>
      </div>
    </div>
  </div>

  <!-- Cancel confirmation modal -->
  <UModal
    :open="!!pendingCancel"
    title="Cancelar Reserva"
    :ui="{ content: 'max-w-sm' }"
    @update:open="(v) => { if (!v) pendingCancel = null }"
  >
    <template #body>
      <div class="space-y-4">
        <p class="text-sm">
          Tem a certeza que pretende cancelar a reserva
          <span class="font-semibold">"{{ pendingCancel?.meeting_title }}"</span>?
          Esta ação não pode ser desfeita.
        </p>
        <div class="flex justify-end gap-2">
          <UButton
            label="Não, manter"
            color="neutral"
            variant="subtle"
            @click="pendingCancel = null"
          />
          <UButton
            label="Sim, cancelar"
            color="error"
            icon="i-lucide-calendar-x"
            @click="confirmCancel"
          />
        </div>
      </div>
    </template>
  </UModal>
</template>
